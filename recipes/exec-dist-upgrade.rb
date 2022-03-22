# Cookbook Name:: oc-opsworks-recipes
# Recipe:: exec-dist-upgrade

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::update-package-repo"

execute "dist upgrade" do
  command %Q|yum update -y|
  retries 5
  retry_delay 15
  timeout 180
end

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
