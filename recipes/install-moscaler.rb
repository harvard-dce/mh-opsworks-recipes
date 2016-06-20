# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-moscaler

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

install_package('python-pip run-one git')

moscaler_attributes = get_moscaler_info
Chef::Log.info moscaler_attributes

moscaler_release = moscaler_attributes['moscaler_release']
moscaler_strategy = moscaler_attributes['moscaler_strategy']
debug_flag = moscaler_attributes['moscaler_debug'] ? '-d' : ''
cron_interval = moscaler_attributes['cron_interval']

rest_auth_info = get_rest_auth_info
stack_name = node[:opsworks][:stack][:name]
autoscale_layer_id = node["opsworks"]["layers"]["workers"]["id"]
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

if moscaler_strategy == 'time'
  
  offpeak_instances = moscaler_attributes['offpeak_instances']
  peak_instances = moscaler_attributes['peak_instances']
  weekend_instances = moscaler_attributes['weekend_instances']

  # weekdays, offpeak, every five minutes from midnight - 7am + 11pm - midnight
  cron_d 'moscaler_offpeak' do
    user 'moscaler'
    hour '0-7,23'
    minute cron_interval
    weekday '1-5'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{offpeak_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  # weekdays, normal production window, every five minutes from 8am - 11pm
  cron_d 'moscaler_normal' do
    user 'moscaler'
    hour '8-22'
    minute cron_interval
    weekday '1-5'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{peak_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end

  # weekends, every five minutes
  cron_d 'moscaler_weekend' do
    user 'moscaler'
    minute cron_interval
    weekday '6,7'
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale to #{weekend_instances} --scale-available 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
elsif moscaler_strategy == 'auto'
  cron_d 'moscaler_auto' do
    user 'moscaler'
    minute cron_interval
    command %Q(cd /home/moscaler/mo-scaler && /usr/bin/run-one ./manager.py #{debug_flag} scale auto 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
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

AUTOSCALE_UP_INCREMENT=#{moscaler_attributes['autoscale_up_increment']}
AUTOSCALE_DOWN_INCREMENT=#{moscaler_attributes['autoscale_down_increment']}
AUTOSCALE_UP_THRESHOLD=#{moscaler_attributes['autoscale_up_threshold']}
AUTOSCALE_DOWN_THRESHOLD=#{moscaler_attributes['autoscale_down_threshold']}
AUTOSCALE_TYPE=#{moscaler_attributes['autoscale_type']}
AUTOSCALE_CLOUDWATCH_METRIC=#{moscaler_attributes['autoscale_cloudwatch_metric']}
AUTOSCALE_CLOUDWATCH_METRIC_LAYER_ID=#{autoscale_layer_id}
AUTOSCALE_UP_PAUSE_INTERVAL=#{moscaler_attributes['autoscale_up_pause_interval']}

#{loggly_config}
|
  mode '600'
end
