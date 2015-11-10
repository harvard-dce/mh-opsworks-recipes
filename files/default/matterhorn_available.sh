#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
matterhorn_port="$2"
metric_name="MatterhornAvailable"
test_string="j_username"
value=0
if $(/usr/bin/curl -s -L http://localhost/ | grep -q "$test_string"); then
  value=1
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value"
