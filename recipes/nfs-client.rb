# Cookbook Name:: mh-opsworks-recipes
# Recipe:: nfs-client

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

# Ensure nfs client requirements are installed
package 'autofs5'
include_recipe "nfs::client4"

export_root = storage_info[:export_root]
storage_hostname = ''
storage_available = false

if storage_info[:type] == 'external'
  storage_available = true
  storage_hostname = storage_info[:nfs_server_host]
else
  layer_shortname = storage_info[:layer_shortname]
  (storage_hostname, storage_available) = node[:opsworks][:layers][layer_shortname.to_sym][:instances].first
end

directory export_root do
  owner "matterhorn"
  group "matterhorn"
  mode "755"
  recursive true
end

if storage_available
  file '/etc/auto.matterhorn' do
    action :create
    owner 'root'
    group 'root'
    mode '640'
    content %Q|#{export_root} -fstype=nfs,rw #{storage_hostname}:#{export_root}|
  end

  service 'autofs' do
    action [:enable]
  end

  ruby_block "update /etc/auto.master to include matterhorn map" do
    block do
      editor = Chef::Util::FileEdit.new('/etc/auto.master')
      editor.insert_line_if_no_match(/auto\.matterhorn/, "/- /etc/auto.matterhorn --timeout=600")
      editor.write_file
    end
    not_if { ::File.read('/etc/auto.master').include?('auto.matterhorn') }
  end

  # For some reason, doing this the more native chef way doesn't
  # cause autofs to fully restart and notice the new mount configuration
  execute 'restart autofs' do
    command 'service autofs restart'
  end

  [ export_root, export_root + '/archive' ].each do |matterhorn_directory|
    directory matterhorn_directory do
      owner 'matterhorn'
      group 'matterhorn'
      mode '755'
    end
  end
end
