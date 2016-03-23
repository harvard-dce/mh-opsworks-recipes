# Cookbook Name:: mh-opsworks-recipes
# Recipe:: stop-matterhorn

execute 'stop matterhorn' do
  command 'service matterhorn stop'
  only_if '[ -f /etc/init.d/matterhorn ]'
end
