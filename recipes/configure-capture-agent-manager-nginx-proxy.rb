# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-capture-agent-manager-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name

include_recipe "oc-opsworks-recipes::install-nginx"

install_nginx_logrotate_customizations
configure_nginx_cloudwatch_logs

ssl_info = node.fetch(:ca_ssl, get_dummy_cert)
if cert_defined(ssl_info)
  create_ssl_cert(ssl_info)
end

directory "/etc/nginx/proxy-includes" do
  owner "root"
  group "root"
end

worker_procs = get_nginx_worker_procs

service 'nginx' do
  action :nothing
end

template %Q|/etc/nginx/nginx.conf| do
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template "/etc/nginx/conf.d/default.conf" do
  source "nginx-proxy-ssl-only.erb"
end

template "/etc/nginx/proxy-includes/capture-agent-manager.conf" do
  source "nginx-proxy-capture-agent-manager.conf.erb"
  variables({
    capture_agent_manager: app_name,
    capture_agent_manager_usr_name: usr_name
  })
  notifies :restart, 'service[nginx]', :immediately
end

