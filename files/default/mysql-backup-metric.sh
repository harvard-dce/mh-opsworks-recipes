#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

backup_root_dir="$1"
instance_id="$2"

result=0

cd "$backup_root_dir"

metric_name="MySQLDatabaseBackupIsFresh"

if (find -type f -name 'mysql-matterhorn*.bz2' -mmin -90 | egrep '.*' > /dev/null) ; then
  # File is there and it's less than 70 minutes old
  result=1
else
  # File isn't there!
  result=0
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$result"
