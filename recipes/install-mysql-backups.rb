# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mysql-backups

include_recipe "mh-opsworks-recipes::install-awscli"
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
storage_info = get_storage_info

mysql_dump_minute = node.fetch(:mysql_dump_minute, 2)
mysql_dump_hour = node.fetch(:mysql_dump_hour, 3)

export_root = storage_info[:export_root]

cookbook_file "mysql-backup.sh" do
  path "/usr/local/bin/mysql-backup.sh"
  owner "root"
  group "root"
  mode "700"
end

cookbook_file "custom_metrics_shared.sh" do
  path "/usr/local/bin/custom_metrics_shared.sh"
  owner "root"
  group "root"
  mode "755"
end

cron_d 'mysql_backup' do
  user 'root'
  minute mysql_dump_minute.to_i
  hour mysql_dump_hour.to_i
  command %Q(/usr/local/bin/mysql-backup.sh "#{export_root}/backups/mysql" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cookbook_file "mysql-backup-metric.sh" do
  path "/usr/local/bin/mysql-backup-metric.sh"
  owner "root"
  group "root"
  mode "700"
end

cron_d 'mysql_backup_metric' do
  user 'root'
  minute mysql_dump_minute.to_i
  hour mysql_dump_hour.to_i + 1
  command %Q(/usr/local/bin/mysql-backup-metric.sh "#{export_root}/backups/mysql" "#{aws_instance_id}" 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block "Fire alarm when the mysql database dump is not fresh" do
  block do
    aws_instance_id = node[:opsworks][:instance][:aws_instance_id]
    region = 'us-east-1'
    # This is idempotent according to the aws docs
    topic_arn = execute_command(%Q(aws sns create-topic --name "#{topic_name}" --region #{region} --output text)).chomp

    command = %Q(aws cloudwatch put-metric-alarm --region "#{region}" --alarm-name "#{alarm_name_prefix}_mysql_backup_freshness" --alarm-description "MySQL backups are fresh" --metric-name MySQLDatabaseBackupIsFresh --namespace AWS/OpsworksCustom --statistic Minimum --period 60 --threshold 1 --comparison-operator LessThanThreshold --dimensions Name=InstanceId,Value=#{aws_instance_id} --evaluation-periods 1 --alarm-actions "#{topic_arn}")
    Chef::Log.info command
    execute_command(command)
  end
end
