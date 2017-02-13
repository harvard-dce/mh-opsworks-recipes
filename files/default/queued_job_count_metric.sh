#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
admin_hostname="$2"
username="$3"
password="$4"

metric_name="OpencastJobsQueued"

queued_jobs=$(/usr/local/bin/queued_job_count.py -u "$username" -p "$password" "$admin_hostname")

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --metric-name="$metric_name" --value="$queued_jobs"
