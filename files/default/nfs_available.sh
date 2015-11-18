#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
root_heartbeat_directory="$2"
metric_name="NFSAvailable"
value=0

if echo $(/bin/date) > "$root_heartbeat_directory/$instance_id-nfs-heartbeat.txt"; then
  value=1
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value"
