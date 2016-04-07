# Cookbook Name:: mh-opsworks-recipes
# Recipe:: start-matterhorn

service 'matterhorn' do
  action :start
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/matterhorn ]'
end
