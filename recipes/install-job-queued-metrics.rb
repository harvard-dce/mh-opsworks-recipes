# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-job-queued-metrics

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
python_pip "pyhorn" do
  version "0.4.1"
end

rest_auth_info = get_rest_auth_info
aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first

# This should probably be less than the number of jobs matterhorn assigns to a
# worker, or we could have some jobs that wait a while for a worker.
scale_up_limit = node.fetch(:scale_up_when_queued_jobs_gt, 3)

cookbook_file "queued_job_count.py" do
  path "/usr/local/bin/queued_job_count.py"
  owner "root"
  group "root"
  mode "755"
end

cookbook_file "queued_job_count_metric.sh" do
  path "/usr/local/bin/queued_job_count_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cron_d 'matterhorn_jobs_queued' do
  user 'custom_metrics'
  minute '*'
  command %Q(/usr/local/bin/queued_job_count_metric.sh "#{aws_instance_id}" "http://#{private_admin_hostname}/" "#{rest_auth_info[:user]}" "#{rest_auth_info[:pass]}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block "add up alarm for matterhorn job queued based scaling" do
  block do
    aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
    region = 'us-east-1'

    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{topic_name}_jobs_queued_high" --alarm-description "Many matterhorn jobs to process" --metric-name MatterhornJobsQueued --namespace AWS/OpsworksCustom --statistic Average --period 180 --threshold #{scale_up_limit} --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=#{aws_instance_id} --evaluation-periods 1 --no-actions-enabled)
    Chef::Log.info command
    execute_command(command)
  end
end
