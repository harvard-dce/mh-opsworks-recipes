# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-admin-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::install-nginx"

public_admin_hostname = get_public_admin_hostname

# allow for admin and engage nodes to have their own, distinct, ssl sertificates
# e.g. production cluster
ssl_info = node.fetch(:ssl, get_dummy_cert)
ssl_admin_info = node.fetch(:ssl_admin, '')
if !ssl_admin_info.empty?
  create_ssl_cert(ssl_admin_info)
  certificate_exists = true
elsif cert_defined(ssl_info)
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
  source 'admin-nginx-proxy-conf.erb'
  manage_symlink_source true
  variables({
    opencast_backend_http_port: 8080,
    certificate_exists: certificate_exists,
    public_admin_hostname: public_admin_hostname
  })
end

cookbook_file 'nginx-status.conf' do
  path %Q|/etc/nginx/conf.d/status.conf|
  owner "root"
  group "root"
  mode "644"
end

service 'nginx' do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action [:enable, :start]
  subscribes :reload, "template[nginx]", :immediately
  subscribes :reload, "template[proxy]", :immediately
  # don't do these immediately as it will trigger a reload when the ssl key
  # is first written, which is prior to our config templates being generated
  # on initial node setup run
  subscribes :reload, "file[/etc/nginx/ssl/certificate.key]"
  subscribes :reload, "file[/etc/nginx/ssl/certificate.cert]"
end
