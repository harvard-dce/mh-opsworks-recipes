# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ua-harvester

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

harvester_release = elk_info['harvester_release']
harvester_repo = elk_info['harvester_repo']
stack_name = stack_shortname
sqs_queue_name = "#{stack_name}-user-actions"
region = node[:opsworks][:instance][:region]

install_package('python-pip python-virtualenv run-one redis-server')

user "ua_harvester" do
  comment 'The ua_harvester user'
  system true
  manage_home true
  home '/home/ua_harvester'
  shell '/bin/false'
end

git "get the ua harvester" do
  repository harvester_repo
  revision harvester_release
  destination '/home/ua_harvester/harvester'
  user 'ua_harvester'
end

bash 'install dependencies' do
  code %Q|
cd /home/ua_harvester/harvester &&
/usr/bin/virtualenv venv &&
source venv/bin/activate &&
sudo -H pip install --no-cache-dir -r requirements.txt
  |
  user 'ua_harvester'
end

include_recipe 'mh-opsworks-recipes::install-geolite2-db'
include_recipe 'mh-opsworks-recipes::configure-ua-harvester'

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

# fetch and index meeting and session data from the zoom api
cron_d 'zoom_harvest' do
  user 'ua_harvester'
  minute '0'
  hour '5'
  command %Q(cd /home/ua_harvester/harvester && source venv/bin/activate && /usr/bin/run-one ./harvest.py zoom 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block 'create sqs queue' do
  block do
    command = %Q(aws sqs create-queue --region "#{region}" --queue-name "#{sqs_queue_name}")
    Chef::Log.info command
    execute_command(command)
  end
end
