# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-matterhorn-user

group 'matterhorn' do
  append true
  gid 2122
end

user 'matterhorn' do
  supports manage_home: true
  comment 'Matterhorn application user'
  uid 2122
  gid 'matterhorn'
  shell '/bin/false'
  home '/home/matterhorn'
end

directory '/home/matterhorn/.ssh' do
  owner 'matterhorn'
  group 'matterhorn'
  mode '700'
end
