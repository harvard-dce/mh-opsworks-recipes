# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-ca-webapp-nginx-proxy

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
ca_webapp_info = node.fetch(:ca_webapp, {})
app_name = ca_webapp_info.fetch(:ca_webapp_name, "webapp")

install_package("nginx")

install_nginx_logrotate_customizations

ssl_info = node.fetch(:ssl, get_dummy_cert)
if cert_defined(ssl_info)
  create_ssl_cert(ssl_info)
  certificate_exists = true
end

template %Q|/etc/nginx/sites-enabled/default| do
  source "ca-webapp-nginx-proxy-conf.erb"
  manage_symlink_source true
  variables({
    ca_webapp: app_name
  })
end

execute "service nginx reload"
