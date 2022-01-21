# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-oc-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::update-package-repo"


# make sure we get this one from the epel repo or it will cause dep conflicts with tesseract
install_package("libwebp", %Q|--disablerepo="*" --enablerepo="epel"|)

packages = %Q|java-1.8.0-openjdk java-1.8.0-openjdk-devel mysql56 postfix tesseract|
install_package(packages)

# remove java-1.7 so that 1.8 becomes default
package 'java-1.7.0-openjdk' do
  action :remove
  ignore_failure true
end

# we use postfix
package 'sendmail' do
  action :remove
  ignore_failure true
end

include_recipe 'maven'

# create symlink in common system path as deploy operations don't seem to source
# The $PATH settings the maven cookbook creates in '/etc/profile.d/maven.sh'
# Note: this is a feature of later versions of the maven cookbook
if node['maven']['setup_bin']
  link '/usr/bin/mvn' do
    to "#{node['maven']['m2_home']}/bin/mvn"
  end
end

if admin_node? || allinone_node?
  include_recipe 'activemq'
end

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
