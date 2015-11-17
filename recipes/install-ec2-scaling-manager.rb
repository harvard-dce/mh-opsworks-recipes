# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ec2-scaling-manager

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

manager_release = node.fetch(:ec2_management_release, 'v0.2.2')
rest_auth_info = get_rest_auth_info
stack_name = node[:opsworks][:stack][:name]
region = "us-east-1"
loggly_info = node.fetch(:loggly, { token: '', url: '' })
loggly_config = if loggly_info[:token] != ''
                  %Q|LOGGLY_TOKEN=#{loggly_info[:token]}|
                else
                  ''
                end

install_package('python-pip')
install_package('run-one')

user "ec2_manager" do
  comment 'The ec2_manager user'
  system true
  manage_home true
  home '/home/ec2_manager'
  shell '/bin/false'
end

git "get the ec2 manager" do
  repository "https://github.com/harvard-dce/mo-scaler.git"
  revision manager_release
  destination '/home/ec2_manager/mo-scaler'
  user 'ec2_manager'
end

file '/home/ec2_manager/mo-scaler/.env' do
  owner 'ec2_manager'
  group 'ec2_manager'
  content %Q|
MOSCALER_CLUSTER="#{stack_name}"
MATTERHORN_USER="#{rest_auth_info[:user]}"
MATTERHORN_PASS="#{rest_auth_info[:pass]}"
AWS_DEFAULT_REGION="#{region}"
#{loggly_config}
|
  mode '600'
end

bash 'install dependencies' do
  code 'cd /home/ec2_manager/mo-scaler && pip install -r requirements.txt'
  user 'root'
end

# weekdays, offpeak, every five minutes from midnight - 7am + 11pm - midnight
cron_d 'moscaler_offpeak' do
  user 'ec2_manager'
  hour '0-7,23'
  minute '*/5'
  weekday '1-5'
  command %Q(cd /home/ec2_manager/mo-scaler && /usr/bin/run-one ./manager.py scale to 2 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

# weekdays, normal production window, every five minutes from 8am - 11pm
cron_d 'moscaler_normal' do
  user 'ec2_manager'
  hour '8-22'
  minute '*/5'
  weekday '1-5'
  command %Q(cd /home/ec2_manager/mo-scaler && /usr/bin/run-one ./manager.py scale to 5 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end

# weekends, every five minutes
cron_d 'moscaler_weekend' do
  user 'ec2_manager'
  minute '*/5'
  weekday '6,7'
  command %Q(cd /home/ec2_manager/mo-scaler && /usr/bin/run-one ./manager.py scale to 1 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end
