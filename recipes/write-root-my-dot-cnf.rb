# Cookbook Name:: oc-opsworks-recipes
# Recipe:: write-root-my-dot-cnf

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

is_db_node = database_node?
db_info = node[:deploy][:opencast][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]

# stack deployment config includes a read-only db endpoint value
# for use by certain mysql commands, e.g. mysqldump
# fall back to standard endpoint if not present in stack config
readonly_op_host = db_info[:readonly_op_host] || db_info[:host]

template %Q|/root/.my.cnf| do
  source 'my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
    host: host,
    readonly_op_host: readonly_op_host,
    username: username,
    password: password,
    is_db_node: is_db_node,
    port: port
  })
end
