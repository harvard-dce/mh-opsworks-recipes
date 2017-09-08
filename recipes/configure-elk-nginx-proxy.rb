# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-elk-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
http_auth = elk_info['http_auth']
es_host = node[:opsworks][:instance][:private_ip]

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package('nginx apache2-utils')

install_nginx_logrotate_customizations
configure_nginx_cloudwatch_logs

create_ssl_cert(elk_info['http_ssl'])

service 'nginx' do
  action :nothing
end

bash "htpasswd" do
  code <<-EOH
    htpasswd -bc /etc/nginx/conf.d/kibana.htpasswd #{http_auth['user']} #{http_auth['pass']}
  EOH
end

worker_procs = get_nginx_worker_procs

template %Q|/etc/nginx/nginx.conf| do
  source 'nginx.conf.erb'
  variables({
    worker_procs: worker_procs
  })
end

template %Q|/etc/nginx/sites-enabled/default| do
  source 'elk-nginx-proxy-conf.erb'
  manage_symlink_source true
  owner 'root'
  group 'root'
  mode '644'
  variables({
    elasticsearch_host: es_host
  })
  notifies :restart, 'service[nginx]', :immediately
end
