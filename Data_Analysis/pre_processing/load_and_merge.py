import pandas as pd
import os
import sys

# use this script to load and merge generated csv files in the folder_path

folder_path = sys.argv[1]
outfile = sys.argv[2]

# get a list of all .csv files in the input folder
csv_files = [file for file in os.listdir(folder_path) if file.endswith('.csv')]

# create an empty DataFrame to store the combined data
combined_data = pd.DataFrame()

for i, file in enumerate(csv_files):

    # read the data from the .csv file
    data = pd.read_csv(os.path.join(folder_path, file))

    # set the header of the merged data to the header of the first file
    if i == 0:
        combined_data = data
    else:
        combined_data = combined_data.append(data, ignore_index=True)
        
# save the combined data to a new .csv file
combined_data.to_csv(outfile, index=False)
