# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-nginx-config-for-ganglia

(private_ganglia_hostname, ganglia_attributes) = node[:opsworks][:layers]['monitoring-master'][:instances].first

config_location = %Q|/etc/nginx/proxy-includes/ganglia.conf|

if ganglia_attributes

  directory '/etc/nginx/proxy-includes' do
    owner 'root'
    group 'root'
  end

  template config_location do
    source 'nginx-ganglia-proxy.conf.erb'
    variables({
      ganglia_host: ganglia_attributes[:private_ip]
    })
  end
else
  file config_location do
    action :delete
  end
end

execute 'service nginx reload'
