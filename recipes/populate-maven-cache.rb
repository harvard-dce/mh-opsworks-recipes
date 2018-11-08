# Cookbook Name:: oc-opsworks-recipes
# Recipe:: populate-maven-cache

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
bucket_name = get_shared_asset_bucket_name

if on_aws?
  include_recipe "oc-opsworks-recipes::install-awscli"
  download_command = "aws s3 cp s3://#{bucket_name}/oc_maven_cache.tgz ."
else
  download_command =  "wget https://s3.amazonaws.com/#{bucket_name}/oc_maven_cache.tgz"
end

execute 'download and unpack maven cache' do
  command %Q|cd /root && /bin/rm -Rf .m2/ && #{download_command} && /bin/tar xvfz oc_maven_cache.tgz && rm oc_maven_cache.tgz|
  retries 10
  retry_delay 5
  timeout 300
  not_if { ::File.exists?('/root/.m2') }
end
