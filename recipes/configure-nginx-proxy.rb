# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::install-nginx"

worker_procs = get_nginx_worker_procs

directory '/etc/nginx/proxy-includes' do
  owner 'root'
  group 'root'
end

template 'nginx' do
  path %Q|/etc/nginx/nginx.conf|
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template 'proxy' do
  path %Q|/etc/nginx/conf.d/default.conf|
  source 'nginx-proxy.conf.erb'
  variables({
    opencast_backend_http_port: 8080
  })
  notifies :restart, 'service[nginx]', :immediately
end

cookbook_file 'nginx-status.conf' do
  path %Q|/etc/nginx/conf.d/status.conf|
  owner "root"
  group "root"
  mode "644"
end

service 'nginx' do
  supports :start => true, :stop => true, :reload => true
  action [:enable, :start]
  start_command   "/bin/systemctl start nginx"
  reload_command  "/bin/systemctl reload nginx"
  subscribes :reload, "template[nginx]", :immediately
  subscribes :reload, "template[proxy]", :immediately
  provider Chef::Provider::Service::Systemd
end
