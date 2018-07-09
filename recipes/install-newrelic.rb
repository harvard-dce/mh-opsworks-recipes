# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-newrelic

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

# to get the newrelic helpers which need to be available during the deploy
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)

layer_name = layer_name_from_hostname

return unless newrelic_config
return unless enable_newrelic_layer?(layer_name)

# config template values
license_key = newrelic_config[layer_name.to_s][:key]
environment_name = stack_shortname
node_name = stack_and_hostname
log_dir = get_log_directory

# installation variables
agent_version = get_newrelic_agent_version
shared_asset_bucket_name = get_shared_asset_bucket_name
agent_url = "https://s3.amazonaws.com/#{shared_asset_bucket_name}/newrelic-#{agent_version}.jar"
install_path = "/opt/newrelic"
agent_config_path = "#{install_path}/newrelic.yml"
agent_jar_path = "#{install_path}/newrelic.jar"

directory install_path do
  owner 'opencast'
  group 'opencast'
  mode '0755'
  recursive true
end

# says "if the agent jar exists and is the version we want"
guard_clause = %Q|
  [ -e '#{agent_jar_path}' ] &&
  current_ver=`java -jar #{agent_jar_path} -version` &&
  [ "$current_ver" == "#{agent_version}" ]
  |

# install jar w/ version check
remote_file agent_jar_path do
  source agent_url
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  not_if guard_clause
end

# process config template
template agent_config_path do
  source 'newrelic.yml.erb'
  manage_symlink_source true
  variables({
                license_key: license_key,
                environment_name: environment_name,
                node_name: node_name,
                log_dir: log_dir
            })
end

