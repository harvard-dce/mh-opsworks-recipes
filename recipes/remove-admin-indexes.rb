# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-admin-indexes

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
local_workspace_root = get_local_workspace_root

if testing_cluster?
  cookbook_file 'remove-solr-indexes.sh' do
    path '/usr/local/bin/remove-solr-indexes.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  if do_it && admin_node?
    execute 'remove admin solr indexes' do
      user 'matterhorn'
      command %Q|/usr/local/bin/remove-solr-indexes.sh -x -p #{local_workspace_root}|
    end
  end
end
