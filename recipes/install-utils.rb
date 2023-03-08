# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

packages = %Q|htop nmap iotop pv nethogs sysstat dstat tree jq fio iperf3 git rsyslog-gnutls curl autofs|
install_package(packages)

# seems as good a place as any for this
cookbook_file "bash.bashrc" do
  path "/etc/bashrc"
  owner "root"
  group "root"
  mode "644"
end

cookbook_file "enable_scls.sh" do
  path "/etc/profile.d/enable_scls.sh"
  owner "root"
  group "root"
  mode "644"
end

# Fixes a bug in the ganglia monitoring service that causes hung configure events
# which can clog up the opsworks command queue
cookbook_file "gmond.service" do
  path "/usr/lib/systemd/system/gmond.service"
  owner "root"
  group "root"
  mode "644"
end

include_recipe "oc-opsworks-recipes::install-run-one"
include_recipe "oc-opsworks-recipes::install-crowdstrike"

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
