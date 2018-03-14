#!/bin/bash

adb shell 'counter(){
for file in "$1"/*
  do
    if [ -d "$file" ]
    then
      if [ ls "$file" ]
      then
        echo "$file"
      else
        counter "$file"
      fi
    fi
  done
}

counter
'
