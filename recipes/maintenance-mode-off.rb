# Cookbook Name:: mh-opsworks-recipes
# Recipe:: maintenance-mode-off

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

toggle_maintenance_mode_to(false)
