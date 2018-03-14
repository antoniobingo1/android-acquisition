#!/bin/bash

#root_list=$(adb shell ls -la /)

#adb shell ls -a | while read line
pull_recur(){
	for line in $(adb shell ls -a $1)
	do
		line="${line//[^a-zA-Z0-9_.-]/}"
		if [ "$line" = "etc" ]
		then
			echo "Skipped"
		else
			line="$1"/"$line"
			echo "$line"
			adb pull -a $line /mnt/isaacscript/pull_latest2/"$line"
			if [ ! $? -eq 0 ]
			then
				echo "Niet gelukt: $line"
			fi
		fi
	done
}
pull_recur $1
