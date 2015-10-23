# Cookbook Name:: mh-opsworks-recipes
# Recipe:: start-matterhorn

execute 'start matterhorn' do
  command 'service matterhorn start'
  only_if '[ -f /etc/init.d/matterhorn ]'
end
