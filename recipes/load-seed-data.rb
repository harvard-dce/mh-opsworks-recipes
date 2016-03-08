# Cookbook Name:: mh-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::install-awscli"

do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root
seed_file = get_seed_file
cluster_seed_bucket_name = get_cluster_seed_bucket_name

engage_ip = get_public_engage_ip
engage_host = get_public_engage_hostname
admin_ip = get_public_admin_ip
cloudfront_domain = get_base_media_download_domain(engage_host)
wowza_edge_url = get_live_streaming_url
s3_distribution_bucket = get_s3_distribution_bucket_name

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

  if do_it && admin_node?
    include_recipe 'mh-opsworks-recipes::remove-all-matterhorn-files'

    execute 'load seed database and create seed files' do
      user "root"
      command %Q|/usr/local/bin/load-seed-data.sh -x -p "#{shared_storage_root}" -b "#{cluster_seed_bucket_name}" -s "#{seed_file}" -n "#{s3_distribution_bucket}"|
      timeout 600
    end

    execute 'modify database to reflect local cluster hostnames' do
      user "root"
      command %Q|/usr/local/bin/modify-database-after-loading-seed-data.sh -x -p "#{shared_storage_root}" --engage_ip "#{engage_ip}" --engage_host "#{engage_host}" --admin_ip "#{admin_ip}" --cloudfront_domain "#{cloudfront_domain}" --wowza_edge_url "#{wowza_edge_url}"|
      timeout 600
    end
  end
end
