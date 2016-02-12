# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ca-webapp

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ca_webapp_info = node.fetch(:ca_webapp, {})
app_name = ca_webapp_info.fetch(:ca_webapp_name, "webapp")

git "git clone webapp #{app_name}" do
  repository ca_webapp_info.fetch(:webapp_git_repo, "https://github.com/harvard-dce/webapp")
  revision ca_webapp_info.fetch(:webapp_git_revision, "master")
  destination "/home/web/sites/#{app_name}"
  user 'web'
end

file "/home/web/sites/#{app_name}/#{app_name}.env" do
  owner "web"
  group "web"
  content %Q|
export CA_STATS_USER="#{ca_webapp_info[:ca_stats_user]}"
export CA_STATS_PASSWD="#{ca_webapp_info[:ca_stats_passwd]}"
export CA_STATS_JSON_URL="#{ca_webapp_info[:ca_stats_json_url]}"
export EPIPEARL_USER="#{ca_webapp_info[:epipearl_user]}"
export EPIPEARL_PASSWD="#{ca_webapp_info[:epipearl_passwd]}"
export LDAP_HOST="#{ca_webapp_info[:ldap_host]}"
export LDAP_BASE_SEARCH="#{ca_webapp_info[:ldap_base_search]}"
export LDAP_BIND_DN="#{ca_webapp_info[:ldap_bind_dn]}"
export LDAP_BIND_PASSWD="#{ca_webapp_info[:ldap_bind_passwd]}"
export LOG_CONFIG="#{ca_webapp_info[:log_config]}"
export FLASK_SECRET="#{ca_webapp_info[:webapp_secret_key]}"
export DATABASE_USR="#{ca_webapp_info[:webapp_database_usr]}"
export DATABASE_PWD="#{ca_webapp_info[:webapp_database_pwd]}"
|
  mode "600"
end

execute "create virtualenv" do
  command "/usr/bin/virtualenv /home/web/sites/#{app_name}/venv"
  user "web"
  creates "/home/web/sites/#{app_name}/venv/bin/activate"
end

execute "install webapp dependencies" do
  command "source /home/web/sites/#{app_name}/venv/bin/activate && pip install -r /home/web/sites/#{app_name}/requirements.txt"
  user "web"
end

cookbook_file "ca-webapp-logrotate.conf" do
  path "/etc/logrotate.d/#{app_name}"
  owner "root"
  group "root"
  mode "644"
end

