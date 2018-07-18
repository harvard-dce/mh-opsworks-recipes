require 'resolv'
# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-squid-proxy-for-storage-cluster

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

return unless external_storage?

install_package('squid3')

storage_hostname = get_storage_hostname

template %Q|/etc/squid3/squid.conf| do
  source 'squid.conf.erb'
  owner 'root'
  group 'root'
  variables({
    storage_ip_address: ::Resolv.getaddress(storage_hostname)
  })
end

execute 'service squid3 restart'
