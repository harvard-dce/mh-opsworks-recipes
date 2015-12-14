# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-mysql-alarms

include_recipe "awscli::default"
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block "fire alarms for MySQL RDS metrics" do
  block do
    region = 'us-east-1'
    topic_arn = %x(aws sns create-topic --name "#{topic_name}" --region #{region} --output text).chomp

    allocated_storage_in_gig = %x(aws rds describe-db-instances --db-instance-identifier "#{rds_name}" --region #{region} --output json | grep AllocatedStorage | sed "s/[^[:digit:]]//g").chomp.to_i

    min_percent_free_space = 0.25
    allocated_storage_in_bytes = allocated_storage_in_gig * (1024 * 1024 * 1024)
    min_available = (allocated_storage_in_bytes * min_percent_free_space).to_i

    # Available disk space
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_space_available" --alarm-description "MySQL RDS allocated storage free space" --metric-name FreeStorageSpace --namespace AWS/RDS --statistic Minimum --period 60 --threshold #{min_available} --comparison-operator LessThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 1 --alarm-actions "#{topic_arn}" --ok-actions "#{topic_arn}")
    Chef::Log.info command
    %x(#{command})

    # CPU utilization over the last 2 minutes
    upper_cpu_percent = 75
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_cpu_usage_high" --alarm-description "MySQL RDS cpu utilization is high" --metric-name CPUUtilization --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{upper_cpu_percent} --comparison-operator GreaterThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 2 --alarm-actions "#{topic_arn}" --ok-actions "#{topic_arn}")
    Chef::Log.info command
    %x(#{command})

    # Freeable RAM greater than 2 gig in bytes (a total guess)
    min_freeable_ram_in_bytes = 2 * 1024 * 1024 * 1024

    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_freeable_memory_low" --alarm-description "MySQL RDS freeable memory is low" --metric-name FreeableMemory --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{min_freeable_ram_in_bytes} --comparison-operator LessThanThreshold --dimensions Name=DBInstanceIdentifier,Value=#{rds_name} --evaluation-periods 2 --alarm-actions "#{topic_arn}" --ok-actions "#{topic_arn}")
    Chef::Log.info command
    %x(#{command})
  end
end
