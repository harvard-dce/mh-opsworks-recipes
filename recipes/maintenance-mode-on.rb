# Cookbook Name:: oc-opsworks-recipes
# Recipe:: maintenance-mode-on

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

toggle_maintenance_mode_to(true)
