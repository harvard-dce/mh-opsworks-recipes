# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-cluster-seed-file

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
shared_storage_root = get_shared_storage_root

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
      command %Q|/usr/local/bin/create-cluster-seed-file.sh -x -p "#{shared_storage_root}"|
    end
  end
end
