# Cookbook Name:: mh-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
db_seed_file = get_db_seed_file
matterhorn_repo_root = node[:matterhorn_repo_root]

if testing_cluster?
  cookbook_file 'reset-mysql-database.sh' do
    path '/usr/local/bin/reset-mysql-database.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  if do_it && database_node?
    execute 'delete matterhorn database' do
      user "root"
      command %Q|/usr/local/bin/reset-mysql-database.sh -x -f "#{matterhorn_repo_root}/current/#{db_seed_file}"|
    end
  end
end
