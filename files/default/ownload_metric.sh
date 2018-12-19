#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
username="$2"
password="$3"

metric_name="OpencastJobLoad"
value=$(/usr/bin/curl -s --digest -u "${username}:${password}" -H "X-Requested-Auth: Digest" http://localhost/services/ownload)

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$value" --unit None
