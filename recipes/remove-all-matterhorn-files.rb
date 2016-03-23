# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-all-matterhorn-files

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
db_seed_file = get_db_seed_file
shared_storage_root = get_shared_storage_root
s3_distribution_bucket = get_s3_distribution_bucket_name

if dev_or_testing_cluster?
  cookbook_file 'remove-all-matterhorn-files.sh' do
    path '/usr/local/bin/remove-all-matterhorn-files.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  if do_it && admin_node?
    execute 'remove all matterhorn files' do
      user "matterhorn"
      command %Q|/usr/local/bin/remove-all-matterhorn-files.sh -x -p "#{shared_storage_root}" -b "#{s3_distribution_bucket}"|
      # There may be files in shared storage that aren't owned by matterhorn. That's OK.
      ignore_failure true
    end
  end
end
