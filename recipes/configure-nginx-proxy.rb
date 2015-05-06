# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-nginx-proxy

package 'nginx'

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)
export_root_parts = storage_info[:export_root].split('/')

client_body_temp_path = (export_root_parts + [ 'nginx', 'client_body_temp' ]).join('/')

directory client_body_temp_path do
  owner 'www-data'
  group 'www-data'
  mode '755'
  recursive true
end

template %Q|/etc/nginx/sites-enabled/default| do
  source 'nginx-proxy.conf.erb'
  variables({
    matterhorn_backend_http_port: 8080,
    client_body_temp_path: client_body_temp_path
  })
end

directory '/etc/nginx/proxy-includes' do
  owner 'root'
  group 'root'
end

service 'nginx' do
  action [:enable, :restart]
end
