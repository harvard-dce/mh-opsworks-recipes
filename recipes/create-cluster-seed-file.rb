# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-cluster-seed-file

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::install-awscli"
do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root

source_engage_ip = get_public_engage_ip
source_engage_host = get_public_engage_hostname
source_admin_ip = get_public_admin_ip
source_admin_host = if admin_node?
               get_public_admin_hostname_on_admin
             else
               get_public_admin_hostname
             end
source_cloudfront_domain = get_base_media_download_domain(source_engage_host)
source_wowza_edge_url = get_live_streaming_url
source_s3_bucket = get_s3_distribution_bucket_name
cluster_seed_bucket_name = get_cluster_seed_bucket_name
base_cluster_seed_name = topic_name

if dev_or_testing_cluster?
  cookbook_file 'create-cluster-seed-file.sh' do
    path '/usr/local/bin/create-cluster-seed-file.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  if do_it && admin_node?
    execute 'create cluster seed file' do
      user "root"
      command %Q|/usr/local/bin/create-cluster-seed-file.sh -x -p "#{shared_storage_root}" --source_engage_ip "#{source_engage_ip}" --source_engage_host "#{source_engage_host}" --source_admin_ip "#{source_admin_ip}" --source_admin_host "#{source_admin_host}" --source_cloudfront_domain "#{source_cloudfront_domain}" --source_wowza_edge_url "#{source_wowza_edge_url}" --source_s3_bucket "#{source_s3_bucket}" --base_cluster_seed_name "#{base_cluster_seed_name}" --upload_s3_bucket "#{cluster_seed_bucket_name}"|
    end
  end
end
