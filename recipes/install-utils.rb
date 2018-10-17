# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

packages = %Q|htop nmap traceroute silversearcher-ag screen tmux iotop mytop pv nethogs sysstat dstat tree jq iozone3 fio iperf3/trusty-backports|
install_package(packages)

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
