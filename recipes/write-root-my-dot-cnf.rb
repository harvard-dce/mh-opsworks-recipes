# Cookbook Name:: oc-opsworks-recipes
# Recipe:: write-root-my-dot-cnf

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

is_db_node = database_node?
db_info = node[:deploy][:opencast][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]


template %Q|/root/.my.cnf| do
  source 'my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    host: host,
    username: username,
    password: password,
    is_db_node: is_db_node,
    port: port
  })
end
