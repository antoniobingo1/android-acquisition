#!/usr/bin/env python3

import sys
import os
import subprocess
import shlex

remote_location = sys.argv[1]
local_location = sys.argv[2]

try:
  os.mkdir(local_location)
except:
  print("File exists")

# Print array
#  for i in ls_array:
#    print(i)

def pull_recur(pull_object_unescaped):
  # List files to pull
  pull_object = shlex.quote(pull_object_unescaped)
  print(pull_object)
  ls_output_files = subprocess.check_output(['adb', 'shell', 'ls', '-la', pull_object, '|', 'grep', '"^-"'])
  # Test for access to the directory
  ls_output_files = ls_output_files.decode('utf-8')
  if "Permission denied" in ls_output_files:
    print("Permission denied: returning")
    return 0

  print(ls_output_files)

  # Go over each file in array and pull
  files_array = ls_output_files.split('\n')
  for i in files_array:
    try:
      file=i.split()[-1]
    except(IndexError):
      print(IndexError)
      continue
    print("Trying to pull",file)
    subprocess.run(['adb', 'pull', '-a', pull_object+"/"+file, local_location+"/"+pull_object_unescaped+"/"])

  # List directories to recurse through
  ls_output_dirs = subprocess.check_output(['adb', 'shell', 'ls', '-la', pull_object, '|', 'grep', '"^d"'])

  # Go over each dir in array and call recursive function on that directory
  dirs_array = ls_output_dirs.decode('utf-8').split('\n')
  for i in dirs_array:
    print(i)
  for i in dirs_array:
    try:
      dir=i.split()[-1]
    except(IndexError):
      print(IndexError)
      continue
    print("\nCreating local directory",dir)
    try:
      os.mkdir(local_location+"/"+pull_object_unescaped+"/"+dir)
    except:
      print("Error: file exists")
    print("Calling function pull_recur with argument", pull_object_unescaped+"/"+dir, "\n")
    pull_recur(pull_object_unescaped+"/"+dir)

pull_recur(remote_location)
