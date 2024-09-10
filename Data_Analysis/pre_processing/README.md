## Instructions for reproducing the labelled _csv_ files
Download the data from [https://ieee-dataport.org/documents/5g-nidd](https://ieee-dataport.org/documents/5g-nidd-comprehensive-network-intrusion-detection-dataset-generated-over-5g-wireless) and extract the files into your _data_ folder.

### Generating the label files
To generate the label files, we employ the _each_attack_csv_ files from each base station and the _get_labels.sh_ script. The output is saved in the respective _attack_labels_ folder.
```
bash get_labels.sh ./data/BS1_each_attack_csv ./data/BS1_attack_labels/
bash get_labels.sh ./data/BS2_each_attack_csv ./data/BS2_attack_labels/
```

### Extracting and labelling the packet data
As we do not simulate the full 5G architecture, we take the pcaps with GTP layer removed, e.g., those in _BS1_GTP_removed.zip_.

Split the pcap files into Train and Test pcaps using the 75-25 split ratio.
```
python3 split_pcaps.py ./data/BS1_GTP_removed
python3 split_pcaps.py ./data/BS2_GTP_removed
```
Extract the packet data as follows.
```
bash get_pkt_data.sh ./data/BS1_GTP_removed
bash get_pkt_data.sh ./data/BS2_GTP_removed
```
Label the extracted packet data using the previously generated label files.
```
bash get_labeled_pkt_data.sh ./data/BS1_GTP_removed ./data/BS1_attack_labels/
bash get_labeled_pkt_data.sh ./data/BS2_GTP_removed ./data/BS2_attack_labels/
```

### Merging the generated data
Use the _load_and_merge.py_ script to merge the respective test/train files for each base station. Then use the same script to merge the final test/train csv files from both base stations to generate the final test and train files.

Our generated train and test data following the above steps are provided at https://box.networks.imdea.org/s/bTD6fBakwWLrHp2.