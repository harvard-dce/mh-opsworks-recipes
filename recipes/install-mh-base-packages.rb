# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

package "maven2" do
  action :purge
  ignore_failure true
end

%w|autofs5
curl
dkms
gzip
libglib2.0-dev
maven
mediainfo
mysql-client
openjdk-7-jdk
openjdk-7-jre
postfix
python-pip
rsyslog-gnutls
run-one
tesseract-ocr|.each do |package_name|
  install_package(package_name)
end

include_recipe 'mh-opsworks-recipes::install-nodejs'
include_recipe "mh-opsworks-recipes::clean-up-package-cache"
