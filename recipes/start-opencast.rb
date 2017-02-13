# Cookbook Name:: oc-opsworks-recipes
# Recipe:: start-opencast

service 'opencast' do
  action :start
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/opencast ]'
end
