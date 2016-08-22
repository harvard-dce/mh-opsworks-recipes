# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

packages = %Q|htop nmap traceroute silversearcher-ag screen tmux iotop mytop pv nethogs sysstat dstat tree jq|
install_package(packages)

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
