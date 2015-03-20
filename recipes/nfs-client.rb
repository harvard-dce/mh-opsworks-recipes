# Cookbook Name:: mh-opsworks-recipes
# Recipe:: nfs-client

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

include_recipe "nfs::client4"

layer_shortname = storage_info[:layer_shortname]

(hostname, values) = node[:opsworks][:layers][layer_shortname.to_sym][:instances].first

directory storage_info[:export_root] do
  owner "root"
  group "root"
  mode "755"
end

mount storage_info[:export_root] do
  supports remount: true
  device %Q|#{hostname}:#{storage_info[:export_root]}|
  fstype "nfs"
  options "rw"
  action [:mount, :enable]
end
