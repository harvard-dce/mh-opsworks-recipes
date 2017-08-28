# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-nginx-proxy

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name
ca_info = get_capture_agent_manager_info
http_auth = ca_info[:http_auth]
api_path = ca_info[:api_path]

::Chef::Log.info(ca_info)
::Chef::Log.info(http_auth)

htpasswd_file = "/etc/nginx/conf.d/#{app_name}.htpasswd"

create_ssl_cert(ca_info[:http_ssl])

service 'nginx' do
  action :nothing
end

directory "/etc/nginx/proxy-includes" do
  owner "root"
  group "root"
end

unless http_auth.nil?
  bash "htpasswd" do
    code <<-EOH
      htpasswd -bc #{htpasswd_file} #{http_auth['user']} #{http_auth['pass']}
    EOH
    notifies :restart, 'service[nginx]', :delayed
  end
end

template "/etc/nginx/sites-enabled/default" do
  source "nginx-proxy-ssl-only.erb"
  owner 'root'
  group 'root'
  mode '644'
  manage_symlink_source true
  notifies :restart, 'service[nginx]', :delayed
end

template "/etc/nginx/proxy-includes/capture-agent-manager.conf" do
  source "nginx-proxy-capture-agent-manager.conf.erb"
  owner 'root'
  group 'root'
  mode '644'
  variables({
    capture_agent_manager: app_name,
    capture_agent_manager_usr_name: usr_name,
    htpasswd_file: http_auth.nil? ? nil : htpasswd_file,
    api_path: api_path
  })
  notifies :restart, 'service[nginx]', :delayed
end
