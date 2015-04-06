# Cookbook Name:: mh-opsworks-recipes
# Recipe:: restart-matterhorn

service 'matterhorn' do
  action :restart
end
