# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

%w|htop nmap traceroute silversearcher-ag screen tmux iotop emacs24-nox mytop pv nethogs|.each do |name|
  install_package(name)
end

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
