# Cookbook Name:: mh-opsworks-recipes
# Recipe:: configure-ca-webapp-supervisor

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package("supervisor")

ca_webapp_info = node.fetch(:ca_webapp, {})
app_name = ca_webapp_info.fetch(:ca_webapp_name, "webapp")

template %Q|/etc/supervisor/conf.d/#{app_name}.conf| do
  source "ca-webapp-supervisor-conf.erb"
  variables({
    ca_webapp_name: app_name
  })
end

execute %Q|service supervisor restart && supervisorctl start #{app_name}|
