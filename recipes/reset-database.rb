# Cookbook Name:: mh-opsworks-recipes
# Recipe:: reset-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
do_it = node.fetch(:do_it, false)
db_seed_file = get_db_seed_file

if do_it
  cookbook_file 'reset-mysql-database.sh' do
    path '/usr/local/sbin/reset-mysql-database.sh'
    owner 'root'
    group 'root'
    mode '700'
  end

  execute 'delete matterhorn database' do
    user "root"
    command %Q|/usr/local/sbin/reset-mysql-database.sh -x -f "#{db_seed_file}"|
  end
end
