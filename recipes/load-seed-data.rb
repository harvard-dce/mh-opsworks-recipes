# Cookbook Name:: mh-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "awscli::default"

do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root
seed_file = get_seed_file
bucket_name = get_shared_asset_bucket_name

if testing_cluster?
  cookbook_file 'load-seed-data.sh' do
    path '/usr/local/bin/load-seed-data.sh'
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
  end
end
