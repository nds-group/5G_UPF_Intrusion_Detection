import pandas as pd
import numpy as np
import os
import sys

input_file = sys.argv[1] # file to be labelled
output_file = sys.argv[2] # name of output file

# function to create the label file
def create_label_file(input_file):
    
    data = pd.read_csv(input_file)
    print("Data loaded")    
    five_tup_dat = data[['SrcAddr', 'DstAddr', 'Sport', 'Dport', 'Proto', 'Label', 'Attack Type']]

    five_tup_dat = five_tup_dat[five_tup_dat['Proto'].isin(['tcp', 'udp', 'icmp'])]
    proto_map = {'tcp': int(6), 'udp': int(17), 'icmp': int(1)}
    five_tup_dat['Proto'] = five_tup_dat['Proto'].map(proto_map)
    
    iana_ports = pd.read_csv("service-names-port-numbers.csv")

    # remove any spaces in the entries of the service name column
    iana_ports['Service Name'] = iana_ports['Service Name'].str.replace(' ', '')

    port_map = dict(zip(iana_ports['Service Name'], iana_ports['Port Number']))
    
    five_tup_dat['Sport'] = five_tup_dat['Sport'].map(port_map).fillna(five_tup_dat['Sport'])
    five_tup_dat['Dport'] = five_tup_dat['Dport'].map(port_map).fillna(five_tup_dat['Dport'])

    port_map2 = {'https': "443", 'ssh': "22"}
    five_tup_dat['Sport'] = five_tup_dat['Sport'].map(port_map2).fillna(five_tup_dat['Sport'])
    five_tup_dat['Dport'] = five_tup_dat['Dport'].map(port_map2).fillna(five_tup_dat['Dport'])

    five_tup_dat['Flow ID'] = five_tup_dat['SrcAddr'] + ' ' + five_tup_dat['DstAddr'] + ' ' + five_tup_dat['Sport'].astype(str) + ' ' + five_tup_dat['Dport'].astype(str) + ' ' + five_tup_dat['Proto'].astype(str)
    
    label_file = five_tup_dat[['Flow ID', 'Label', 'Attack Type']]
    label_file = label_file.drop_duplicates(keep='first')

    #save the output to a csv file
    label_file.to_csv(output_file, index=False)

    print("Label file created")

# create the label file
create_label_file(input_file)