# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-nginx-proxy

package 'nginx'

template %Q|/etc/nginx/sites-enabled/default| do
  source 'nginx-proxy.conf.erb'
  variables({
    matterhorn_backend_http_port: 8080
  })
end

directory '/etc/nginx/proxy-includes' do
  owner 'root'
  group 'root'
end

execute 'service nginx reload'
