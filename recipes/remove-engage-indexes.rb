# Cookbook Name:: oc-opsworks-recipes
# Recipe:: remove-engage-indexes

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
local_workspace_root = get_local_workspace_root

if dev_or_testing_cluster?
  cookbook_file 'remove-indexes.sh' do
    path '/usr/local/bin/remove-indexes.sh'
    owner 'root'
    group 'root'
    mode '755'
  end

  if do_it && engage_node?
    execute 'remove engage solr and elasticsearch indexes' do
      user 'opencast'
      command %Q|/usr/local/bin/remove-indexes.sh -x -p #{local_workspace_root}|
    end
  end
end
