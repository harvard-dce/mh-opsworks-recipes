# Cookbook Name:: oc-opsworks-recipes
# Recipe:: stop-opencast

service 'opencast' do
  action :stop
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/opencast ]'
end
