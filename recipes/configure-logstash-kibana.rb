# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-logstash-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe 'mh-opsworks-recipes::configure-elk-nginx-proxy'

stack_name = stack_shortname
elk_info = get_elk_info
es_host = node[:opsworks][:instance][:private_ip]

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
end

execute 'service logstash restart'

template '/opt/kibana/config/kibana.yml' do
  source 'kibana.yml.erb'
  user 'kibana'
  group 'kibana'
  mode '644'
  variables({
    elasticsearch_host: es_host
  })
end

execute 'service kibana restart'
