#!/bin/bash

#If no arguments are given show usage
usage="adbpull.sh is a program that automates a (recursive) pull of data on a Android device.\n
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
pull_recur(){
	local pull_object=$1
	echo "Pull object is: $pull_object"

	# Check if folder is /proc or /sys and if so skip folder
	if [ "$pull_object" == "//proc" ] || [ "$pull_object" == "//sys" ]
	then
		return
	fi

	# Pull files
	local list_of_files=$(adb shell "ls -la '$pull_object' | grep '^-' | grep -Eo '[^ ]+$'")
        echo "$list_of_files" | grep 'No such file' &> /dev/null
	if [ $? == 0 ]
	then
	        echo "Failure on list for files: No such file or directory"
        else
        	echo "$list_of_files" | grep -i 'permission denied' &> /dev/null
		if [ ! $? == 0 ]
		then
			echo -e "List of files:\n$list_of_files\n"
			for file in $list_of_files
			do
				local file="$(echo -n "$file" | tr -d '\r')"
				#if [ "$pull_object/$file" == "FILE" ]
				#then
				#	continue
				#fi
				echo "Trying to pull: $pull_object"/"$file"
				adb pull -a "$pull_object/$file" "$local_location/$pull_object/"
				if [ ! $? -eq 0 ]
				then
					echo "Failure on: $pull_object/$file"
				fi
			done
		else
			echo "Failure on list for files: Permission denied"
		fi
	fi
	echo -e "\n\nPulled all files in directory: $pull_object\n\n"

	# Recurse through directories
	local list_of_dirs=$(adb shell "ls -la '$pull_object' | grep '^d' | grep -Eo '[^ ]+$'")
        echo $list_of_dirs | grep 'No such file' &> /dev/null
	if [ $? == 0 ]
	then
		echo "Failure on list for directories: No such file or directory"
	else
		echo $list_of_dirs | grep -i 'permission denied' &> /dev/null
		if [ ! $? == 0 ]
		then
			# Check if an empty list of directory is returned
			if [ ! -z "$list_of_dirs" ]
			then
				echo -e "List of directories:\n$list_of_dirs\n"
				for directory in $list_of_dirs
				do
					local directory="$(echo -n "$directory" | tr -d '\r')"
					mkdir -p "$local_location"/"$pull_object"/"$directory"
					echo "Pull_object = $pull_object and dir = $directory"
					echo -e "\n\n Calling function pull_recur $pull_object/$directory \n\n"
					pull_recur "$pull_object/$directory"
				done
			else
				echo "Failure on $pull_object: No directories found"
			fi
		else
			echo "Failure on list for directories: Permission denied"
		fi
	fi
}
pull_recur $remote_location

#Make a hash of all pulled files
echo "Done pulling all files from '$remote_location', now creating a hash of all files... This could take some time."
find $local_location -type f | while read files; do echo $(sha256sum "$files"); done > $local_location/hash_files.txt
echo "A hash of all the files can be found in '$local_location/hash_files.txt'"
