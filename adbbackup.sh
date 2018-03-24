#!/bin/bash

#If no location is given show usage
usage="adbbackup.sh is a program that automates a full backup of a Android device.\n
In order to use the program an argument has to be given where the backup (locally) will be stored...\n\n

e.g. ./addbackup.sh /location/backup.ab extract_folder"
if [[ $# -eq 0 ]] ; then
	echo -e $usage
	exit 0
fi

#Declare variables from arguments
backup_location=$1
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
echo "Performing a backup of device $device_name saved on '$backup_location'"

#Create folder where backup will be stored
mkdir "$(dirname $backup_location)"

#Run backup
#.apk files, shared storage, all installed apps and system
#https://developer.android.com/studio/command-line/adb.html
adb backup -apk -shared -all -f $backup_location
echo "Finshed backup! Now the backup will be extracted... This could take some time."

#Extract backup
mkdir $extract_folder
( printf "\x1f\x8b\x08\x00\x00\x00\x00\x00" ; tail -c +25 $backup_location ) | tar xfz - -C $extract_folder

#Get hashes
hash_backup=$(sha256sum $backup_location)
echo $hash_backup > $(dirname $backup_location)/hash_backup.txt
echo "A hash of the backup-file can be found in '$(dirname $backup_location)/hash_backup.txt'"
echo "Now a hash of all all files is created... This could take some time."
find $extract_folder -type f | while read files; do echo $(sha256sum "$files"); done > $extract_folder/hash_files.txt
echo "A hash of all the files can be found in '$extraxt_folder/hash_files.txt'"
