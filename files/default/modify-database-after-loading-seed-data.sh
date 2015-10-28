#!/bin/bash -e
do_it=false
shared_files_path=
engage_ip=
engage_host=
admin_ip=
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
  echo "Usage: modify-database-after-loading-seed-data.sh -x -p <full path to shared matterhorn files> --engage_ip <value> --engage_host <value> --admin_ip <value> --cloudfront_domain <value> --wowza_edge_url <value>"
  echo
  echo "This uses the cluster hostname manifest from the seed file to and the current"
  echo "cluster hostnames to modify the database after it's been loaded from the seeds"

  exit 1;
fi
#
# executes a series of mysql update statements to prepare mh database to
# be moved from source cluster to target cluster
#
# - assumes matterhorn is stopped and haven't accessed the db yet
#


# uncomment if not already defined in environment
#MYSQL_MH_USER=matterhorn
#MYSQL_MH_PASSWD=password

# production values!
SOURCE_ENGAGE_IP="$source_engage_ip"
SOURCE_ENGAGE_HOST="$source_engage_host"
SOURCE_ADMIN_IP="$source_admin_ip"
SOURCE_CLOUDFRONT_DOMAIN="$source_cloudfront_domain"
SOURCE_WOWZA_EDGE_URL="$source_wowza_edge_url"

TARGET_ENGAGE_IP="$engage_ip"
TARGET_ENGAGE_HOST="$engage_host"
TARGET_ADMIN_IP="$admin_ip"
TARGET_CLOUDFRONT_DOMAIN="$cloudfront_domain"
TARGET_WOWZA_EDGE_URL="$wowza_edge_url"

mh_episode_engage_ip_http_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, 'http://${SOURCE_ENGAGE_IP}', 'https://${TARGET_ENGAGE_HOST}' ) WHERE mediapackage_xml LIKE ('%http://${SOURCE_ENGAGE_IP}%');"

mh_episode_engage_ip_https_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, 'https://${SOURCE_ENGAGE_IP}', 'https://${TARGET_ENGAGE_HOST}' ) WHERE mediapackage_xml LIKE ('%https://${SOURCE_ENGAGE_IP}%');"

mh_episode_engage_host_http_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, 'http://${SOURCE_ENGAGE_HOST}', 'https://${TARGET_ENGAGE_HOST}') WHERE mediapackage_xml LIKE ('%http://${SOURCE_ENGAGE_HOST}%');"

mh_episode_engage_ip_https_statement="UPDATE mh_episode_episode SET mediapackage_xml = REPLACE( mediapackage_xml, 'https://${SOURCE_ENGAGE_HOST}', 'https://${TARGET_ENGAGE_HOST}' ) WHERE mediapackage_xml LIKE ('%https://${SOURCE_ENGAGE_HOST}%');"

mh_job_admin_ip_statement="UPDATE mh_job SET payload = REPLACE( payload, 'http://${SOURCE_ADMIN_IP}', 'http://${TARGET_ADMIN_IP}') WHERE operation = 'START_WORKFLOW' and payload like '%http://${SOURCE_ADMIN_IP}%';"

mh_job_engage_ip_http_statement="UPDATE mh_job SET payload = REPLACE( payload, 'http://${SOURCE_ENGAGE_IP}', 'https://${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%http://${SOURCE_ENGAGE_IP}%';"

mh_job_engage_ip_https_statement="UPDATE mh_job SET payload = REPLACE( payload, 'https://${SOURCE_ENGAGE_IP}', 'https://${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%https://${SOURCE_ENGAGE_IP}%';"

mh_job_engage_host_http_statement="UPDATE mh_job SET payload = REPLACE( payload, 'http://${SOURCE_ENGAGE_HOST}', 'https://${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%http://${SOURCE_ENGAGE_HOST}%';"

mh_job_engage_ip_https_statement="UPDATE mh_job SET payload = REPLACE( payload, 'https://${SOURCE_ENGAGE_HOST}', 'https://${TARGET_ENGAGE_HOST}') WHERE operation = 'START_WORKFLOW' and payload like '%https://${SOURCE_ENGAGE_HOST}%';"

################################################################################
# ATT: this assume that all references to engage are already https cloudfront
mh_search_cloudfront_statement="UPDATE mh_search SET mediapackage_xml = REPLACE( mediapackage_xml, 'https://${SOURCE_CLOUDFRONT_DOMAIN}', 'https://${TARGET_CLOUDFRONT_DOMAIN}') WHERE mediapackage_xml like '%https://${SOURCE_CLOUDFRONT_DOMAIN}%';"

mh_search_wowza_edge_url_statement="UPDATE mh_search SET mediapackage_xml = REPLACE( mediapackage_xml, '${SOURCE_WOWZA_EDGE_URL}', '${TARGET_WOWZA_EDGE_URL}') WHERE mediapackage_xml like '%${SOURCE_WOWZA_EDGE_URL}%';"

mh_service_registration_deactivate_statement="UPDATE mh_service_registration SET active = 0;"
mh_service_registration_offline_statement="UPDATE mh_service_registration SET online = 0;"
mh_host_registration_deactivate_statement="UPDATE mh_host_registration SET active = 0;"
mh_host_registration_offline_statement="UPDATE mh_host_registration SET online = 0;"
mh_host_registration_maintenance_statement="UPDATE mh_host_registration SET maintenance = 1;"

for statement in "${mh_episode_engage_ip_http_statement}" "${mh_episode_engage_ip_https_statement}" "${mh_episode_engage_host_http_statement}" "${mh_episode_engage_host_https_statement}" "${mh_job_admin_ip_statement}" "${mh_job_engage_ip_http_statement}" "${mh_job_engage_ip_https_statement}" "${mh_job_engage_host_http_statement}" "${mh_job_engage_host_https_statement}" "${mh_search_cloudfront_statement}" "${mh_search_wowza_edge_url_statement}" "${mh_service_registration_deactivate_statement}" "${mh_host_registration_deactivate_statement}" "${mh_service_registration_offline_statement}" "${mh_host_registration_offline_statement}" "${mh_host_registration_maintenance_statement}"
do
    echo "EXECUTING STATEMENT: ${statement}"
    echo
    mysql -u ${MYSQL_MH_USER} -p${MYSQL_MH_PASSWD} -e "${statement}" matterhorn
    echo
done


