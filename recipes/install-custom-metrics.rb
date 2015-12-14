# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-custom-metrics

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::create-metrics-dependencies"

aws_instance_id = node[:opsworks][:instance][:aws_instance_id]

cookbook_file "disk_free_metric.sh" do
  path "/usr/local/bin/disk_free_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cookbook_file "raid_metric.sh" do
  path "/usr/local/bin/raid_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cookbook_file "mysql_available_metric.sh" do
  path "/usr/local/bin/mysql_available_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cookbook_file "load_metric.sh" do
  path "/usr/local/bin/load_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cookbook_file "memory_used_metric.sh" do
  path "/usr/local/bin/memory_used_metric.sh"
  owner "root"
  group "root"
  mode "755"
end

cron_d 'disk_metrics' do
  user 'custom_metrics'
  minute '*/2'
  # Redirect stderr and stdout to logger. The command is silent on succesful runs
  command %Q(/usr/local/bin/disk_free_metric.sh "#{aws_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d 'load_metrics' do
  user 'custom_metrics'
  minute '*/2'
  # Redirect stderr and stdout to logger. The command is silent on succesful runs
  command %Q(/usr/local/bin/load_metric.sh "#{aws_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d 'memory_used_metrics' do
  user 'custom_metrics'
  minute '*/2'
  # Redirect stderr and stdout to logger. The command is silent on succesful runs
  command %Q(/usr/local/bin/memory_used_metric.sh "#{aws_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d 'raid_metrics' do
  user 'root'
  minute '*/2'
  command %Q(/usr/local/bin/raid_metric.sh "#{aws_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  only_if { ::File.exists?('/etc/mdadm/mdadm.conf') }
end

if admin_node?
  cron_d 'mysql_available_metrics' do
    user 'root'
    minute '*'
    command %Q(/usr/local/bin/mysql_available_metric.sh "#{aws_instance_id}" 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end
