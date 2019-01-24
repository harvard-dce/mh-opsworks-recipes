# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-mysql-alarms

include_recipe "oc-opsworks-recipes::install-awscli"
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block "fire alarms for MySQL RDS metrics" do
  block do
    region = 'us-east-1'
    topic_arn = execute_command(%Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)).chomp

    # CPU utilization over 80 for 10 1 minute periods
    upper_cpu_percent = 80
    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_database_cpu_usage_high" --alarm-description "MySQL RDS cpu utilization is high" --metric-name CPUUtilization --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{upper_cpu_percent} --comparison-operator GreaterThanThreshold --dimensions Name=DBClusterIdentifier,Value=#{rds_name} --evaluation-periods 10 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

    # Freeable RAM greater than 2 gig in bytes (a total guess)
    min_freeable_ram_in_bytes = 2 * 1024 * 1024 * 1024

    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{rds_name}_database_freeable_memory_low" --alarm-description "MySQL RDS freeable memory is low" --metric-name FreeableMemory --namespace AWS/RDS --statistic Maximum --period 60 --threshold #{min_freeable_ram_in_bytes} --comparison-operator LessThanThreshold --dimensions Name=DBClusterIdentifier,Value=#{rds_name} --evaluation-periods 2 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)

  end
end
