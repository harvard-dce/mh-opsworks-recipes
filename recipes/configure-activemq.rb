# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-activemq

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

activemq_bind_host = node[:opsworks][:instance][:private_dns_name]
activemq_version = node.default['activemq']['version']
activemq_config = %Q|/opt/apache-activemq-#{activemq_version}/conf/activemq.xml|

template 'activemq_config' do
  path activemq_config
  source 'activemq.xml.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables({
      activemq_bind_host: activemq_bind_host
  })
end

service 'activemq' do
  supports start: true, stop: true, restart: true, status: true
  action [:enable, :start]
  subscribes :restart, "template[activemq_config]", :immediately
end

