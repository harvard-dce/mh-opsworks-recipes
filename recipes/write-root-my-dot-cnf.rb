# Cookbook Name:: mh-opsworks-recipes
# Recipe:: write-root-my-dot-cnf

db_info = node[:deploy][:matterhorn][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]

current_hostname = node['opsworks']['instance']['hostname']

template %Q|/root/.my.cnf| do
  source 'my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    host: host,
    username: username,
    password: password,
    port: port
  })
end
