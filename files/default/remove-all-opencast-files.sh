#!/bin/bash

do_it=false
shared_files_path=
s3_distribution_bucket=

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
    -b|--s3_distribution_bucket)
      s3_distribution_bucket=$2
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
  echo "Usage: remove-all-opencast-files.sh -x -p <full path to shared opencast files>"
  echo
  echo " -x	Actually remove the files"
  echo " -p	the full path to the root directory of the opencast files, probably on the shared workspace"
  echo " -b or --s3_distribution_bucket	The s3 bucket used to hold the uploaded files for this cluster"
  echo
  exit 1;
fi

if [ -z "$shared_files_path" ]; then
  echo 'Please provide a path to the root directory for where the files are stored'
  exit 1
fi

/bin/rm -Rf $shared_files_path/*
aws s3 rm "s3://$s3_distribution_bucket" --recursive
