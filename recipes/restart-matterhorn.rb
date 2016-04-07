# Cookbook Name:: mh-opsworks-recipes
# Recipe:: restart-matterhorn

service 'matterhorn' do
  action :restart
  supports restart: true, start: true, stop: true, status: true
  only_if '[ -f /etc/init.d/matterhorn ]'
end
