#!/bin/bash

pull_recur(){
	for line in $(adb shell ls -a $1)
	do
		line="$1"/"${line//[^a-zA-Z0-9]/}"
		if [ "$line" = "d" ] || [ "$line" = "proc" ] || [ "$line" = "sys" ]
		then
			echo "Skipped"
		else
			echo "$line"
			adb pull -a "$line" /mnt/isaacscript/pull_latest2/"$line"
			if [ ! $? -eq 0 ]
			then
				echo "Niet gelukt: $line"
				pull_recur "$line"
			fi
		fi
	done
}
pull_recur "$1"
