# Cookbook Name:: mh-opsworks-recipes
# Recipe:: populate-maven-cache

bucket_name = node.fetch(:shared_asset_bucket_name, 'dce-matterhorn-assets')

# Remo
execute 'download and unpack maven cache' do
  command %Q|cd /root && /usr/bin/timeout 45 /usr/bin/curl -s http://s3.amazonaws.com/#{bucket_name}/maven_cache.tgz -o m2_cache.tgz && /bin/tar xvfz m2_cache.tgz|
  retries 5
  retry_delay 15
  not_if { ::File.exists?('/root/.m2') }
end
