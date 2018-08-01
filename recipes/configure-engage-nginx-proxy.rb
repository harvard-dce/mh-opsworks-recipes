# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-engage-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::install-nginx"

install_nginx_logrotate_customizations

shared_storage_root = get_shared_storage_root

ssl_info = node.fetch(:ssl, get_dummy_cert)
if cert_defined(ssl_info)
  create_ssl_cert(ssl_info)
  certificate_exists = true
end

worker_procs = get_nginx_worker_procs

template 'nginx' do
  path %Q|/etc/nginx/nginx.conf|
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template 'proxy' do
  path %Q|/etc/nginx/conf.d/default.conf|
  source 'engage-nginx-proxy-conf.erb'
  manage_symlink_source true
  variables({
    shared_storage_root: shared_storage_root,
    opencast_backend_http_port: 8080,
    certificate_exists: certificate_exists
  })
end

service 'nginx' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [:enable, :start]
  subscribes :reload, "template[nginx]", :immediately
  subscribes :reload, "template[proxy]", :immediately
  # don't do this one immediately as it will trigger a reload when the ssl key
  # is first written, which is prior to our config templates being generated
  # on initial node setup run
  subscribes :reload, "file[/etc/nginx/ssl/certificate.key]"
end

