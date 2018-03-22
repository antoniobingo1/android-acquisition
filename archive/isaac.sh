#!/bin/bash

#If no arguments are given show usage
usage="adbpull.sh is a program that automates a pull of data on a Android device.\n
In order to use the program an argument has to be given where the backup (locally) will be stored...\n\n
e.g. ./adbpull.sh REMOTE LOCAL"

if [[ $# -eq 0 ]] ; then
	echo -e $usage
	exit 0
fi

#Declare variables from arguments
remote_location=$1
local_location=$2
device_name=$(adb devices | tail -2 | head -1 | awk '{print $1}')
device_state=$(adb devices | tail -2 | head -1 | awk '{print $2}')

#Start ADB server
adb start-server
echo "ADB server started"
echo "Performing a backup of device $device_name saved on '$local_location'"

#Check device state
if [[ $device_state = "unauthorized" ]]; then
	echo "Device '$device_name' is unauthorized, please authorize on device and start script again."
	exit
fi

mkdir $local_location

counter=0

pull_recur(){
	declare -A pull_object=()
	counter=$(($counter+1))
	pull_object[$counter]=$1
	echo "Pull object is: ${pull_object[$counter]} and counter is: $counter"

	# Pull files
	file=""
	for file in $(adb shell "ls -la ${pull_object[$counter]} | grep '^-' | grep -Eo '[^ ]+$'")
	do
		#line=$(echo $line | tr -d '\\t')
		file="${file//[^a-zA-Z0-9_.-]/}"
		echo "Trying to pull: ${pull_object[$counter]}"/"$file"
		adb pull -a "${pull_object[$counter]}"/"$file" "$local_location"/"${pull_object[$counter]}"/
		if [ ! $? -eq 0 ]
		then
			echo "Fail: ${pull_object[$counter]}/$file"
		fi
	done
	echo -e "\n\nPulled all files in directory: ${pull_object[$counter]} \n\n"

	# Recurse through directories
	directory=""
	for directory in $(adb shell "ls -la ${pull_object[$counter]} | grep '^d' | grep -Eo '[^ ]+$'")
	do
		echo "Before $directory - $counter - ${pull_object[$counter]}"
		directory="${directory//[^a-zA-Z0-9_.-]/}"
		echo "After $directory"
		adb shell "ls -la ${pull_object[$counter]} | grep '^d' | grep -Eo '[^ ]+$'"
		mkdir -p "$local_location"/"{$pull_object[$counter]}"/"$directory"
		echo -e "\n\n Calling function pull_recur ${pull_object[$counter]}/$directory \n\n"
		pull_recur "${pull_object[$counter]}/$directory"
	done
}
pull_recur $remote_location

#Make a hash of all pulled files
find $local_location -type f | while read files; do echo $(sha256sum "$files"); done > $local_location/hash_files.txt
