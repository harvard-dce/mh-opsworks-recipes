# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

install_package("python-dev python-virtualenv python-pip " \
                "supervisor libpq-dev libffi-dev nginx redis-server")

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
