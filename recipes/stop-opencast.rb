# Cookbook Name:: oc-opsworks-recipes
# Recipe:: stop-opencast

service 'opencast' do
  action :stop
  supports start: true, stop: true, restart: false, status: true
  stop_command    "/bin/systemctl stop opencast"
  status_command  "/bin/systemctl status opencast"
  provider Chef::Provider::Service::Systemd
end
