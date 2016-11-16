
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name
capture_agent_manager_info = get_capture_agent_manager_info
log_level = capture_agent_manager_info.fetch(:capture_agent_manager_gunicorn_log_level, 'INFO')


file "dotenv file" do
  path %Q|/home/#{usr_name}/sites/#{app_name}/#{app_name}.env|
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
export DB_NAME="#{stack_shortname}"
export DB_DIR="/home/#{usr_name}/db"
|
  mode "600"
end

service "capture-agent-manager-gunicorn" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true, :status => true
  action :nothing
end

template "gunicorn upstart script" do
  source "capture-agent-manager-gunicorn-upstart.conf.erb"
  path "/etc/init/capture-agent-manager-gunicorn.conf"
  owner "root"
  group "root"
  mode "644"
  variables ({
    name: app_name,
    user: usr_name
  })
  notifies :enable, 'service[capture-agent-manager-gunicorn]', :immediately
end

template "gunicorn config file" do
  source "capture-agent-manager-gunicorn-config.py.erb"
  path "/home/#{usr_name}/sites/#{app_name}/gunicorn_config.py"
  owner usr_name
  group usr_name
  mode "644"
  variables ({
    name: app_name,
    workers: 3,
    user: usr_name
  })
  notifies :restart, 'service[capture-agent-manager-gunicorn]', :immediately
end

include_recipe "mh-opsworks-recipes::configure-capture-agent-manager-nginx-proxy"
