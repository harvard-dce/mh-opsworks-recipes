# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-engage-nginx-proxy

include_recipe "oc-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('nginx')

install_nginx_logrotate_customizations

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

shared_storage_root = get_shared_storage_root

ssl_info = node.fetch(:ssl, get_dummy_cert)
if cert_defined(ssl_info)
  create_ssl_cert(ssl_info)
  certificate_exists = true
end

worker_procs = get_nginx_worker_procs

template %Q|/etc/nginx/nginx.conf| do
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template %Q|/etc/nginx/sites-enabled/default| do
  source 'engage-nginx-proxy-conf.erb'
  manage_symlink_source true
  variables({
    shared_storage_root: shared_storage_root,
    opencast_backend_http_port: 8080,
    certificate_exists: certificate_exists
  })
end

execute 'service nginx reload'
