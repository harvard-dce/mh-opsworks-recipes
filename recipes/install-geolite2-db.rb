# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-geolite2-db

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

shared_assets_bucket = get_shared_asset_bucket_name
geolite2_db_archive = elk_info['geolite2_db_archive']

if on_aws?
  include_recipe 'mh-opsworks-recipes::install-awscli'
  geolite2_dl_cmd = "/usr/local/bin/aws s3 cp s3://#{shared_assets_bucket}/#{geolite2_db_archive} ."
else
  geolite2_dl_cmd = "wget https://s3.amazonaws.com/#{shared_assets_bucket}/#{geolite2_db_archive}"
end

directory '/opt/geolite2' do
  owner 'root'
  group 'root'
  mode '755'
end

bash 'download geolite2 db' do
  code %Q|
cd /opt/geolite2 &&
/bin/rm -f *.* &&
#{geolite2_dl_cmd} &&
/bin/tar -xzvf #{geolite2_db_archive} --strip-components=1
|
  timeout 300
  retries 10
  retry_delay 5
  not_if { ::File::exists?("/opt/geolite2/#{geolite2_db_archive}") }
end

