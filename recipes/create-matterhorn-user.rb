# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-matterhorn-user

group 'matterhorn' do
  append true
  gid 2122
end

user 'matterhorn' do
  supports manage_home: false
  comment 'Matterhorn application user'
  uid 2122
  gid 'matterhorn'
  home '/opt/matterhorn'
  shell '/bin/false'
end
