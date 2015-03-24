# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-utils

include_recipe "mh-opsworks-recipes::update-package-repo"

%w|htop nmap traceroute silversearcher-ag screen tmux|.each do |package_name|
  package package_name
end

include_recipe "mh-opsworks-recipes::clean-up-package-installs"
