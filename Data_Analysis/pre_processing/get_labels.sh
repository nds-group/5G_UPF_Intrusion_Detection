#!/bin/bash

# get label file for each attach
for csv_file in "$1"/*.csv; do
    if [ -f "$csv_file" ]; then
        echo "Processing CSV file: $(basename "$csv_file")"
        # generate the label file for the csv file
        python3 generate_label_files.py "$csv_file" "$2/$(basename "$csv_file" .csv)_label.csv"
    fi
done