## Instructions for reproducing the labelled _csv_ files
- Download the data from [https://ieee-dataport.org/documents/5g-nidd](https://ieee-dataport.org/documents/5g-nidd-comprehensive-network-intrusion-detection-dataset-generated-over-5g-wireless) 
- Extract the files into a folder


- Run the _split_pcaps.py_ script using the above folder as the input folder. 
    - This will create two folders; Train and Test, each containing a pcap which is respectively 75% and 25% of each original pcap from the individual folders.

- For each folder Train or Test, run the _get_pkt_data.sh_ script to extract the packet data from the pcap files.
- For each folder Train or Test, run the _get_labeled_pkt_data.sh_ script to label the extracted packet data. This script depends on the _clean_and_label.py_ script which itself uses the Data_Analysis_DNP3_labs_unique.csv file.
- Use the _load_and_merge.py_ script to merge the csv files generated from the step above to create a train and test csv file.
    - Our generated Train and Test data are provided at https://box.networks.imdea.org/s/M8QFbsKJHzykeIb.

- Use the _./model_training/DNP3_Data_Analysis_packet.ipynb_ script to train, evaluate and save models. You can also re-generate our diagrams from there.
    - Our saved model is provided in the _./model_training/dt_model_dnp3_7_classes.pkl_ file.
- Use the _./model_training/generate_table_entries.py_ file to generate the match & action table entries from the saved model file.
    - We provide our table entries for direct use in the _./User_Plane_Inference/te_dnp3_attack_pl_model.py_ file.