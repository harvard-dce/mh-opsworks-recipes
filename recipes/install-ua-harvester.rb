# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-install-ua-harvester

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

engage_node = search(:node, 'role:engage').first

elk_info = get_elk_info

harvester_release = elk_info[:harvester_release]
rest_auth_info = get_rest_auth_info
stack_name = stack_shortname
sqs_queue_name = "#{stack_name}-user-actions"
region = node[:opsworks][:instance][:region]
loggly_info = node.fetch(:loggly, { token: '', url: '' })
loggly_config = if loggly_info[:token] != ''
                  %Q|LOGGLY_TOKEN=#{loggly_info[:token]}|
                else
                  ''
                end

install_package('python-pip')
install_package('run-one')

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

file '/home/ua_harvester/harvester/.env' do
  owner 'ua_harvester'
  group 'ua_harvester'
  content %Q|
AWS_DEFAULT_REGION="#{region}"
MATTERHORN_REST_USER="#{rest_auth_info[:user]}"
MATTERHORN_REST_PASS="#{rest_auth_info[:pass]}"
MATTERHORN_HOST="#{engage_node[:private_ip]}"
S3_LAST_ACTION_TS_BUCKET=mh-user-action-harvester
S3_LAST_ACTION_TS_KEY="#{stack_name}-last-action-ts"
SQS_QUEUE_NAME="#{sqs_queue_name}"
LOGGLY_TAGS="#{stack_name}"
#{loggly_config}
|
  mode '600'
end

bash 'install dependencies' do
  code 'cd /home/ua_harvester/harvester && pip install -r requirements.txt'
  user 'root'
end

# fetch user action data from MH every 2m
cron_d 'ua_harvester' do
  user 'ua_harvester'
  minute '*/2'
  command %Q(cd /home/ua_harvester/harvester && /usr/bin/run-one ./ua_harvest.py 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

ruby_block 'create sqs queue' do
  block do
    command = %Q(aws sqs create-queue --region "#{region}" --queue-name "#{sqs_queue_name}")
    Chef::Log.info command
    execute_command(command)
  end
end

