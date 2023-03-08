# Cookbook Name:: oc-opsworks-recipes
# Recipe:: monitor-opencast-daemon

::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

if on_aws?
  include_recipe 'oc-opsworks-recipes::create-metrics-dependencies'
  aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
  opencast_backend_port = 8080

  cookbook_file 'opencast_available.sh' do
    path '/usr/local/bin/opencast_available.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  cron_d 'opencast_available' do
    user 'custom_metrics'
    minute '*/2'
    # Redirect stderr and stdout to logger. The command is silent on succesful runs
    command %Q(/usr/local/bin/opencast_available.sh "#{aws_instance_id}" "#{opencast_backend_port}" 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  ruby_block "add opencast monitoring" do
    block do
      aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
      region = 'us-east-1'
      # This is idempotent according to the aws docs
      create_topic_cmd = %Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)
      topic_arn = execute_command(create_topic_cmd).chomp

      command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{alarm_name_prefix}_opencast_availability" --alarm-description "Opencast is unavailable #{alarm_name_prefix}" --metric-name OpencastAvailable --namespace AWS/OpsworksCustom --statistic Minimum --period 120 --threshold 1 --comparison-operator LessThanThreshold --dimensions Name=InstanceId,Value=#{aws_instance_id} --evaluation-periods 4 --alarm-actions "#{topic_arn}")
      Chef::Log.info command
      execute_command(command)
    end
  end
end
