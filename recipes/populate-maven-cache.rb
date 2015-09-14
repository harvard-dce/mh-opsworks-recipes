# Cookbook Name:: mh-opsworks-recipes
# Recipe:: populate-maven-cache

include_recipe "awscli::default"

bucket_name = node.fetch(:shared_asset_bucket_name, 'mh-opsworks-shared-assets')

execute 'download and unpack maven cache' do
  command %Q|cd /root && /bin/rm -Rf .m2/ && aws s3 cp s3://#{bucket_name}/maven_cache.tgz . && /bin/tar xvfz maven_cache.tgz && rm maven_cache.tgz|
  retries 10
  retry_delay 5
  timeout 300
  not_if { ::File.exists?('/root/.m2') }
end
