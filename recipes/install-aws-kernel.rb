# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-aws-kernel
# This recipe is intended only for ami building

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

install_package('linux-aws')
