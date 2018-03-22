# Cookbook Name:: oc-opsworks-recipes
# Recipe:: populate-maven-cache

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
bucket_name = get_shared_asset_bucket_name

if on_aws?
  include_recipe "oc-opsworks-recipes::install-awscli"
  download_command = "aws s3 cp s3://#{bucket_name}/maven_cache.tgz ."
else
  download_command =  "wget https://s3.amazonaws.com/#{bucket_name}/maven_cache.tgz"
end

# create path for m2 repository under /home/opencast
directory "/home/opencast/.m2" do
  action :create
  owner 'opencast'
  group 'opencast'
  mode '755'
  recursive true
end

execute 'download and unpack maven cache' do
  command %Q|cd /home/opencast && /bin/rm -Rf .m2/ && #{download_command} && /bin/tar xvfz maven_cache.tgz && rm maven_cache.tgz|
  retries 10
  retry_delay 5
  timeout 300
  not_if { ::File.exists?('/home/opencast/.m2') }
end
