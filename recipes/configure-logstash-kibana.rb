# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-logstash-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

(private_es_hostname, es_attributes) = node[:opsworks][:layers]['elasticsearch'][:instances].first

stack_name = stack_shortname
elk_info = get_elk_info

template '/etc/logstash/conf.d/logstash.conf' do
  source 'logstash.conf.erb'
  variables({
    tcp_port: elk_info[:logstash_tcp_port],
    sqs_queue_name: "#{stack_name}-user-actions",
    stdout_output: elk_info[:logstash_stdout_output],
    elasticsearch_index_prefix: elk_info[:es_index_prefix],
    elasticsearch_host: es_attributes[:private_ip]
  })
end

execute 'service logstash restart'

template '/opt/kibana/config/kibana.yml' do
  source 'kibana.yml.erb'
  variables({
    elasticsearch_host: es_attributes[:private_ip],
  })
end

execute 'service kibana restart'
  