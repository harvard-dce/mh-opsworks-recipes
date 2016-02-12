# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-nginx-proxy

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = node.fetch(:capture_agent_manager, {})
app_name = capture_agent_manager_info.fetch(:capture_agent_manager_name, "capture_agent_manager")

install_package("nginx")

install_nginx_logrotate_customizations

ssl_info = node.fetch(:ca_ssl, get_dummy_cert)
if cert_defined(ssl_info)
  create_ssl_cert(ssl_info)
  certificate_exists = true
end

directory '/etc/nginx/proxy-includes' do
  owner 'root'
  group 'root'
end

template %Q|/etc/nginx/sites-enabled/default| do
  source "nginx-proxy-ssl-only.erb"
  manage_symlink_source true
end

template %Q|/etc/nginx/proxy-includes/capture-agent-manager.conf| do
  source "nginx-proxy-capture-agent-manager.conf.erb"
  variables({
    capture_agent_manager: app_name
  })
end

execute "service nginx reload"
