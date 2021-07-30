# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-oc-base-packages

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::update-package-repo"

packages = %Q|autofs5 curl dkms gzip jq libglib2.0-dev mysql-client postfix python3-pip python3-setuptools python3-dev rsyslog-gnutls run-one tesseract-ocr|
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

# create symlink in common system path as deploy operations don't seem to source
# The $PATH settings the maven cookbook creates in '/etc/profile.d/maven.sh'
# Note: this is a feature of later versions of the maven cookbook
if node['maven']['setup_bin']
  link '/usr/bin/mvn' do
    to "#{node['maven']['m2_home']}/bin/mvn"
  end
end

# this is a workaround for a bug on ubuntu 14.04: https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/1406483
# alternatively we could purge and reinstall the ca-certificates-java package but this works and is simpler
execute 'update-ca-certificates' do
  command '/usr/sbin/update-ca-certificates -f'
  not_if 'test -e /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts'
end

if admin_node? || allinone_node?
  include_recipe 'activemq'
end

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
