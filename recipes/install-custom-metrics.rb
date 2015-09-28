# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-custom-metrics

include_recipe "awscli::default"

opsworks_instance_id = node[:opsworks][:instance][:id]

user "custom_metrics" do
  comment 'The custom metrics reporting user'
  system true
  shell '/bin/false'
end

cookbook_file "custom_metrics_shared.sh" do
  path "/usr/local/bin/custom_metrics_shared.sh"
  owner "root"
  group "root"
  mode "755"
end

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

cron_d 'disk_metrics' do
  user 'custom_metrics'
  minute '*/2'
  # Redirect stderr and stdout to logger. The command is silent on succesful runs
  command %Q(/usr/local/bin/disk_free_metric.sh "#{opsworks_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d 'raid_metrics' do
  user 'root'
  minute '*/2'
  command %Q(/usr/local/bin/raid_metric.sh "#{opsworks_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  only_if { ::File.exists?('/etc/mdadm/mdadm.conf') }
end
