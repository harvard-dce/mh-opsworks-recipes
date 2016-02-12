# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-capture-agent-manager

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = node.fetch(:capture_agent_manager, {})
app_name = capture_agent_manager_info.fetch(:capture_agent_manager_name, "capture_agent_manager")

git "git clone capture_agent_manager #{app_name}" do
  repository capture_agent_manager_info.fetch(:capture_agent_manager_git_repo, "https://github.com/harvard-dce/capture_agent_manager")
  revision capture_agent_manager_info.fetch(:capture_agent_manager_git_revision, "master")
  destination "/home/capture_agent_manager/sites/#{app_name}"
  user 'capture_agent_manager'
end

file "/home/capture_agent_manager/sites/#{app_name}/#{app_name}.env" do
  owner "capture_agent_manager"
  group "capture_agent_manager"
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
export DATABASE_USR="#{capture_agent_manager_info[:capture_agent_manager]}"
export DATABASE_PWD="#{capture_agent_manager_info[:capture_agent_manager_database_pwd]}"
|
  mode "600"
end

execute "create virtualenv" do
  command "/usr/bin/virtualenv /home/capture_agent_manager/sites/#{app_name}/venv"
  user "capture_agent_manager"
  creates "/home/capture_agent_manager/sites/#{app_name}/venv/bin/activate"
end

execute "install capture_agent_manager dependencies" do
  command "source /home/capture_agent_manager/sites/#{app_name}/venv/bin/activate && pip install -r /home/capture_agent_manager/sites/#{app_name}/requirements.txt"
  user "capture_agent_manager"
end

cookbook_file "capture-agent-manager-logrotate.conf" do
  path "/etc/logrotate.d/#{app_name}"
  owner "root"
  group "root"
  mode "644"
end

