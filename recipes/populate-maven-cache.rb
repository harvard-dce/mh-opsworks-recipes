# Cookbook Name:: mh-opsworks-recipes
# Recipe:: populate-maven-cache

include_recipe "mh-opsworks-recipes::update-package-repo"
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('curl')

bucket_name = node.fetch(:shared_asset_bucket_name, 'mh-opsworks-shared-assets')

execute 'download and unpack maven cache' do
  command %Q|cd /root && /bin/rm -Rf .m2/ && /usr/bin/curl --continue-at - --silent http://s3.amazonaws.com/#{bucket_name}/maven_cache.tgz --output m2_cache.tgz && /bin/tar xvfz m2_cache.tgz && rm m2_cache.tgz|
  retries 10
  retry_delay 15
  timeout 45
  not_if { ::File.exists?('/root/.m2') }
end
