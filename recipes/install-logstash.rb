# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-logstash

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

stack_name = stack_shortname
es_host = node[:opsworks][:instance][:private_ip]
logstash_major_version = elk_info['logstash_major_version']
logstash_repo_uri = elk_info['logstash_repo_uri']

apt_repository 'logstash' do
  uri logstash_repo_uri
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "oc-opsworks-recipes::update-package-repo"
pin_package("logstash", "#{logstash_major_version}.*")
install_package("logstash")

service 'logstash' do
  action :enable
  supports :restart => true
end

cookbook_file "/etc/default/logstash" do
  source "logstash-default"
  owner 'root'
  group 'root'
  mode '644'
end

template '/etc/logstash/conf.d/logstash.conf' do
  source 'logstash.conf.erb'
  user 'root'
  group 'root'
  mode '644'
  variables({
    tcp_port: elk_info['logstash_tcp_port'],
    sqs_queue_name: "#{stack_name}-user-actions",
    stdout_output: elk_info['logstash_stdout_output'],
    elasticsearch_index_prefix: elk_info['es_index_prefix'],
    elasticsearch_host: es_host
  })
  notifies :restart, 'service[logstash]', :immediately
end

