# Cookbook Name:: mh-opsworks-recipes
# Recipe:: monitor-matterhorn-daemon

::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

if on_aws?
  include_recipe 'mh-opsworks-recipes::create-metrics-dependencies'
  aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
  matterhorn_backend_port = 8080

  cookbook_file 'matterhorn_available.sh' do
    path '/usr/local/bin/matterhorn_available.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  cron_d 'matterhorn_available' do
    user 'custom_metrics'
    minute '*/2'
    # Redirect stderr and stdout to logger. The command is silent on succesful runs
    command %Q(/usr/local/bin/matterhorn_available.sh "#{aws_instance_id}" "#{matterhorn_backend_port}" 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  ruby_block "add matterhorn monitoring" do
    block do
      aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
      region = 'us-east-1'
      # This is idempotent according to the aws docs
      topic_arn = execute_command(%Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)).chomp

      command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{alarm_name_prefix}_matterhorn_availability" --alarm-description "Matterhorn is unavailable #{alarm_name_prefix}" --metric-name MatterhornAvailable --namespace AWS/OpsworksCustom --statistic Minimum --period 120 --threshold 1 --comparison-operator LessThanThreshold --dimensions Name=InstanceId,Value=#{aws_instance_id} --evaluation-periods 4 --alarm-actions "#{topic_arn}")
      Chef::Log.info command
      execute_command(command)
    end
  end
end
