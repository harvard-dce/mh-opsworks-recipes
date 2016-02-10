#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
filesystem_type="$2"
metric_name=""

local_file_systems=$(mount | grep -E "$filesystem_type" | cut -f3 -d' ')

for partition_mount in $local_file_systems; do
  if [ $partition_mount = '/' ]; then
    metric_name="SpaceFreeOnRootPartition"
  else
    metric_suffix=$(echo -n "$partition_mount" | tr -c "[[:alnum:]]" "_")
    metric_name="SpaceFreeOn$metric_suffix"
  fi
  percent_free=$(expr 100 - $(df -hP "$partition_mount" | tail -1 | awk '{ print $5 }' | tr -d '/%//'))
  aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$percent_free" --unit Percent
done
