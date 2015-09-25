# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ec2-scaling-manager

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

manager_release = node.fetch(:ec2_management_release, 'v2.3.2')
rest_auth_info = get_rest_auth_info
stack_name = node[:opsworks][:stack][:name]
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
  repository "https://github.com/harvard-dce/ec2-management.git"
  revision manager_release
  destination '/home/ec2_manager/ec2-management'
  user 'ec2_manager'
end

file '/home/ec2_manager/ec2-management/.env' do
  owner 'ec2_manager'
  group 'ec2_manager'
  content %Q|
MATTERHORN_ADMIN_SERVER_USER="#{rest_auth_info[:user]}"
MATTERHORN_ADMIN_SERVER_PASS="#{rest_auth_info[:pass]}"
#{loggly_config}
EC2M_WAIT_RETRIES=20
EC2M_WAIT_TIME=30
|
  mode '600'
end

bash 'install dependencies' do
  code 'cd /home/ec2_manager/ec2-management && pip install -r requirements.txt'
  user 'root'
end

cron_d 'ec2_manager' do
  user 'ec2_manager'
  minute '*/2'
  command %Q(cd /home/ec2_manager/ec2-management && /usr/bin/run-one ./ec2_manager.py --opsworks "#{stack_name}" autoscale 2>&1 | logger -t info)
  path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
end
