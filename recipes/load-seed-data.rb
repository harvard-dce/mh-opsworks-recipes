# Cookbook Name:: mh-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "awscli::default"

do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root
seed_file = get_seed_file
bucket_name = get_shared_asset_bucket_name

engage_ip = get_public_engage_ip
engage_host = get_public_engage_hostname
admin_ip = get_public_admin_ip
cloudfront_domain = get_base_media_download_url
wowza_edge_url = get_live_streaming_url

if testing_cluster?
  cookbook_file 'load-seed-data.sh' do
    path '/usr/local/bin/load-seed-data.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  cookbook_file 'modify-database-after-loading-seed-data.sh' do
    path '/usr/local/bin/modify-database-after-loading-seed-data.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  if do_it && database_node?
    include_recipe 'mh-opsworks-recipes::remove-all-matterhorn-files'

    execute 'load seed database and create seed files' do
      user "root"
      command %Q|/usr/local/bin/load-seed-data.sh -x -p "#{shared_storage_root}" -b "#{bucket_name}" -s "#{seed_file}"|
      timeout 600
    end

    execute 'modify database to reflect local cluster hostnames' do
      user "root"
      command %Q|/usr/local/bin/modify-database-after-loading-seed-data.sh -x -p "#{shared_storage_root}" --engage_ip "#{engage_ip}" --engage_host "#{engage_host}" --admin_ip "#{admin_ip}" --cloudfront_domain "#{cloudfront_domain}" --wowza_edge_url "#{wowza_edge_url}"|
      timeout 600
    end
  end
end
