# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

packages = %Q|htop nmap iotop pv nethogs sysstat dstat tree jq fio iperf3 python38 python38-devel|
install_package(packages)

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
