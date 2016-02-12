# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-capture-agent-manager-supervisor

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package("supervisor")

capture_agent_manager_info = node.fetch(:capture_agent_manager, {})
app_name = capture_agent_manager_info.fetch(:capture_agent_manager_name, "capture_agent_manager")

template %Q|/etc/supervisor/conf.d/#{app_name}.conf| do
  source "capture-agent-manager-supervisor-conf.erb"
  variables({
    capture_agent_manager_name: app_name
  })
end

execute %Q|service supervisor restart && supervisorctl start #{app_name}|
