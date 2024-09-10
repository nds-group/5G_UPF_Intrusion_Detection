# Towards Real-Time Intrusion Detection in P4-Programmable 5G User Plane Functions

 This repository contains the code for our work on intrusion detection in P4-programmable 5G User Plane Functions (UPF) based on programmable switches.

The paper will be presented at the 7th European P4 Workshop (EuroP4’24), co-located with The 32nd IEEE International Conference on Network Protocols (ICNP 2024), Charleroi, Belgium, October 28-31, 2024.

We show that by leveraging recent advances in (i) hardware acceleration of 5G UPFs with programmable switches, and (ii) user-plane ML inference in programmable switches, we can enable real-time and high-speed intrusion detection on 5G networks. For details, please check out [our paper](#).

## Organization of the repository  
There are two folders:  
- _User_Plane_ : P4 code compiled and tested on an Intel Tofino switch, and the model table entries file.
- _Data_Analysis_ : scripts and instructions for processing the data, the jupyter notebooks for training the machine learning models, and the python scripts for generating the M/A table entries from the saved trained models.

## Use case
To evaluate the proposed solution, an intrusion detection use case based on the [5G-NIDD dataset](https://ieee-dataport.org/documents/5g-nidd-comprehensive-network-intrusion-detection-dataset-generated-over-5g-wireless) is targeted. The challenge is to classify 5G traffic into one of 9 classes of which 1 is benign and 8 are malicious.

If you make use of our code, please cite our paper.

```
@inproceedings{akem_icnp2024,
author = {Akem, Aristide Tanyi-Jong and Fiore, Marco},
title = {Towards Real-Time Intrusion Detection in P4-Programmable 5G User Plane Functions},
year = {2024},
booktitle = {IEEE ICNP 2024 - IEEE International Conference on Network Protocols},
numpages = {6},
keywords = {Machine learning, 5G, user plane function, P4},
}
```

If you need any additional information, send us an email at _aristide.akem_ at _imdea.org_.