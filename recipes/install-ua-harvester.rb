# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-ua-harvester

include_recipe "oc-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

harvester_release = elk_info['harvester_release']
stack_name = stack_shortname
sqs_queue_name = "#{stack_name}-user-actions"
region = node[:opsworks][:instance][:region]

install_package('python-pip run-one redis-server')

user "ua_harvester" do
  comment 'The ua_harvester user'
  system true
  manage_home true
  home '/home/ua_harvester'
  shell '/bin/false'
end

git "get the ua harvester" do
  repository "https://github.com/harvard-dce/mh-user-action-harvester.git"
  revision harvester_release
  destination '/home/ua_harvester/harvester'
  user 'ua_harvester'
end

bash 'install dependencies' do
  code 'cd /home/ua_harvester/harvester && pip install -r requirements.txt'
  user 'root'
end

include_recipe 'oc-opsworks-recipes::configure-ua-harvester'

# fetch user action data from MH every 2m
cron_d 'ua_harvester' do
  user 'ua_harvester'
  minute '*/2'
  command %Q(cd /home/ua_harvester/harvester && /usr/bin/run-one ./ua_harvest.py harvest -b 10000 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

cron_d 'load_episodes' do
  user 'ua_harvester'
  minute '0'
  hour '4'
  command %Q(cd /home/ua_harvester/harvester && /usr/bin/run-one ./ua_harvest.py load_episodes --created_from_days_ago 1 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block 'create sqs queue' do
  block do
    command = %Q(aws sqs create-queue --region "#{region}" --queue-name "#{sqs_queue_name}")
    Chef::Log.info command
    execute_command(command)
  end
end
