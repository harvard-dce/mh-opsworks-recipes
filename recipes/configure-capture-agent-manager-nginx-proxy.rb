# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-nginx-proxy

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name
ca_info = get_capture_agent_manager_info

create_ssl_cert(ca_info[:http_ssl])

service 'nginx' do
  action :nothing
end

directory "/etc/nginx/proxy-includes" do
  owner "root"
  group "root"
end

template "/etc/nginx/sites-enabled/default" do
  source "nginx-proxy-ssl-only.erb"
  owner 'root'
  group 'root'
  mode '644'
  manage_symlink_source true
end

template "/etc/nginx/proxy-includes/capture-agent-manager.conf" do
  source "nginx-proxy-capture-agent-manager.conf.erb"
  owner 'root'
  group 'root'
  mode '644'
  variables({
    capture_agent_manager: app_name,
    capture_agent_manager_usr_name: usr_name
  })
  notifies :restart, 'service[nginx]', :immediately
end
