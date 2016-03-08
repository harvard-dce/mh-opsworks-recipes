#!/bin/bash

do_it=false
shared_files_path=

while :; do
  case $1 in
    -x)
      do_it=true
      ;;
    -p|--path)
      shared_files_path=$2
      shift 2
      continue
      ;;
    *)
      break
  esac

  shift
done

if ! $do_it; then
  echo
  echo "Usage: remove-all-matterhorn-files.sh -x -p <full path to shared matterhorn files>"
  echo
  echo " -x	Actually remove the files"
  echo " -p	the full path to the root directory of the matterhorn files, probably on the shared workspace"
  echo
  exit 1;
fi

if [ -z "$shared_files_path" ]; then
  echo 'Please provide a path to the root directory for where the files are stored'
  exit 1
fi

# TODO - remove the S3 files from the correct distribution bucket

/bin/rm -Rf $shared_files_path/*
