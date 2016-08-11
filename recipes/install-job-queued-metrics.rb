# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-job-queued-metrics

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

install_package('python-pip')

rest_auth_info = get_rest_auth_info
aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first

bash 'install pyhorn' do
  code 'pip install pyhorn==0.8.0'
  user 'root'
end

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
