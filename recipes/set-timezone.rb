# Cookbook Name:: mh-opsworks-recipes
# Recipe:: set-timezone

timezone = node.fetch(:timezone, 'America/New_York')

# need to create a service stub to notify
service 'rsyslog' do
  action :nothing
  supports :restart => true
  provider Chef::Provider::Service::Upstart
end

execute 'set timezone' do
  command %Q|timedatectl set-timezone "#{timezone}"|
  retries 5
  retry_delay 5
  notifies :restart, "service[rsyslog]", :immediately
end
