# Cookbook Name:: oc-opsworks-recipes
# Recipe:: start-opencast

service 'opencast' do
  action :start
  supports start: true, stop: true, restart: false, status: true
  start_command   "/bin/systemctl start opencast"
  status_command  "/bin/systemctl status opencast"
  provider Chef::Provider::Service::Systemd
end
