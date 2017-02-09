#!/bin/bash -e
do_it=false
shared_files_path=
engage_ip=
engage_host=
admin_ip=
admin_host=
cloudfront_domain=
wowza_edge_url=

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
    --engage_ip)
      engage_ip=$2
      shift 2
      continue
      ;;
    --engage_host)
      engage_host=$2
      shift 2
      continue
      ;;
    --admin_ip)
      admin_ip=$2
      shift 2
      continue
      ;;
    --admin_host)
      admin_host=$2
      shift 2
      continue
      ;;
    --cloudfront_domain)
      cloudfront_domain=$2
      shift 2
      continue
      ;;
    --wowza_edge_url)
      wowza_edge_url=$2
      shift 2
      continue
      ;;
    *)
      break
  esac

  shift
done

source "$shared_files_path/seed_cluster_hostnames.txt"

if ! $do_it; then
  echo
  echo "Usage: modify-database-after-loading-seed-data.sh -x -p <full path to shared opencast files> --engage_ip <value> --engage_host <value> --admin_ip <value> --admin_host <value> --cloudfront_domain <value> --wowza_edge_url <value>"
  echo
  echo "This uses the cluster hostname manifest from the seed file and the current target"
  echo "cluster hostnames to modify the database after it's been loaded from the seeds"
  echo
  echo "-x	Actually do the thing"
  echo "-p or --path	Full path to the shared opencast files on nfs"
  echo "--engage_ip	The engage IP of the target cluster"
  echo "--engage_host	The engage hostname of the target cluster"
  echo "--admin_ip	The admin IP of the target cluster"
  echo "--admin_host	The hostname of the admin for the target cluster"
  echo "--cloudfront_domain	The video / image asset distribution domain - either the s3 bucket or cloudfront domain"
  echo "--wowza_edge_url	The current target wowza edge URL. Probably not necessary"
  echo

  exit 1;
fi
#
# executes a series of mysql update statements to prepare mh database to
# be moved from source cluster to target cluster
#
# - assumes opencast is stopped and haven't accessed the db yet
#


# uncomment if not already defined in environment
#MYSQL_MH_USER=opencast
#MYSQL_MH_PASSWD=password

# production values!
SOURCE_ENGAGE_IP="$source_engage_ip"
SOURCE_ENGAGE_HOST="$source_engage_host"
SOURCE_ADMIN_IP="$source_admin_ip"
SOURCE_ADMIN_HOST="$source_admin_host"
SOURCE_CLOUDFRONT_DOMAIN="$source_cloudfront_domain"
SOURCE_WOWZA_EDGE_URL="$source_wowza_edge_url"

TARGET_ENGAGE_IP="$engage_ip"
TARGET_ENGAGE_HOST="$engage_host"
TARGET_ADMIN_IP="$admin_ip"
TARGET_ADMIN_HOST="$admin_host"
TARGET_CLOUDFRONT_DOMAIN="$cloudfront_domain"
TARGET_WOWZA_EDGE_URL="$wowza_edge_url"

mh_episode_engage_ip_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, '${SOURCE_ENGAGE_IP}', '${TARGET_ENGAGE_HOST}' ) WHERE mediapackage_xml LIKE ('%${SOURCE_ENGAGE_IP}%');"

mh_episode_engage_host_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, '${SOURCE_ENGAGE_HOST}', '${TARGET_ENGAGE_HOST}') WHERE mediapackage_xml LIKE ('%${SOURCE_ENGAGE_HOST}%');"

mh_job_admin_ip_statement="UPDATE mh_job SET payload = REPLACE( payload, '${SOURCE_ADMIN_IP}', '${TARGET_ADMIN_IP}') WHERE operation = 'START_WORKFLOW' and payload like '%${SOURCE_ADMIN_IP}%';"

mh_job_admin_host_statement="UPDATE mh_job SET payload = REPLACE( payload, '${SOURCE_ADMIN_HOST}', '${TARGET_ADMIN_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%${SOURCE_ADMIN_HOST}%';"

mh_job_engage_ip_statement="UPDATE mh_job SET payload = REPLACE( payload, '${SOURCE_ENGAGE_IP}', '${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%${SOURCE_ENGAGE_IP}%';"

mh_job_engage_host_statement="UPDATE mh_job SET payload = REPLACE( payload, '${SOURCE_ENGAGE_HOST}', '${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%${SOURCE_ENGAGE_HOST}%';"

mh_search_cloudfront_statement="UPDATE mh_search SET mediapackage_xml = REPLACE( mediapackage_xml, '${SOURCE_CLOUDFRONT_DOMAIN}', '${TARGET_CLOUDFRONT_DOMAIN}') WHERE mediapackage_xml like '%${SOURCE_CLOUDFRONT_DOMAIN}%';"

mh_search_wowza_edge_url_statement="UPDATE mh_search SET mediapackage_xml = REPLACE( mediapackage_xml, '${SOURCE_WOWZA_EDGE_URL}', '${TARGET_WOWZA_EDGE_URL}') WHERE mediapackage_xml like '%${SOURCE_WOWZA_EDGE_URL}%';"

mh_service_registration_deactivate_statement="UPDATE mh_service_registration SET active = 0;"
mh_service_registration_offline_statement="UPDATE mh_service_registration SET online = 0;"
mh_host_registration_deactivate_statement="UPDATE mh_host_registration SET active = 0;"
mh_host_registration_offline_statement="UPDATE mh_host_registration SET online = 0;"
mh_host_registration_maintenance_statement="UPDATE mh_host_registration SET maintenance = 1;"

for statement in "${mh_episode_engage_ip_statement}" "${mh_episode_engage_host_statement}" "${mh_job_admin_ip_statement}" "${mh_job_admin_host_statement}" "${mh_job_engage_ip_statement}" "${mh_job_engage_host_statement}" "${mh_search_cloudfront_statement}" "${mh_search_wowza_edge_url_statement}" "${mh_service_registration_deactivate_statement}" "${mh_host_registration_deactivate_statement}" "${mh_service_registration_offline_statement}" "${mh_host_registration_offline_statement}" "${mh_host_registration_maintenance_statement}"
do
    echo "EXECUTING STATEMENT: ${statement}"
    echo
    mysql -e "${statement}" opencast
    echo
done


