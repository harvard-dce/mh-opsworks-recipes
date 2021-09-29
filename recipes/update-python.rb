# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-python

# make sure we're using the latest python3 available (in amazon linux)
# and the latest pip and virtualenv libraries

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

packages = %Q|python38 python38-devel openssl-devel libffi-devel bzip2-devel gcc|
install_package(packages)

execute 'upgrade pip' do
	command "/usr/bin/python3 -m pip install -U pip"
end

execute 'install virtualenv' do
	command "/usr/bin/python3 -m pip install -U virtualenv"
end
