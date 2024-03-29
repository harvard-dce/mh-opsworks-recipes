# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-logstash

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

stack_name = stack_shortname
es_host = node[:opsworks][:instance][:private_ip]

yum_repository 'logstash' do
  description "logstash 2.4.x packages"
  baseurl "http://packages.elastic.co/logstash/2.4/centos"
  action :create
  gpgkey "http://packages.elastic.co/GPG-KEY-elasticsearch"
end

include_recipe "oc-opsworks-recipes::update-package-repo"
install_package("logstash")

service 'logstash' do
  action :enable
  supports :restart => true
  provider Chef::Provider::Service::Systemd
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
