# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-capture-agent-manager

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = get_capture_agent_manager_info
app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name

git "git clone capture_agent_manager #{app_name}" do
  repository capture_agent_manager_info.fetch(:capture_agent_manager_git_repo)
  revision capture_agent_manager_info.fetch(:capture_agent_manager_git_revision)
  destination %Q|/home/#{usr_name}/sites/#{app_name}|
  user usr_name
end

file %Q|/home/#{usr_name}/sites/#{app_name}/#{app_name}.env| do
  owner usr_name
  group usr_name
  content %Q|
export CA_STATS_USER="#{capture_agent_manager_info[:ca_stats_user]}"
export CA_STATS_PASSWD="#{capture_agent_manager_info[:ca_stats_passwd]}"
export CA_STATS_JSON_URL="#{capture_agent_manager_info[:ca_stats_json_url]}"
export EPIPEARL_USER="#{capture_agent_manager_info[:epipearl_user]}"
export EPIPEARL_PASSWD="#{capture_agent_manager_info[:epipearl_passwd]}"
export LDAP_HOST="#{capture_agent_manager_info[:ldap_host]}"
export LDAP_BASE_SEARCH="#{capture_agent_manager_info[:ldap_base_search]}"
export LDAP_BIND_DN="#{capture_agent_manager_info[:ldap_bind_dn]}"
export LDAP_BIND_PASSWD="#{capture_agent_manager_info[:ldap_bind_passwd]}"
export LOG_CONFIG="#{capture_agent_manager_info[:log_config]}"
export FLASK_SECRET="#{capture_agent_manager_info[:capture_agent_manager_secret_key]}"
export DATABASE_USR="#{capture_agent_manager_info[:capture_agent_manager_database_usr]}"
export DATABASE_PWD="#{capture_agent_manager_info[:capture_agent_manager_database_pwd]}"
|
  mode "600"
end

execute "create virtualenv" do
  command %Q|/usr/bin/virtualenv /home/#{usr_name}/sites/#{app_name}/venv|
  user usr_name
  creates %Q|/home/#{usr_name}/sites/#{app_name}/venv/bin/activate|
end

execute "install capture_agent_manager dependencies" do
  command %Q|/home/#{usr_name}/sites/#{app_name}/venv/bin/pip install -r /home/#{usr_name}/sites/#{app_name}/requirements.txt|
  user usr_name
  environment ({ "HOME" => "/home/#{usr_name}" })
end

cookbook_file "capture-agent-manager-logrotate.conf" do
  path %Q|/etc/logrotate.d/#{app_name}|
  owner "root"
  group "root"
  mode "644"
end

configure_cloudwatch_log("capture-agent-manager", "/home/capture_agent_manager/logs/*.log", "%Y-%m-%d %H:%M:%S")

