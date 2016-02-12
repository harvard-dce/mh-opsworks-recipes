# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

%w|python-dev
python-virtualenv
python-pip
supervisor
libpq-dev
libffi-dev
nginx|.each do |package_name|
  install_package(package_name)
end

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
