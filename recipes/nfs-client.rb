# Cookbook Name:: mh-opsworks-recipes
# Recipe:: nfs-client

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

# Ensure nfs client requirements are installed
install_package('autofs5')
include_recipe "nfs::client4"

export_root = storage_info[:export_root]
shared_storage_root = get_shared_storage_root

# If we've explictly defined an nfs server export root path different than
# the path we use everywhere else, use that for the export root.  This is
# primarily for efs, which exports a filesystem on the root path always.
nfs_server_export_root = storage_info[:nfs_server_export_root] || storage_info[:export_root]
storage_hostname = ''
storage_available = false

if storage_info[:type] == 'external'
  storage_available = true
  storage_hostname = storage_info[:nfs_server_host]
else
  layer_shortname = storage_info[:layer_shortname]
  (storage_hostname, storage_available) = node[:opsworks][:layers][layer_shortname.to_sym][:instances].first
end

if storage_available
  directory '/etc/auto.master.d' do
    action :create
    owner 'root'
    group 'root'
    mode '755'
  end

  file '/etc/auto.matterhorn' do
    action :create
    owner 'root'
    group 'root'
    mode '640'
    content %Q|#{export_root} -fstype=nfs4 #{storage_hostname}:#{nfs_server_export_root}\n|
  end

  file '/etc/auto.master.d/matterhorn.autofs' do
    action :create
    owner 'root'
    group 'root'
    mode '640'
    content "/- /etc/auto.matterhorn -t 3600 -n 1"
  end

  # Only restart if we don't have an active mount
  execute 'service autofs restart' do
    command 'service autofs restart'
    not_if %Q|grep ' #{export_root} ' /proc/mounts|
  end

  execute 'warm directory' do
    command %Q|ls -flai #{export_root}/|
    retries 10
    retry_delay 5
  end

  directory shared_storage_root do
    owner 'matterhorn'
    group 'matterhorn'
    mode '755'
    recursive true
  end
end
