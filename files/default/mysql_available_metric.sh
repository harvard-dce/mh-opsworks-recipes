#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
metric_name="MySQLServerAvailable"
value=0

if mysql matterhorn -e 'select * from mh_organization order by id limit 1' &> /dev/null; then
  value=1
else
  value=0
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value"
