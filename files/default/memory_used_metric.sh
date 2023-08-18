#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
metric_name="MemoryUsed"
value=$(free | awk 'FNR == 3 {print $3/($3+$7)*100}')

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value" --unit Percent
