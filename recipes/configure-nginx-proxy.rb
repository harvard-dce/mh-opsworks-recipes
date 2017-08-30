# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::install-nginx"

install_nginx_logrotate_customizations

worker_procs = get_nginx_worker_procs

service 'nginx' do
  action :nothing
end

# The template path variable cannot be a get, must be saved locally first
body_temp_path = get_nginx_body_temp_path

# create path for nginx to buffer large uploads, the get can be called directly
directory get_nginx_body_temp_path do
  action :create
  owner 'www-data'
  group 'admin'
  mode '755'
  recursive true
end

directory '/etc/nginx/proxy-includes' do
  owner 'root'
  group 'root'
end

template %Q|/etc/nginx/nginx.conf| do
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template %Q|/etc/nginx/conf.d/default.conf| do
  source 'nginx-proxy.conf.erb'
  variables({
    opencast_backend_http_port: 8080,
    body_temp_path: body_temp_path
  })
  notifies :restart, 'service[nginx]', :immediately
end

