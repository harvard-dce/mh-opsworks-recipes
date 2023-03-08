# Cookbook Name:: oc-opsworks-recipes
# Recipe:: nfs-client

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe 'oc-opsworks-recipes::create-metrics-dependencies'

storage_info = get_storage_info

# Ensure nfs client requirements are installed
install_package('autofs')
include_recipe "nfs::client4"

export_root = storage_info[:export_root]
shared_storage_root = get_shared_storage_root

# If we've explictly defined an nfs server export root path different than
# the path we use everywhere else, use that for the export root.  This is
# primarily for efs, which exports a filesystem on the root path always.
nfs_server_export_root = storage_info[:nfs_server_export_root] || storage_info[:export_root]

storage_hostname = get_storage_hostname

directory '/etc/auto.master.d' do
  action :create
  owner 'root'
  group 'root'
  mode '755'
end

file '/etc/auto.opencast' do
  action :create
  owner 'root'
  group 'root'
  mode '640'
  content %Q|#{export_root} -fstype=nfs4 #{storage_hostname}:#{nfs_server_export_root}\n|
end

file '/etc/auto.master.d/opencast.autofs' do
  action :create
  owner 'root'
  group 'root'
  mode '640'
  content "/- /etc/auto.opencast -t 3600 -n 1"
end

# Only restart if we don't have an active mount
service 'autofs' do
  action :restart
  not_if %Q|grep '#{storage_hostname}:#{nfs_server_export_root} ' /proc/mounts|
  provider Chef::Provider::Service::Systemd
end

execute 'warm directory' do
  command %Q|ls -flai #{export_root}/|
  retries 10
  retry_delay 5
end

directory shared_storage_root do
  owner 'opencast'
  group 'opencast'
  mode '755'
  recursive true
end

if on_aws?
  heartbeat_root_dir = shared_storage_root + "/.storage_heartbeat"
  aws_instance_id = node[:opsworks][:instance][:aws_instance_id]

  cookbook_file 'nfs_available.sh' do
    path '/usr/local/bin/nfs_available.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  directory heartbeat_root_dir do
    owner 'custom_metrics'
    group 'custom_metrics'
    mode '700'
    recursive true
  end

  cron_d 'nfs_available' do
    user 'custom_metrics'
    minute '*'
    # Redirect stderr and stdout to logger. The command is silent on succesful runs
    command %Q(/usr/local/bin/nfs_available.sh "#{aws_instance_id}" "#{heartbeat_root_dir}" 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  ruby_block "add nfs availability check" do
    block do
      region = 'us-east-1'
      # This is idempotent according to the aws docs
      topic_arn = execute_command(%Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)).chomp

      command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{alarm_name_prefix}_nfs_availability" --alarm-description "NFS is unavailable #{alarm_name_prefix}" --metric-name NFSAvailable --namespace AWS/OpsworksCustom --statistic Minimum --period 60 --threshold 1 --comparison-operator LessThanThreshold --dimensions Name=InstanceId,Value=#{aws_instance_id} --evaluation-periods 2 --alarm-actions "#{topic_arn}")
      Chef::Log.info command
      execute_command(command)
    end
  end
end
