# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-oc-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

install_package("python-dev python-virtualenv python-pip " \
                "supervisor libpq-dev libffi-dev redis-server")

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
