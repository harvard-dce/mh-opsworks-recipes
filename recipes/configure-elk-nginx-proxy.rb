# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-elk-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
http_auth = elk_info[:http_auth]
es_host = node['opsworks']['instance']['private_ip']

template %Q|/etc/nginx/sites-enabled/default| do
  source 'elk-nginx-proxy-conf.erb'
  manage_symlink_source true
  owner 'root'
  group 'root'
  mode '644'
  variables({
    elasticsearch_host: es_host
  })
end

bash "htpasswd" do
  code <<-EOH
    htpasswd -bc /etc/nginx/conf.d/kibana.htpasswd #{http_auth[:user]} #{http_auth[:pass]}
  EOH
end

execute 'service nginx reload'

