# Cookbook Name:: mh-opsworks-recipes
# Recipe:: stop-matterhorn

service 'matterhorn' do
  action :stop
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/matterhorn ]'
end
