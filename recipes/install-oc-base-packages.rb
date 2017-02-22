# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-oc-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

packages = %Q|autofs5 curl dkms gzip jq libglib2.0-dev mysql-client postfix python-pip rsyslog-gnutls run-one tesseract-ocr|
install_package(packages)

# remove any existing maven install
['maven2', 'maven'].each do |package_name|
  package package_name do
    action :purge
    ignore_failure true
  end
end

include_recipe 'java'
include_recipe 'maven'
include_recipe 'activemq'
include_recipe 'oc-opsworks-recipes::install-nodejs'
include_recipe "oc-opsworks-recipes::clean-up-package-cache"
