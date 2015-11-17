# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-cluster-seed-file

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root

source_engage_ip = get_public_engage_ip
source_engage_host = get_public_engage_hostname
source_admin_ip = get_public_admin_ip
source_cloudfront_domain = get_base_media_download_url(source_engage_host)
source_wowza_edge_url = get_live_streaming_url
Chef::Log.info("From create-cluster-seed-file: source_cloudfront_domain: #{source_cloudfront_domain}")

if testing_cluster?
  cookbook_file 'create-cluster-seed-file.sh' do
    path '/usr/local/bin/create-cluster-seed-file.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  if do_it && database_node?
    execute 'create cluster seed file' do
      user "root"
      command %Q|/usr/local/bin/create-cluster-seed-file.sh -x -p "#{shared_storage_root}" --source_engage_ip "#{source_engage_ip}" --source_engage_host "#{source_engage_host}" --source_admin_ip "#{source_admin_ip}" --source_cloudfront_domain="#{source_cloudfront_domain}" --source_wowza_edge_url="#{source_wowza_edge_url}"|
    end
  end
end
