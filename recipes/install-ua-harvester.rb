# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-ua-harvester

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-python"

elk_info = get_elk_info

harvester_release = elk_info['harvester_release']
harvester_repo = elk_info['harvester_repo']
harvester_home = "/home/ua_harvester"
harvester_dir = "#{harvester_home}/harvester"
stack_name = stack_shortname
sqs_queue_name = "#{stack_name}-user-actions"
region = node[:opsworks][:instance][:region]

install_package('redis')

user "ua_harvester" do
  comment 'The ua_harvester user'
  system true
  manage_home true
  home harvester_home
  shell '/bin/false'
end

git "get the ua harvester" do
  repository harvester_repo
  revision harvester_release
  destination harvester_dir
  user 'ua_harvester'
end

harvester_venv = "#{harvester_dir}/venv"
harvester_requirements = "#{harvester_dir}/requirements.txt"
create_virtualenv(harvester_venv, 'ua_harvester', harvester_requirements)

include_recipe 'oc-opsworks-recipes::install-geolite2-db'
include_recipe 'oc-opsworks-recipes::configure-ua-harvester'

bash 'put index templates' do
  code 'cd /home/ua_harvester/harvester && source venv/bin/activate && ./harvest.py setup load_index_templates 2>&1 | logger -t info'
  user 'ua_harvester'
end

# fetch user action data from MH every 2m
cron_d 'ua_harvester' do
  user 'ua_harvester'
  minute '*/2'
  command %Q(cd /home/ua_harvester/harvester && source venv/bin/activate && /usr/bin/run-one ./harvest.py useractions -b 10000 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

# fetch and index episodes referenced by useractions from the previous da
cron_d 'load_episodes' do
  user 'ua_harvester'
  minute '0'
  hour '4'
  command %Q(cd /home/ua_harvester/harvester && source venv/bin/activate && /usr/bin/run-one ./harvest.py load_episodes 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block 'create sqs queue' do
  block do
    command = %Q(aws sqs create-queue --region "#{region}" --queue-name "#{sqs_queue_name}")
    Chef::Log.info command
    execute_command(command)
  end
end

service "redis" do
  action [ :enable, :start ]
  provider Chef::Provider::Service::Systemd
end
