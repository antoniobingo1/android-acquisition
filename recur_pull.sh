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
pull_recur(){
	local pull_object=$1
	echo "Pull object is: $pull_object"
	if [ "$pull_object" == "//acct" ] || [ "$pull_object" == "//mnt/shell/emulated/0/Android" ]; then
		return;
	fi;

	# Pull files
	local list_of_files=$(adb shell "ls -la '$pull_object' | grep '^-' | grep -Eo '[^ ]+$'")
        echo "$list_of_files" | grep 'No such file' &> /dev/null
	if [ $? == 0 ]
	then
	        echo "Failure on list for files: No such file or directory"
        else
        	echo "$list_of_files" | grep 'opendir failed' &> /dev/null
		if [ ! $? == 0 ]
		then
			echo "Our pretty list of files is $list_of_files"
			for file in $list_of_files
			do
				local file="$(echo -n "$file" | tr -d '\r')"
				if [ "$pull_object/$file" == "//proc/mlog" ] || [ "$pull_object/$file" == "//proc/ccci_log" ] || [ "$pull_object/$file" == "//proc/sysram" ] || [ "$pull_object/$file" == "//proc/zraminfo" ] || [ "$pull_object/$file" == "//proc/sysram_flag" ]
				then
					continue;
				fi
				echo "Trying to pull: $pull_object"/"$file"
				adb pull -a "$pull_object"/"$file" "$local_location"/"$pull_object"/
				if [ ! $? -eq 0 ]
				then
					echo "Fail: $pull_object/$file"
				fi
			done
		else
			echo "Failure on list for files: opendir failed, Permission denied"
		fi
	fi
	echo -e "\n\nPulled all files in directory: $pull_object \n\n"

	# Recurse through directories
	local list_of_dirs=$(adb shell "ls -la '$pull_object' | grep '^d' | grep -Eo '[^ ]+$'")
        echo $list_of_dirs | grep 'No such file' &> /dev/null
	if [ $? == 0 ]
	then
		echo "Failure on list for directories: No such file or directory"
	else
		echo $list_of_dirs | grep 'opendir failed' &> /dev/null
		if [ ! $? == 0 ]
		then
			if [ ! -z "$list_of_dirs" ]
			then
				for directory in $list_of_dirs
				do
					local directory="$(echo -n "$directory" | tr -d '\r')"
					echo "List of dirs = $list_of_dirs"
					mkdir -p "$local_location"/"$pull_object"/"$directory"
					echo "Pull_object = $pull_object and dir = $directory"
					echo -e "\n\n Calling function pull_recur $pull_object/$directory \n\n"
					pull_recur "$pull_object/$directory"
				done
			else
				echo "No directories found"
			fi
		else
			echo "Failure on list for directories: opendir, Permission denied"
		fi
	fi
}
pull_recur $remote_location

#Make a hash of all pulled files
find $local_location -type f | while read files; do echo $(sha256sum "$files"); done > $local_location/hash_files.txt
