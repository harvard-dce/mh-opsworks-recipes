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
  echo "Usage: create-cluster-seed-file.sh -x -p <full path to shared matterhorn files>"
  echo
  echo "This creates a tarball at <shared matterhorn file path>/cluster_seed.tgz"
  echo "of the mysql data and matterhorn-generated files necessary to recreate"
  echo "this cluster in another environment. This is not meant as a backup, it is tooling"
  echo "to make automated testing easier."
  echo
  echo " -x	Actually create the backup"
  echo " -p	the full path to the root directory of the matterhorn files, probably on the shared workspace"
  echo
  exit 1;
fi

cluster_seed_path="$shared_files_path/cluster_seed"
db_backup_path="$shared_files_path/mysql_seed_backup"

/bin/mkdir -p "$cluster_seed_path"
/bin/mkdir -p "$db_backup_path"

/usr/bin/mysqldump --single-transaction --extended-insert --disable-keys --quick --set-charset --skip-comments matterhorn > "$db_backup_path/matterhorn.mysql"

cd "$shared_files_path"
tar -czf "$cluster_seed_path/cluster_seed.tgz" . --exclude="*/cluster_seed.tgz"
