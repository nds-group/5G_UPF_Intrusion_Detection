## Steps to run the code

Compile the P4 program after setting the SDE environment.
```
sudo -E ./p4_build.sh upf_intrusion_detection.p4
```

Launch the switch daemon with the compiled program.
```
sudo -E $SDE/run_switchd.sh -p upf_intrusion_detection
```

Check the table entries file. Modify the port setup according to your testbed and then load the table entries file using _bfrt_python_.
```
sudo -E $SDE/run_bfshell.sh -b table_entries_5G_upf_ID.py
```

- Send the test pcap files through the switch using _tcpreplay_ and test.
- By default the response table is active and so traffic from malware classes is dropped.
- To capture traffic from all classes, in the P4 program, comment the mitigate_attack.apply(); on line 333 and uncomment the ipv4_forward(260); on line 223. Also modify port 260 to the actual forwarding port on you device, and remove the table entries of the _mitigate_attack_ table in the table entries file.
- Collect classified traffic at your destination host as pcap files using _tcpdump_ at the output port and analyze. Classification results are stored in the TTL field of packets.