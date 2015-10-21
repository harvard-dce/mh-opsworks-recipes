#!/bin/bash

do_it=false
index_path=

while :; do
  case $1 in
    -x)
      do_it=true
      ;;
    -p|--path)
      index_path=$2
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
  echo "Usage: remove-solr-indexes.sh -x -p <full path to indexes>"
  echo
  echo " -x	Actually remove the indexes"
  echo " -p	the full path to the root directory of the indexes, probably the local workspace"
  echo
  exit 1;
fi

if [ -z "$index_path" ]; then
  echo 'Please provide a path to the root directory for where the indexes are stored'
  exit 1
fi

/bin/rm -Rf $index_path/*index/
