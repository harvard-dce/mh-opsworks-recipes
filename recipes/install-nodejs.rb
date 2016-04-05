# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-nodejs

clear_cache = node.fetch(:clear_npm_cache, false)

if clear_cache
  execute "clear npm cache" do
    command %Q|npm cache clear|
    ignore_failure true
  end
end

link '/usr/bin/node' do
  action :delete
  to '/usr/bin/nodejs'
  ignore_failure true
end

['nodejs', 'nodejs-dev', 'npm'].each do |package_name|
  package package_name do
    action :purge
    ignore_failure true
  end
end

node.default['nodejs']['install_method'] = 'binary'
node.default['nodejs']['version'] = node.fetch(:node_version, '0.12.1')
include_recipe 'nodejs'
