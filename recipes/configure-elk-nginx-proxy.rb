# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-elk-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
http_auth = elk_info['http_auth']
es_host = node[:opsworks][:instance][:private_ip]

include_recipe "oc-opsworks-recipes::install-nginx"
install_package('httpd-tools')

install_nginx_logrotate_customizations

create_ssl_cert(elk_info['http_ssl'])

bash "htpasswd" do
  code <<-EOH
    htpasswd -bc /etc/nginx/conf.d/kibana.htpasswd #{http_auth['user']} #{http_auth['pass']}
  EOH
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
  source 'elk-nginx-proxy-conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    elasticsearch_host: es_host
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
