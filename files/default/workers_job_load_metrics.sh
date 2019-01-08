#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

stack_shortname="$1"
stack_id="$2"
workers_layer_id="$3"
admin_hostname="$4"
username="$5"
password="$6"

# get the private dns names of running worker instances for this stack
worker_hostnames=$(aws --region "$region" ec2 describe-instances --filters "Name=tag:opsworks:stack,Values=$stack_shortname" "Name=tag:opsworks:layer:workers,Values=Workers" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[PrivateDnsName]" --output text)

# this gets the percent usage of the total running worker capacity based on current load and max load
percent_used=$(/usr/local/bin/workers_job_load.py -a "$admin_hostname" --mode "percent_used" -u "$username" -p "$password" $worker_hostnames)

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="LayerId=$workers_layer_id" --metric-name="WorkersJobLoadPercentUsed" --value="$percent_used" --unit "Percent"

# this gets the max available job load capacity among the running workers
max_available=$(/usr/local/bin/workers_job_load.py -a "$admin_hostname" --mode "max_available" -u "$username" -p "$password" $worker_hostnames)

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="LayerId=$workers_layer_id" --metric-name="WorkersJobLoadMaxAavailable" --value="$max_available"

running_workflows=$(/usr/local/bin/workers_job_load.py -a "$admin_hostname" --mode "running_workflows" -u "$username" -p "$password")

aws cloudwatch put-metric-data --region="$region" --namespace="$namespace" --dimensions="StackId=$stack_id" --metric-name="RunningWorkflows" --value="$running_workflows" --unit "Count"

