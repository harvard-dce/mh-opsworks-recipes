# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-gunicorn

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name
capture_agent_manager_info = get_capture_agent_manager_info
log_level = capture_agent_manager_info.fetch(:capture_agent_manager_gunicorn_log_level)

execute "install gunicorn" do
  command "/home/#{usr_name}/sites/#{app_name}/venv/bin/pip install gunicorn"
  user usr_name
  creates "/home/#{usr_name}/sites/#{app_name}/venv/bin/gunicorn"
end

template "/home/#{usr_name}/sites/#{app_name}/gunicorn_start.sh" do
  source "capture-agent-manager-gunicorn-start.sh.erb"
  owner usr_name
  group usr_name
  mode "775"
  variables({
    capture_agent_manager_name: app_name,
    capture_agent_manager_usr_name: usr_name,
    capture_agent_manager_gunicorn_log_level: log_level
  })
end
