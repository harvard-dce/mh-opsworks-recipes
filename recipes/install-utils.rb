# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-utils

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

packages = %Q|htop nmap iotop pv nethogs sysstat dstat tree jq fio iperf3 git rsyslog-gnutls curl autofs|
install_package(packages)

# seems as good a place as any for this
cookbook_file "bash.bashrc" do
	path "/etc/bash.bashrc"
	owner "root"
	group "root"
	mode "644"
end

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
