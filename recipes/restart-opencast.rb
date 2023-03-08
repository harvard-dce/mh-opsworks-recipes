# Cookbook Name:: oc-opsworks-recipes
# Recipe:: restart-opencast

service 'opencast' do
  action :restart
  supports start: true, stop: true, restart: true, status: true
  restart_command    "/bin/systemctl restart opencast"
  status_command  "/bin/systemctl status opencast"
  provider Chef::Provider::Service::Systemd
end
