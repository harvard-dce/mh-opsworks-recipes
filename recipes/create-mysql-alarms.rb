# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-mysql-alarms

include_recipe "mh-opsworks-recipes::install-awscli"
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block "fire alarms for MySQL RDS metrics" do
  block do
    region = 'us-east-1'
    topic_arn = execute_command(%Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)).chomp

    allocated_storage_in_gig = execute_command(%Q(aws rds describe-db-instances --db-instance-identifier "#{rds_name}" --region #{region} --output text --query 'DBInstances[].AllocatedStorage')).chomp.to_i

    min_percent_free_space = 0.25
    allocated_storage_in_bytes = allocated_storage_in_gig * (1024 * 1024 * 1024)
    min_available = (allocated_storage_in_bytes * min_percent_free_space).to_i

    # Available disk space
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_space_available" --alarm-description "MySQL RDS allocated storage free space" --metric-name FreeStorageSpace --namespace AWS/RDS --statistic Minimum --period 60 --threshold #{min_available} --comparison-operator LessThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 1 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

    # CPU utilization over 80 for 10 1 minute periods
    upper_cpu_percent = 80
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_cpu_usage_high" --alarm-description "MySQL RDS cpu utilization is high" --metric-name CPUUtilization --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{upper_cpu_percent} --comparison-operator GreaterThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 10 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

    # Freeable RAM greater than 2 gig in bytes (a total guess)
    min_freeable_ram_in_bytes = 2 * 1024 * 1024 * 1024

    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_freeable_memory_low" --alarm-description "MySQL RDS freeable memory is low" --metric-name FreeableMemory --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{min_freeable_ram_in_bytes} --comparison-operator LessThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 2 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

    # an instance's baseline iops is determined by the size of the underlying ebs volume.
    # surpassing the baseline is fine for brief periods as the iops are "burstable", but
    # you don't want to go over for too long, so we'll alert if we go over 80% of the baseline
    baseline_iops = allocated_storage_in_gig * 3
    alert_on_write_iops_over = (baseline_iops * 0.80).to_i

    # Write operations over the threshold for 5 1 minute periods. This is rather coarse and reactionary, and
    # lots of writes can be seen as the database performing *well*, so take this one in context
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_write_iops_high" --alarm-description "MySQL RDS write iops are high" --metric-name WriteIOPS --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{alert_on_write_iops_over} --comparison-operator GreaterThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 5 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

    # Queue depth is over 2 for 10 1 minute periods. This means IO processes are stacking
    # up and EBS is getting swamped.
    disk_queue_depth_over = 2
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_queue_depth_high" --alarm-description "MySQL RDS EBS queue depth is high" --metric-name DiskQueueDepth --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{disk_queue_depth_over} --comparison-operator GreaterThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 10 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)
  end
end
