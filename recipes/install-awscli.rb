# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-awscli

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-python"

if on_aws?
  awscli_version = node.fetch(:awscli_version, '1.27.78')
  pip_install("awscli==#{awscli_version}")
end
