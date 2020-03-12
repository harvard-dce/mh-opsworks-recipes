# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-cwlogs

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

install_package("python-dev")

region = node[:opsworks][:instance][:region]
shared_assets_bucket = get_shared_asset_bucket_name

service 'awslogs' do
  action :nothing
end

# put the base config file where the setup script can use it
cookbook_file 'cwlogs base config' do
  path '/tmp/cwlogs.conf'
  source 'cwlogs.conf'
  owner 'root'
  group 'root'
  mode 0644
end

directory '/opt/aws/cloudwatch' do
  recursive true
end

remote_file '/opt/aws/cloudwatch/awslogs-agent-setup.py' do
  source %Q|https://s3.amazonaws.com/#{ shared_assets_bucket }/awslogs-agent-setup.py|
  mode '0755'
end

execute 'Upgrade to latest pip' do
  # upgrade pip, ensure virtualenv is installed & ignore errors about `six` compatibility
  command %Q|pip install --ignore-installed six -U pip virtualenv|
  retries 5
  retry_delay 15
  timeout 300
end

execute 'Install CloudWatch Logs agent' do
  command %Q|/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{region} -c /tmp/cwlogs.conf|
  retries 2
  retry_delay 15
  timeout 300
end

execute 'delete existing stream configs' do
  command %|find . -name "*.conf" -delete|
  cwd "/var/awslogs/etc/config"
  only_if { ::File.directory?("/var/awslogs/etc/config") }
end

# Just configure the core services here; let other recipes use `configure_cloudwatch_log` as they see fit
configure_cloudwatch_log("syslog", "/var/log/syslog", "%b %d %H:%M:%S")

if admin_node?
  configure_cloudwatch_log("mail", "/var/log/mail.log", "%b %d %H:%M:%S")
end

if utility_node?
  configure_cloudwatch_log("squid", "/var/log/squid3/access.log", "")
end

if mh_node?
  configure_cloudwatch_log("opencast", "#{ get_log_directory }/opencast.log", "%Y-%m-%d %H:%M:%S")
end

if engage_node? || admin_node?
  configure_nginx_cloudwatch_logs
end


