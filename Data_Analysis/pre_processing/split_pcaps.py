import os
import shutil
from scapy.all import *
import random
import sys

# Point the location containing your split pcap files.
parent_folder = sys.argv[1]

train_folder = os.path.join(parent_folder, "Train")
test_folder = os.path.join(parent_folder, "Test")
os.makedirs(train_folder, exist_ok=True)
os.makedirs(test_folder, exist_ok=True)

# Traverse through each pcap file in the folder
for pcap_file in os.listdir(parent_folder):

    pcap_file_path = os.path.join(parent_folder, pcap_file)

    if pcap_file.endswith(".pcapng") or pcap_file.endswith(".pcap"):

        # Load the pcap file with Scapy and split it into train and test sets using 75-25 split ratio
        packets = rdpcap(pcap_file_path)
        total_packets = len(packets)
        
        # Convert PacketList to a regular list
        packets_list = list(packets)

        # Shuffle the packets
        random.shuffle(packets_list)

        # Split the packets into train and test sets
        total_packets = len(packets_list)
        train_packets = packets_list[:int(0.75 * total_packets)]
        test_packets = packets_list[int(0.75 * total_packets):]

        # Sort the packets by timestamp in ascending order
        train_packets.sort(key=lambda pkt: pkt.time)
        test_packets.sort(key=lambda pkt: pkt.time)

        # Add a suffix to the two new files to specify whehter they are train or test
        train_pcap_file = os.path.join(parent_folder, os.path.splitext(pcap_file)[0] + "_train.pcap")
        test_pcap_file = os.path.join(parent_folder, os.path.splitext(pcap_file)[0] + "_test.pcap")

        wrpcap(train_pcap_file, train_packets)
        wrpcap(test_pcap_file, test_packets)

        # Move files to Train or Test folder based on suffix
        if "_train" in train_pcap_file:
            shutil.move(train_pcap_file, os.path.join(train_folder, os.path.basename(train_pcap_file)))
        if "_test" in test_pcap_file:
            shutil.move(test_pcap_file, os.path.join(test_folder, os.path.basename(test_pcap_file)))

print("Files split and saved in test and train folders.")
