# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-web-user

group "web" do
  append true
  gid 2133
end

user "web" do
  supports manage_home: true
  comment "web application user"
  uid 2133
  gid "web"
  shell "/bin/false"
  home "/home/web"
end

directory "/home/web/.ssh" do
  owner "web"
  group "web"
  mode "700"
end
