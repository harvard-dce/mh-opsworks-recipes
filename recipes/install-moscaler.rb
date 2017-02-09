# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-moscaler

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

install_package('python-pip run-one git python-dev libffi-dev')

moscaler_attributes = get_moscaler_info
Chef::Log.info moscaler_attributes

moscaler_release = moscaler_attributes['moscaler_release']

rest_auth_info = get_rest_auth_info
stack_name = node[:opsworks][:stack][:name]
region = "us-east-1"

loggly_info = node.fetch(:loggly, { token: '', url: '' })
loggly_config = if loggly_info[:token] != ''
                  %Q|LOGGLY_TOKEN=#{loggly_info[:token]}|
                else
                  ''
                end

user "moscaler" do
  comment 'The moscaler user'
  system true
  manage_home true
  home '/home/moscaler'
  shell '/bin/false'
end

git "get the moscaler software" do
  repository "https://github.com/harvard-dce/mo-scaler.git"
  revision moscaler_release
  destination '/home/moscaler/mo-scaler'
  user 'moscaler'
end

bash 'install dependencies' do
  code 'cd /home/moscaler/mo-scaler && pip install -r requirements.txt'
  user 'root'
end

execute "Clean out existing cron jobs" do
  command "find -name 'moscaler*' -delete"
  cwd "/etc/cron.d"
  action :run  
end

file '/home/moscaler/mo-scaler/autoscale.json' do
  owner 'moscaler'
  group 'moscaler'
  content Chef::JSONCompat.to_json_pretty({
      pause_cycles: moscaler_attributes['autoscale_pause_cycles'],
      up_increment: moscaler_attributes['autoscale_up_increment'],
      down_increment: moscaler_attributes['autoscale_down_increment'],
      strategies: moscaler_attributes['autoscale_strategies']
  })
end

file '/home/moscaler/mo-scaler/.env' do
  owner 'moscaler'
  group 'moscaler'
  content %Q|
MOSCALER_CLUSTER="#{stack_name}"
MATTERHORN_USER="#{rest_auth_info[:user]}"
MATTERHORN_PASS="#{rest_auth_info[:pass]}"
AWS_DEFAULT_REGION="#{region}"

MOSCALER_MIN_WORKERS=#{moscaler_attributes['min_workers']}
MOSCALER_IDLE_UPTIME_THRESHOLD=#{moscaler_attributes['idle_uptime_threshold']}
AUTOSCALE_CONFIG="/home/moscaler/mo-scaler/autoscale.json"
#{loggly_config}
|
  mode '600'
end

include_recipe "mh-opsworks-recipes::moscaler-resume"

