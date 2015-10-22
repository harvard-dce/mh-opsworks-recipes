# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-all-matterhorn-files

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
db_seed_file = get_db_seed_file
shared_storage_root = get_shared_storage_root

if testing_cluster?
  cookbook_file 'remove-all-matterhorn-files.sh' do
    path '/usr/local/bin/remove-all-matterhorn-files.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  if do_it && admin_node?
    execute 'remove all matterhorn files' do
      user "matterhorn"
      command %Q|/usr/local/bin/remove-all-matterhorn-files.sh -x -p "#{shared_storage_root}"|
      # There may be files in shared storage that aren't owned by matterhorn. That's OK.
      ignore_failure true
    end
  end

  include_recipe 'mh-opsworks-recipes::create-matterhorn-directories'
end
