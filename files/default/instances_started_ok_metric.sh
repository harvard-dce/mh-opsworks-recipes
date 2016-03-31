#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

stack_id="$1"
metric_name="InstancesStartedOK"
value=0

output=$(aws opsworks describe-instances --region="$region" --stack-id="$stack_id" --output=text --query='Instances[?Status==`connection_lost`]||Instances[?Status==`setup_failed`]||Instances[?Status==`start_failed`]')

if [ "$output" = '' ]; then
  # No problems
  value=1
else
  # Bad things happening
  value=0
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="StackId=$stack_id" --metric-name="$metric_name" --value="$value"
