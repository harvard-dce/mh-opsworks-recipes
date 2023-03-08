# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-activemq

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

# for getting available ram to determine max_memory value
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)

activemq_bind_host = node[:opsworks][:instance][:private_dns_name]
activemq_version = node.default['activemq']['version']
activemq_base = %Q|#{node['activemq']['home']}/apache-activemq-#{activemq_version}|
activemq_wrapper_conf = %Q|#{activemq_base}/bin/linux/wrapper.conf|

cookbook_file 'activemq-log4j.properties' do
  path %Q|#{activemq_base}/conf/log4j.properties|
  owner "root"
  group "root"
  mode "644"
end

increase_max_memory = total_ram_in_meg > 16000

# for bigger instances (i.e. prod clusters) bump the max memory to 2G
ruby_block "max_memory" do
  block do
    sed = Chef::Util::FileEdit.new(activemq_wrapper_conf)
    sed.search_file_replace(/^(wrapper\.java\.maxmemory)=\d+/, '\1=4096')
    sed.write_file
  end
  only_if { increase_max_memory }
end

template 'activemq_service' do
  path '/etc/systemd/system/activemq.service'
  source 'activemq.service.erb'
  mode '644'
  owner 'root'
  group 'root'
  variables({
    activemq_base: activemq_base
  })
end

template 'activemq_config' do
  path %Q|#{activemq_base}/conf/activemq.xml|
  source 'activemq.xml.erb'
  mode '0755'
  owner 'root'
  group 'root'
  variables({
      activemq_bind_host: activemq_bind_host
  })
end

service 'activemq' do
  action [:enable, :start]
  supports start: true, stop: true, status: true, restart: true
  subscribes :restart, "template[activemq_config]", :immediately
  subscribes :restart, "ruby_block[max_memory]", :immediately
  provider Chef::Provider::Service::Systemd
end

# symlink the wrapper's correct pidfile location into /var/run
# the 3rd-party cookbook we use gets this location wrong
link '/var/run/activemq.pid' do
  to "#{activemq_base}/data/activemq.pid"
  not_if 'test -f /var/run/activemq.pid'
end

activemq_log = "#{activemq_base}/data/activemq.log"
