# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

package "maven2" do
  action :purge
  ignore_failure true
end

packages = %Q|autofs5 curl dkms gzip jq libglib2.0-dev maven mediainfo mysql-client openjdk-7-jdk openjdk-7-jre postfix python-pip python-dev rsyslog-gnutls run-one tesseract-ocr|
install_package(packages)

include_recipe "mh-opsworks-recipes::clean-up-package-cache"
