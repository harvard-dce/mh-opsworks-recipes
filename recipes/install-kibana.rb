# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
es_host = node[:opsworks][:instance][:private_ip]

apt_repository 'kibana' do
  uri 'https://packages.elastic.co/kibana/4.6/debian'
  components ['stable', 'main']
  key 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
end

include_recipe "oc-opsworks-recipes::update-package-repo"
install_package("kibana")

service 'kibana' do
  action :enable
  supports :restart => true
end

template '/opt/kibana/config/kibana.yml' do
  source 'kibana.yml.erb'
  user 'kibana'
  group 'kibana'
  mode '644'
  variables({
    elasticsearch_host: es_host
  })
  notifies :restart, 'service[kibana]', :immediately
end
