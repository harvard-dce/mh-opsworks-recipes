# Cookbook Name:: oc-opsworks-recipes
# Recipe:: restart-opencast

service 'opencast' do
  action :restart
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/opencast ]'
end
