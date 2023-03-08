# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-python

# make sure we're using the latest python3 available
# and the latest pip and virtualenv libraries

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

# prepend  what will be the correct path to python and other installed executables (e.g. the `aws` cli)
ENV['PATH'] = "/opt/rh/rh-python38/root/usr/local/bin:#{ENV['PATH']}"

packages = %Q|rh-python38 rh-python38-python-devel openssl-devel libffi-devel bzip2-devel gcc|
install_package(packages)

pip_install("pip")
pip_install("virtualenv")
