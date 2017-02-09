# Cookbook Name:: oc-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
db_seed_file = get_db_seed_file
opencast_repo_root = node[:opencast_repo_root]

if dev_or_testing_cluster?
  cookbook_file 'reset-mysql-database.sh' do
    path '/usr/local/bin/reset-mysql-database.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  if do_it && admin_node?
    execute 'delete opencast database' do
      user "root"
      command %Q|/usr/local/bin/reset-mysql-database.sh -x -f "#{opencast_repo_root}/current/#{db_seed_file}"|
    end
  end
end
