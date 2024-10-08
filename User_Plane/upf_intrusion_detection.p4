/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>
/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;
const bit<16>   TYPE_IPV4 = 0x800;
const bit<8>    TYPE_ICMP = 1;
const bit<8>    TYPE_TCP  = 6;
const bit<8>    TYPE_UDP  = 17;
/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/* Standard ethernet header */
header ethernet_h {
    mac_addr_t   dst_addr;
    mac_addr_t   src_addr;
    ether_type_t ether_type;
}
/* IPV4 header */
header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}
/* TCP header */
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}
/* ICMP header */
header icmp_h {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    bit<32> rest;
}
/* UDP header */
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> udp_total_len;
    bit<16> checksum;
}
/***********************  H E A D E R S  ************************/
struct my_ingress_headers_t {
    ethernet_h   ethernet;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
    icmp_h       icmp;
}
/******  G L O B A L   I N G R E S S   M E T A D A T A  *********/
struct my_ingress_metadata_t {

    bit<16> hdr_srcport;
    bit<16> hdr_dstport;
    bit<16> ip_total_len;
    bit<16> tcp_window_size;
    bit<16> udp_length;
    bit<8>  ip_ttl;
    bit<4>  tcp_hdr_len;
    bit<1>  tcp_flag_push;
    bit<1>  tcp_flag_reset;
    bit<1>  tcp_flag_fin;

    bit<8> final_class;
    bit<499> codeword0;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }
    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            TYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        meta.final_class=100; // initialize class
        meta.ip_total_len = hdr.ipv4.total_len;
        meta.ip_ttl       = hdr.ipv4.ttl;
        transition select(hdr.ipv4.protocol) {
            TYPE_TCP:  parse_tcp;
            TYPE_UDP:  parse_udp;
            TYPE_ICMP: parse_icmp;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        meta.hdr_dstport     = hdr.tcp.dst_port;
        meta.hdr_srcport     = hdr.tcp.src_port;
        meta.tcp_hdr_len     = hdr.tcp.data_offset;
        meta.tcp_window_size = hdr.tcp.window;
        meta.tcp_flag_push   = hdr.tcp.psh;
        meta.tcp_flag_reset  = hdr.tcp.rst;
        meta.tcp_flag_fin    = hdr.tcp.fin;
        meta.udp_length      = 0;
        transition accept;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        meta.hdr_dstport     = hdr.udp.dst_port;
        meta.hdr_srcport     = hdr.udp.src_port;
        meta.tcp_hdr_len     = 0;
        meta.tcp_window_size = 0;
        meta.tcp_flag_push   = 0;
        meta.tcp_flag_reset  = 0;
        meta.tcp_flag_fin    = 0;
        meta.udp_length      = hdr.udp.udp_total_len;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        meta.hdr_dstport     = 0;
        meta.hdr_srcport     = 0;
        meta.tcp_hdr_len     = 0;
        meta.tcp_window_size = 0;
        meta.tcp_flag_push   = 0;
        meta.tcp_flag_reset  = 0;
        meta.tcp_flag_fin    = 0;
        meta.udp_length      = 0;
        transition accept;
    }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
/***************** M A T C H - A C T I O N  *********************/
control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    /* Forward to a specific port upon classification */
    action ipv4_forward(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    /* Custom Do Nothing Action */
    action nop(){}

    /* Assign class if at leaf node */
    action SetClass0(bit<8> classe) {
        meta.final_class = classe;
        hdr.ipv4.ttl = classe;
        // ipv4_forward(260);
    }

    /* Feature table actions */
    action SetCode9(bit<14>  code0) {meta.codeword0[13:0]    = code0;}
    action SetCode8(bit<207> code0) {meta.codeword0[220:14]  = code0;}
    action SetCode7(bit<15>  code0) {meta.codeword0[235:221] = code0;}
    action SetCode6(bit<28>  code0) {meta.codeword0[263:236] = code0;}
    action SetCode5(bit<1>   code0) {meta.codeword0[264:264] = code0;}
    action SetCode4(bit<6>   code0) {meta.codeword0[270:265] = code0;}
    action SetCode3(bit<213> code0) {meta.codeword0[483:271] = code0;}
    action SetCode2(bit<5>   code0) {meta.codeword0[488:484] = code0;}
    action SetCode1(bit<2>   code0) {meta.codeword0[490:489] = code0;}
    action SetCode0(bit<8>   code0) {meta.codeword0[498:491] = code0;}

    /* Feature tables */
    table table_feature0{
	    key = {meta.ip_ttl: range @name("feature0");}
	    actions = {@defaultonly nop; SetCode0;}
	    size = 16;
        const default_action = nop();
	}
    table table_feature1{
	    key = {meta.hdr_dstport: range @name("feature1");}
	    actions = {@defaultonly nop; SetCode1;}
	    size = 192;
        const default_action = nop();
	}
    table table_feature2{
        key = {meta.tcp_window_size: range @name("feature2");}
	    actions = {@defaultonly nop; SetCode2;}
	    size = 16;
        const default_action = nop();
	}
    table table_feature3{
	    key = {meta.ip_total_len: range @name("feature3");}
	    actions = {@defaultonly nop; SetCode3;}
	    size = 32;
        const default_action = nop();
	}
    table table_feature4{
        key = {meta.tcp_flag_push: range @name("feature4");}
        actions = {@defaultonly nop; SetCode4;}
        size = 2;
        const default_action = nop();
    }
    table table_feature5{
        key = {meta.tcp_hdr_len: range @name("feature5");}
        actions = {@defaultonly nop; SetCode5;}
        size = 8;
        const default_action = nop();
    }
    table table_feature6{
        key = {meta.hdr_srcport: range @name("feature6");}
        actions = {@defaultonly nop; SetCode6;}
        size = 216;
        const default_action = nop();
    }
    table table_feature7{
        key = {meta.tcp_flag_reset: range @name("feature7");}
        actions = {@defaultonly nop; SetCode7;}
        size = 2;
        const default_action = nop();
    }
    table table_feature8{
        key = {meta.udp_length: range @name("feature8");}
        actions = {@defaultonly nop; SetCode8;}
        size = 4;
        const default_action = nop();
    }
    table table_feature9{
        key = {meta.tcp_flag_fin: range @name("feature9");}
        actions = {@defaultonly nop; SetCode9;}
        size = 2;
        const default_action = nop();
    }

    /* Code tables */
	table code_table0{
	    key = {meta.codeword0: ternary;}
	    actions = {@defaultonly nop; SetClass0;}
	    size = 512;
        const default_action = nop();
	}

    /* Table to mitigate attack by dropping malicious packets */
    table mitigate_attack{
	    key = {meta.final_class: exact;}
	    actions = {@defaultonly nop; drop; ipv4_forward;}
	    size = 8;
        const default_action = nop();
	}

    apply {
            // apply feature tables to assign codes
            table_feature0.apply();
            table_feature1.apply();
            table_feature2.apply();
            table_feature3.apply();
            table_feature4.apply();
            table_feature5.apply();
            table_feature6.apply();
            table_feature7.apply();
            table_feature8.apply();
            table_feature9.apply();

            // apply code table to assign labels
            code_table0.apply();

            // apply mitigation table to drop malicious packets
            mitigate_attack.apply(); 
            
    } //end apply
} // end ingress control

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/
struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
