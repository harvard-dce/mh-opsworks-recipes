#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
opencast_port="$2"
metric_name="OpencastAvailable"
test_string="j_username"
value=0

# http will get redirected to https here so use -k to ignore issues
# related to the ssl certificate not being valid for "localhost"
if $(/usr/bin/curl -k -s -L http://localhost/ | grep -q "$test_string"); then
  value=1
fi

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value"
