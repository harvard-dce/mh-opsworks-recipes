#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

stack_id="$1"
metric_name="online_workers"

online_workers=`aws opsworks describe-instances --region="$region" --stack-id="$stack_id" --query="Instances[?Status=='online' && starts_with(Hostname, 'workers')].InstanceId" --output=text | wc -w`

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="StackId=$stack_id" --metric-name="$metric_name" --value="$online_workers"

