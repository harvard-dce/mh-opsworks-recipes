#!/bin/bash

do_it=false
shared_files_path=

source_engage_ip=
source_engage_host=
source_admin_ip=
source_admin_host=
source_cloudfront_domain=
source_wowza_edge_url=
source_s3_bucket=
base_cluster_seed_name=
upload_s3_bucket=

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
    --source_admin_host)
      source_admin_host=$2
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
    --upload_s3_bucket)
      upload_s3_bucket=$2
      shift 2
      continue
      ;;
    --base_cluster_seed_name)
      base_cluster_seed_name=$2
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
  echo "Usage: create-cluster-seed-file.sh -x -p <full path to shared opencast files>"
  echo
  echo "This creates a tarball at <shared opencast file path>/<your seed cluster name>.tgz"
  echo "of the mysql data and opencast-generated files necessary to recreate"
  echo "this cluster in another environment. This is not meant as a backup, it is tooling"
  echo "to make automated testing easier. After the seed file is created, it is uploaded"
  echo "to the bucket defined as --upload_s3_bucket in the options."
  echo
  echo " -x	Actually create the seed file"
  echo " -p or --path	the full path to the root directory of the opencast files, probably on the shared workspace"
  echo " --source_engage_ip	 the engage IP of the seed cluster"
  echo " --source_engage_host	 the external engage hostname of the seed cluster"
  echo " --source_admin_ip	 the external admin IP of the seed cluster"
  echo " --source_admin_host	 the external hostname for the admin node of the seed cluster"
  echo " --source_cloudfront_domain	 the domain that assets are delivered over - either s3 or cloudfront"
  echo " --source_wowza_edge_url	 The wowza URL. Probably not necessary"
  echo " --source_s3_bucket	 The s3 distribution bucket for the seed cluster"
  echo " --upload_s3_bucket	 The s3 bucket used to store cluster seeds"
  echo " --base_cluster_seed_name	 The name (sans file extension) for the seed file created by this process. Alphanumeric, no spaces."
  echo
  exit 1;
fi

cluster_seed_path="$shared_files_path/cluster_seed"
db_backup_path="$shared_files_path/mysql_seed_backup"
s3_backup_path="$shared_files_path/s3_contents"
cluster_seed_file_path="$cluster_seed_path/${base_cluster_seed_name}.tgz"

/bin/mkdir -p "$cluster_seed_path"
/bin/mkdir -p "$db_backup_path"

/usr/bin/mysqldump --single-transaction --extended-insert --disable-keys --quick --set-charset --skip-comments opencast > "$db_backup_path/opencast.mysql"

aws s3 sync s3://"$source_s3_bucket" "$s3_backup_path"

cd "$shared_files_path"

# The contents of this file are sourced when we re-load a seed so
# that we can fix hostnames correctly
echo "
# The hosts below are from the cluster this seed was extracted from
source_engage_ip='$source_engage_ip'
source_engage_host='$source_engage_host'
source_admin_ip='$source_admin_ip'
source_admin_host='$source_admin_host'
source_cloudfront_domain='$source_cloudfront_domain'
source_wowza_edge_url='$source_wowza_edge_url'
source_s3_bucket='$source_s3_bucket'
source_cluster='$base_cluster_seed_name'
upload_s3_bucket='$upload_s3_bucket'

" > seed_cluster_hostnames.txt

tar -czf "$cluster_seed_file_path" . --exclude="*/*.tgz"

aws s3 cp "$cluster_seed_file_path" "s3://$upload_s3_bucket"
