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
node.default['nodejs']['binary']['checksum'] = '270d478d0ffb06063f01eab932f672b788f6ecf3c117075ac8b87c0c17e0c9de'
node.default['nodejs']['binary']['url'] = %Q|https://s3.amazonaws.com/#{get_shared_asset_bucket_name}/node-v0.12.1-linux-x64.tar.gz|
include_recipe 'nodejs'
