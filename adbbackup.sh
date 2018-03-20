#!/bin/bash

#If no location is given show usage
usage="adbbackup.sh is a program that automates a full backup of a Android device.\n
In order to use the program an argument has to be given where the backup (locally) will be stored...\n\n

e.g. ./addbackup.sh /mnt/fullbackup.ab"
if [[ $# -eq 0 ]] ; then
	echo -e $usage
	exit 0
fi

#Declare variables from arguments
file_name=$1
extract_folder=$2
device_name=$(adb devices | tail -2 | head -1 | awk '{print $1}')
device_state=$(adb devices | tail -2 | head -1 | awk '{print $2}')

if [[ $device_state = "unauthorized" ]]; then
	echo "Device '$device_name' is unauthorized, please authorize on device and start script again."
	exit
fi

#Start ADB server
adb start-server
echo "ADB server started"
echo "Performing a backup of device $device_name saved on '$file_name'"


#Run backup
#.apk files, shared storage, all installed apps and system
#https://developer.android.com/studio/command-line/adb.html
adb backup -apk -shared -all -f $file_name
echo "Finshed backup! Now the hash of the backup will be calculated..."

#Get hash of the backup
hashAB=$(sha256sum $file_name)
echo "The hash of the file is: $hashAB"

#Extract backup
echo "Extracting backup"
mkdir $extract_folder
( printf "\x1f\x8b\x08\x00\x00\x00\x00\x00" ; tail -c +25 $file_name ) | tar xfz - -C $extract_folder
hashExtract=$(tar c $extract_folder | sha256sum)
echo "Extracted data hash: $hashExtract"
