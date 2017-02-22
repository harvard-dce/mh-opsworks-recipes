# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-activemq

activemq_bind_host = node.fetch(:activemq_bind_host, '0.0.0.0')
activemq_version = node.default['activemq']['version']
activemq_config = %Q|/opt/apache-activemq-#{activemq_version}/conf/activemq.xml|

template activemq_config do
  source 'activemq.xml.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables({
      bind_host: activemq_bind_host
  })
  notifies :restart, 'service[activemq]' if node['activemq']['enabled']
end
