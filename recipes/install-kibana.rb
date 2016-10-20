# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
es_host = node[:opsworks][:instance][:private_ip]
kibana_major_version = elk_info['kibana_major_version']
kibana_repo_uri = elk_info['kibana_repo_uri']

apt_repository 'kibana' do
  uri kibana_repo_uri
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "mh-opsworks-recipes::update-package-repo"
pin_package("kibana", "#{kibana_major_version}.*")
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
