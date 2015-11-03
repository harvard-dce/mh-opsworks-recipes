#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
metric_name="Load5"
value=$(cat /proc/loadavg | cut -d' ' -f 2)

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value"
