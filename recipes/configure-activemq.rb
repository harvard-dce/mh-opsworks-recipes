# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-activemq

activemq_bind_host = node[:opsworks][:instance][:private_dns_name] 
activemq_version = node.default['activemq']['version']
activemq_config = %Q|/opt/apache-activemq-#{activemq_version}/conf/activemq.xml|

service 'activemq' do
    action :nothing
end

template activemq_config do
  source 'activemq.xml.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables({
      activemq_bind_host: activemq_bind_host
  })
  notifies :restart, 'service[activemq]' if node['activemq']['enabled']
end

