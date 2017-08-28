# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-capture-agent-manager

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "mh-opsworks-recipes::update-package-repo"

install_package("python-dev python-virtualenv python-pip " \
                "libpq-dev libffi-dev nginx apache2-utils " \
                "redis-server sqlite3 libsqlite3-dev")

capture_agent_manager_info = get_capture_agent_manager_info
app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name

user usr_name do
  comment "capture agent manager user"
  system true
  manage_home true
  home "/home/#{usr_name}"
  shell "/bin/false"
end

directory "/home/#{usr_name}/sites" do
  owner usr_name
  group usr_name
  mode "755"
  recursive true
end

directory "/home/#{usr_name}/.ssh" do
  owner usr_name
  group usr_name
  mode "700"
end

git "git clone capture_agent_manager #{app_name}" do
  repository capture_agent_manager_info.fetch(:capture_agent_manager_git_repo)
  revision capture_agent_manager_info.fetch(:capture_agent_manager_git_revision)
  destination %Q|/home/#{usr_name}/sites/#{app_name}|
  user usr_name
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

install_nginx_logrotate_customizations
if on_aws?
  configure_nginx_cloudwatch_logs
end

database_s3_resource = get_capture_agent_manager_database_s3_resource
database_filepath = get_capture_agent_manager_database_filepath
execute "pull db file from s3" do
  command %Q(aws s3 cp #{database_s3_resource} - | sqlite3 #{database_filepath})
  creates database_filepath
end

# TODO: checar permissions for s3
cron_d "db backup" do
  minute "0"
  hour "3"
  user "root"
  command %Q(sqlite3 #{database_filepath} .dump | aws s3 cp - #  #{database_s3_resource})
end
