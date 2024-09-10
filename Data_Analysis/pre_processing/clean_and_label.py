import pandas as pd
import numpy as np
import sys

input_file = sys.argv[1] # file to be labelled
output_file = sys.argv[2] # name of output file - these two are catered for in the bash scripts

# label file
Labels = pd.read_csv(sys.argv[3])

packet_data = pd.DataFrame()

packet_data = pd.read_csv(input_file, sep = '|', header=None)

packet_data.columns = ["frame.time_relative","ip.src","ip.dst","tcp.srcport","tcp.dstport","ip.len",
                   "tcp.flags.syn","tcp.flags.ack","tcp.flags.push","tcp.flags.fin",
                   "tcp.flags.reset","tcp.flags.ece","ip.proto","udp.srcport","udp.dstport",
                   "eth.src","eth.dst", "ip.hdr_len", "ip.tos", "ip.ttl", "tcp.window_size_value", 
                   "tcp.hdr_len", "udp.length"]

packet_data = packet_data[(packet_data["ip.proto"] != "1,17") & (packet_data["ip.proto"] != "1,6")].reset_index(drop=True)
packet_data = packet_data.dropna(subset=['ip.proto'])
packet_data["ip.src"] = packet_data["ip.src"].astype(str)
packet_data["ip.dst"] = packet_data["ip.dst"].astype(str)
packet_data["ip.len"] = packet_data["ip.len"].astype("int")
packet_data["ip.proto"] = packet_data["ip.proto"].astype("int")
##the new features from either tcp or udp might have some NA which we set to 0
packet_data["tcp.window_size_value"] = packet_data["tcp.window_size_value"].astype('Int64').fillna(0)
packet_data["tcp.hdr_len"] = packet_data["tcp.hdr_len"].astype('Int64').fillna(0)
packet_data["udp.length"] = packet_data["udp.length"].astype('Int64').fillna(0)
##
packet_data["tcp.srcport"] = packet_data["tcp.srcport"].astype('Int64').fillna(0)
packet_data["tcp.dstport"] = packet_data["tcp.dstport"].astype('Int64').fillna(0)
packet_data["udp.srcport"] = packet_data["udp.srcport"].astype('Int64').fillna(0)
packet_data["udp.dstport"] = packet_data["udp.dstport"].astype('Int64').fillna(0)
##
packet_data["srcport"] = np.where(
    packet_data["ip.proto"] == 6, packet_data["tcp.srcport"],
    np.where(packet_data["ip.proto"] == 17, packet_data["udp.srcport"],
             np.where(packet_data["ip.proto"] == 1, 0, np.nan))
)

packet_data["dstport"] = np.where(
    packet_data["ip.proto"] == 6, packet_data["tcp.dstport"],
    np.where(packet_data["ip.proto"] == 17, packet_data["udp.dstport"],
             np.where(packet_data["ip.proto"] == 1, 0, np.nan))
)
##
packet_data["srcport"] = packet_data["srcport"].astype('Int64')
packet_data["dstport"] = packet_data["dstport"].astype('Int64')

## CREATE THE FLOW IDs AND DROP UNWANTED COLUMNS
packet_data = packet_data.drop(["tcp.srcport","tcp.dstport","udp.srcport","udp.dstport"],axis=1) #,"sctp.srcport","sctp.dstport"

packet_data = packet_data.reset_index(drop=True)

packet_data["flow.id"] = packet_data["ip.src"].astype(str) + " " + packet_data["ip.dst"].astype(str) + " " + packet_data["srcport"].astype(str) + " " + packet_data["dstport"].astype(str) + " " + packet_data["ip.proto"].astype(str)
packet_data["flow.id_rev"] = packet_data["ip.dst"].astype(str) + " " + packet_data["ip.src"].astype(str) + " " + packet_data["dstport"].astype(str) + " " + packet_data["srcport"].astype(str) + " " + packet_data["ip.proto"].astype(str)

# 3-tuple id of src ip, dst ip, and proto for icmp and udp flood
packet_data["flow.id_3tuple"] = packet_data["ip.src"].astype(str) + " " + packet_data["ip.dst"].astype(str) + " " + packet_data["ip.proto"].astype(str)
packet_data["flow.id_3tuple_rev"] = packet_data["ip.dst"].astype(str) + " " + packet_data["ip.src"].astype(str) + " " + packet_data["ip.proto"].astype(str)

# extract the 3-tuple id from the label file using the FLow ID column
split_columns = Labels["Flow ID"].str.split(" ", expand=True)
Labels["id_3tuple"] = split_columns[0] + " " + split_columns[1] + " " + split_columns[4]

# Labeling
flow_label_dict = Labels.set_index("Flow ID")["Attack Type"].to_dict()
flow_label_dict_3tuple = Labels.set_index("id_3tuple")["Attack Type"].to_dict()

packet_data["label"] = packet_data["flow.id"].map(flow_label_dict)
packet_data["label2"] = packet_data["flow.id_rev"].map(flow_label_dict)
packet_data["label"] = packet_data["label"].fillna(packet_data["label2"])

# if the label is '', then use the 3-tuple id to find the label
packet_data["label3"] = packet_data["flow.id_3tuple"].map(flow_label_dict_3tuple)
packet_data["label4"] = packet_data["flow.id_3tuple_rev"].map(flow_label_dict_3tuple)
packet_data["label3"] = packet_data["label3"].fillna(packet_data["label4"]) 
packet_data["label"] = packet_data["label"].fillna(packet_data["label3"]) 

# drop unwanted columns
packet_data = packet_data.drop(["label2","flow.id_rev","ip.tos","label3","label4","flow.id_3tuple","flow.id_3tuple_rev"],axis=1)

# Remove rows with srcport or dstport = 0 and label = Benign
packet_data = packet_data[~(((packet_data["srcport"]==0) | (packet_data["dstport"]==0)) & (packet_data['label']=='Benign'))]

# reset index
packet_data = packet_data.reset_index(drop=True)

# save final data to csv
packet_data.to_csv(output_file,index=False)
