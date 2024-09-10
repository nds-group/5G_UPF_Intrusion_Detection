#!/bin/bash

# input directory where all the folders with pcaps of each attack type are located -  Train or Test
root_dir=$1

# Loop through each folder
for folder in "$root_dir"/*; do
    if [ -d "$folder" ]; then
        pcap_folder="$folder/"
        #create a folder to store the extracted packet data files
        pkt_folder="$folder/Pkt_Files"
        mkdir -p "$pkt_folder"

        # loop through the pcap files in each sub folder for processing
        for pcap_file in "$pcap_folder"/*.pcap; do
            if [ -f "$pcap_file" ]; then
                echo "Processing PCAP file: $(basename "$pcap_file")"
                # extract all the desired packet headers and save them to a csv file for onward processing
                tshark -r "$pcap_file" -Y 'ip.proto == 6 or ip.proto == 17 or ip.proto == 1' -T fields -e frame.time_relative -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e ip.len -e tcp.flags.syn -e tcp.flags.ack -e tcp.flags.push -e tcp.flags.fin -e tcp.flags.reset -e tcp.flags.ecn -e ip.proto -e udp.srcport -e udp.dstport -e eth.src -e eth.dst -e ip.hdr_len -e ip.tos -e ip.ttl -e tcp.window_size_value -e tcp.hdr_len -e udp.length -E separator='|' > "$pkt_folder/$(basename "$pcap_file" .pcap).csv"
            fi
        done
    fi
done
# run these scripts for both the train and test data