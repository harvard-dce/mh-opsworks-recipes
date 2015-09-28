#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
metric_name="RAIDArrayInSync"

if [ -e "/etc/mdadm/mdadm.conf" ]; then
  status=1
  for volume in $(cat /etc/mdadm/mdadm.conf  | grep ARRAY | cut -f 2 -d ' '); do
    if ! /sbin/mdadm --detail "$volume" -t > /dev/null; then
      # Detailed status of this volume returned a failure.
      status=0
    fi
  done
  aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$status"
fi
