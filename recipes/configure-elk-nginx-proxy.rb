# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-elk-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

es_node = search(:node, 'role:elasticsearch').first

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package('nginx')
install_package('apache2-utils')

install_nginx_logrotate_customizations

elk_info = get_elk_info
http_auth = elk_info[:http_auth]
certificate_exists = create_ssl_cert(elk_info[:http_ssl])

template %Q|/etc/nginx/sites-enabled/default| do
  source 'elk-nginx-proxy-conf.erb'
  manage_symlink_source true
  owner 'root'
  group 'root'
  mode '644'
  variables({
    certificate_exists: certificate_exists,
    elasticsearch_host: es_node[:private_ip]
  })
end

bash "htpasswd" do
  code <<-EOH
    htpasswd -bc /etc/nginx/conf.d/kibana.htpasswd #{http_auth[:user]} #{http_auth[:pass]}
  EOH
end

execute 'service nginx reload'

