# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-opencast-user

group 'opencast' do
  append true
  gid 2122
end

user 'opencast' do
  supports manage_home: true
  comment 'Opencast application user'
  uid 2122
  gid 'opencast'
  shell '/bin/false'
  home '/home/opencast'
end

directory '/home/opencast/.ssh' do
  owner 'opencast'
  group 'opencast'
  mode '700'
end
