#!/bin/bash

counter(){
  for file in "$
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

counter "$1"
