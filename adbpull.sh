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

#Check device state
if [[ $device_state = "unauthorized" ]]; then
	echo "Device '$device_name' is unauthorized, please authorize on device and start script again."
	exit
fi

#Start ADB server
adb start-server
echo "ADB server started"
echo "Performing a backup of device $device_name saved on '$local_location'"

mkdir $local_location
#adb shell ls -a | while read line
pull_recur(){
	pull_object=$1
	# Remove backslash if already there

	for line in $(adb shell ls -a $pull_object)
	do
                if [[ $pull_object = "/" ]]; then
                        pull_object=""
                fi
		# Sanitize ls output
		line="${line//[^a-zA-Z0-9_.-]/}"
		# Skip /proc directory to prevent timeout errors
		if [ "$line" = "d" ] || [ "$line" = "proc" ] || [ "$line" = "sys" ]
		then
			echo "Skipped $line"
		else
			line="$pull_object"/"$line"
			echo "Trying to pull: $line"
			adb pull -a $line $local_location"$line"
			if [ ! $? -eq 0 ]
			then
				echo "Fail: $line"
			else
				hashFolder=$(tar c $local_location"$line" | sha256sum)
				echo "$hashFolder $local_location$line" | tee -a $local_location/hash.txt
			fi
		fi
	done
}
pull_recur $remote_location

#Make a hash of all pulled files
find $local_location -type f | while read files; do echo $(sha256sum "$files"); done > $local_location/hash_files.txt

