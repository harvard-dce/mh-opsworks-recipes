# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
