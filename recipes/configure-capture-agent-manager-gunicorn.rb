# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-gunicorn

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

capture_agent_manager_info = node.fetch(:capture_agent_manager, {})
app_name = capture_agent_manager_info.fetch(:capture_agent_manager_name, "capture_agent_manager")

execute "install gunicorn" do
  command "source /home/capture_agent_manager/sites/#{app_name}/venv/bin/activate" \
    " && pip install gunicorn"
  user "capture_agent_manager"
  creates "/home/capture_agent_manager/sites/#{app_name}/venv/bin/gunicorn"
end

template "/home/capture_agent_manager/sites/#{app_name}/gunicorn_start.sh" do
  source "capture-agent-manager-gunicorn-start.sh.erb"
  owner "capture_agent_manager"
  group "capture_agent_manager"
  mode "775"
  variables({
    capture_agent_manager_name: app_name
  })
end

directory "/home/capture_agent_manager/sock" do
  owner "capture_agent_manager"
  group "capture_agent_manager"
  mode "775"
end
