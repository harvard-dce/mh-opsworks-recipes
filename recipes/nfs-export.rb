# Cookbook Name:: oc-opsworks-recipes
# Recipe:: nfs-export

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

storage_info = get_storage_info

shared_storage_root = get_shared_storage_root

include_recipe "nfs::server4"

nfs_export storage_info[:export_root] do
  network storage_info[:network]
  writeable true
  sync true
  options ['no_root_squash']
end

directory shared_storage_root do
  owner 'opencast'
  group 'opencast'
  mode '755'
  recursive true
end
