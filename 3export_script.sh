#!/bin/bash

#root_list=$(adb shell ls -la /)

#adb shell ls -a | while read line
for line in $(adb shell ls -a)
do
	line=${line//[^a-zA-Z0-9]/}
	if [ "$line" = "d" ] || [ "$line" = "proc" ]
	then
		echo "Skipped"
	else
		echo "$line"
		adb pull -a $line ./pull_latest
		if [ ! $? -eq 0 ]
		then
			echo "Niet gelukt: $line"
		fi
	fi
done
