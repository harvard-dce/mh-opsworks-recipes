#!/bin/bash

do_it=false
file_path=

while :; do
  case $1 in
    -x)
      do_it=true
      ;;
    -f|--file)
      file_path=$2
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
  echo "Usage: reset-mysql-database.sh -x -f <seed file>"
  echo
  echo " -x	Actually do the database reset"
  echo " -f	the full path to the database seed file"
  echo
  exit 1;
fi

if [ -z "$file_path" ]; then
  echo 'Please provide a seed file in -f or --file'
  exit 1
fi

/usr/bin/mysql -e 'drop database matterhorn; create database matterhorn'
/usr/bin/mysql matterhorn < "$file_path"
