# Cookbook Name:: oc-opsworks-recipes
# Recipe:: set-timezone

timezone = node.fetch(:timezone, 'America/New_York')

# need to create a service stub to notify
service 'rsyslog' do
  action :nothing
  supports :restart => true
end

# TODO: install chrony
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html#configure-amazon-time-service-amazon-linux
#execute 'set timezone' do
#  command %Q|timedatectl set-timezone "#{timezone}"|
#  retries 5
#  retry_delay 5
#  notifies :restart, "service[rsyslog]", :immediately
#end
