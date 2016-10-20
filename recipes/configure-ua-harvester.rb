# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-ua-harvester

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

engage_node = search(:node, 'role:engage').first
admin_node = search(:node, 'role:admin').first

elk_info = get_elk_info
rest_auth_info = get_rest_auth_info
stack_name = stack_shortname
sqs_queue_name = "#{stack_name}-user-actions"
region = node[:opsworks][:instance][:region]
es_host = node[:opsworks][:instance][:private_ip]
max_start_end_span = elk_info.fetch('harvester_max_start_end_span', nil)
loggly_info = node.fetch(:loggly, { token: '', url: '' })
loggly_config = if loggly_info[:token] != ''
                  %Q|LOGGLY_TOKEN=#{loggly_info[:token]}|
                else
                  ''
                end

file '/home/ua_harvester/harvester/.env' do
  owner 'ua_harvester'
  group 'ua_harvester'
  content %Q|
AWS_DEFAULT_REGION="#{region}"
MATTERHORN_REST_USER="#{rest_auth_info[:user]}"
MATTERHORN_REST_PASS="#{rest_auth_info[:pass]}"
MATTERHORN_ENGAGE_HOST="#{engage_node[:private_ip]}"
MATTERHORN_ADMIN_HOST="#{admin_node[:private_ip]}"
ELASTICSEARCH_HOST="#{es_host}"
S3_HARVEST_TS_BUCKET="#{stack_name}-ua-harvester"
S3_LAST_ACTION_TS_KEY="#{stack_name}-last-action-ts"
SQS_QUEUE_NAME="#{sqs_queue_name}"
MAX_START_END_SPAN=#{max_start_end_span}
LOGGLY_TAGS="#{stack_name}"
#{loggly_config}
|
  mode '600'
end


