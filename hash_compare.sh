#!/bin/bash

# Small script to compare two hash files
# Arguments are the two hash files to compare

# Print only the hashes and not the file location/file name
cat $1 | awk '{print($1)}' > /tmp/hashes_of_file_1
cat $2 | awk '{print($1)}' > /tmp/hashes_of_file_2

# Get the hashes that occur in file 1 but not in file 2
hashes=$(diff /tmp/hashes_of_file_1 /tmp/hashes_of_file_2 | grep -v "^>" | awk '{print($2)}')

# Get the contents of file 1 including the file locations/file names
files=$(cat $1)

for hash in $hashes
do
	# Print the hash+file location for every hash that only occurs in file 1
	echo "$files" | grep "$hash"
done
