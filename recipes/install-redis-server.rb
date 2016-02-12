# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-redis-server

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('redis-server')

