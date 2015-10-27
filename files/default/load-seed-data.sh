#!/bin/bash

do_it=false
shared_files_path=
bucket_name=
seed_file=

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
    -b|--bucket_name)
      bucket_name=$2
      shift 2
      continue
      ;;
    -s|--seed_file)
      seed_file=$2
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
  echo "Usage: load-seed-data.sh -x -p <full path to shared matterhorn files> -b <shared asset bucket name> -s <seed file name>"
  echo
  echo " -x	Actually load the seed data"
  echo " -p	the full path to the root directory of the matterhorn files, probably on the shared workspace"
  echo " -b	the bucket name that contains the seed file"
  echo " -s	the seed file name - probably cluster_seed.tgz"
  echo
  exit 1;
fi

if [ -z "$shared_files_path" ]; then
  echo 'Please provide a path to the root directory for where the files are stored'
  exit 1
fi

if [ -z "$bucket_name" ]; then
  echo 'Please provide a bucket_name'
  exit 1
fi

if [ -z "$seed_file" ]; then
  echo 'Please provide a seed_file'
  exit 1
fi

cd $shared_files_path

aws s3 cp s3://"$bucket_name"/"$seed_file" .
tar xvfz "$seed_file"
rm "$seed_file"

/usr/bin/mysql matterhorn < "$shared_files_path/mysql_seed_backup/matterhorn.mysql"

# TODO - modify hosts in the database via some version of the provision script from nmaekawa
