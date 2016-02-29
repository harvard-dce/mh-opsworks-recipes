#!/bin/bash

do_it=false
shared_files_path=

source_engage_ip=
source_engage_host=
source_admin_ip=
source_cloudfront_domain=
source_wowza_edge_url=
source_s3_bucket=

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
    --source_engage_ip)
      source_engage_ip=$2
      shift 2
      continue
      ;;
    --source_engage_host)
      source_engage_host=$2
      shift 2
      continue
      ;;
    --source_admin_ip)
      source_admin_ip=$2
      shift 2
      continue
      ;;
    --source_cloudfront_domain)
      source_cloudfront_domain=$2
      shift 2
      continue
      ;;
    --source_wowza_edge_url)
      source_wowza_edge_url=$2
      shift 2
      continue
      ;;
    --source_s3_bucket)
      source_s3_bucket=$2
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
s3_backup_path="$shared_files_path/s3_contents"

/bin/mkdir -p "$cluster_seed_path"
/bin/mkdir -p "$db_backup_path"

/usr/bin/mysqldump --single-transaction --extended-insert --disable-keys --quick --set-charset --skip-comments matterhorn > "$db_backup_path/matterhorn.mysql"

aws s3 sync s3://"$source_s3_bucket" "$s3_backup_path"

cd "$shared_files_path"

# The contents of this file are sourced when we re-load a seed so
# that we can fix hostnames correctly
echo "
# The hosts below are from the cluster this seed was extracted from
source_engage_ip='$source_engage_ip'
source_engage_host='$source_engage_host'
source_admin_ip='$source_admin_ip'
source_cloudfront_domain='$source_cloudfront_domain'
source_wowza_edge_url='$source_wowza_edge_url'
source_s3_bucket='$source_s3_bucket'
" > seed_cluster_hostnames.txt

tar -czf "$cluster_seed_path/cluster_seed.tgz" . --exclude="*/cluster_seed.tgz"
