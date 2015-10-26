# Cookbook Name:: mh-opsworks-recipes
# Recipe:: populate-maven-cache

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "mh-opsworks-recipes::install-awscli"
bucket_name = get_shared_asset_bucket_name

execute 'download and unpack maven cache' do
  command %Q|cd /root && /bin/rm -Rf .m2/ && aws s3 cp s3://#{bucket_name}/maven_cache.tgz . && /bin/tar xvfz maven_cache.tgz && rm maven_cache.tgz|
  retries 10
  retry_delay 5
  timeout 300
  not_if { ::File.exists?('/root/.m2') }
end
