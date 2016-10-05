#!/bin/bash

. /usr/local/bin/custom_metrics_shared.sh

instance_id="$1"
app_name="$2"
namespace="Java/$app_name"

proc_id=`jps | grep $app_name | cut -d ' ' -f 1`
data=`jstat -gcutil $proc_id | tail -1 | tr -s ' ' | cut -c2-100`

echo $data | while read survivor0 survivor1 eden oldgen perm younggc younggctime fullgc fullgctime totalgctime
do
    aws cloudwatch put-metric-data --metric-name="Survivor0Usage" --value="$survivor0" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="Survivor1Usage" --value="$survivor1" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="EdenUsage" --value="$eden" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="OldGenUsage" --value="$oldgen" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="PermUsage" --value="$perm" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="YoungGCCount" --value="$younggc" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="YoungGCTime" --value="$younggctime" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Seconds --region="$region"
    aws cloudwatch put-metric-data --metric-name="FullGCCount" --value="$fullgc" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Percent --region="$region"
    aws cloudwatch put-metric-data --metric-name="FullGCTime" --value="$fullgctime" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Seconds --region="$region"
    aws cloudwatch put-metric-data --metric-name="TotalGCTime" --value="$totalgctime" --namespace="$namespace" --dimensions="InstanceId=$instance_id" --unit Seconds --region="$region"
done
