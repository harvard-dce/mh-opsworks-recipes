# Cookbook Name:: mh-opsworks-recipes
# Recipe:: nfs-export

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

include_recipe "nfs::server4"

nfs_export storage_info[:export_root] do
  network storage_info[:network]
  writeable true
  sync true
  options ['no_root_squash']
end

directory storage_info[:export_root] do
  owner 'matterhorn'
  group 'matterhorn'
  mode '755'
end
