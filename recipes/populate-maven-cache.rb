# Cookbook Name:: mh-opsworks-recipes
# Recipe:: populate-maven-cache

bucket_name = node.fetch(:shared_asset_bucket_name, 'dce-matterhorn-assets')

remote_file '/root/m2_cache.tgz' do
  source %Q|http://s3.amazonaws.com/#{bucket_name}/maven_cache.tgz|
  action :create_if_missing
  backup false
  ignore_failure true
end

execute 'unpack maven cache' do
  command 'cd /root && tar xvfz m2_cache.tgz'
  not_if { ::File.exists?('/root/.m2') || ! ::File.exists?('/root/m2_cache.tgz') }
end
