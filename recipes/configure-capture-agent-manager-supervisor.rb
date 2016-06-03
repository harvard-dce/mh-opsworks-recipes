# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-supervisor

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package("supervisor")

app_name = get_capture_agent_manager_app_name
usr_name = get_capture_agent_manager_usr_name

template "/etc/supervisor/conf.d/#{app_name}.conf" do
  source "capture-agent-manager-supervisor-conf.erb"
  variables({
    capture_agent_manager_name: app_name,
    capture_agent_manager_usr_name: usr_name
  })
end

execute "service supervisor restart"
