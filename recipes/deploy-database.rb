# Cookbook Name:: oc-opsworks-recipes
# Recipe:: deploy-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

opencast_repo_root = node[:opencast_repo_root]
db_seed_file = get_db_seed_file
db_info = node[:deploy][:opencast][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]

git_data = node[:deploy][:opencast][:scm]
repo_url = git_repo_url(git_data)

deploy_action = get_deploy_action

deploy_revision "opencast" do
  deploy_to opencast_repo_root
  repo repo_url
  revision git_data.fetch(:revision, 'master')

  user 'opencast'
  group 'opencast'

  migrate false
  symlinks({})
  create_dirs_before_symlink([])
  purge_before_symlink([])
  symlink_before_migrate({})
  keep_releases 10
  action deploy_action

  before_symlink do
    most_recent_deploy = path_to_most_recent_deploy(new_resource)

    database_connection = %Q|/usr/bin/mysql --user="#{username}" --host="#{host}" --port=#{port} --password="#{password}" "#{database_name}"|
    create_database = %Q|#{database_connection} < #{most_recent_deploy}/#{db_seed_file}|
    tables_exist = %Q(#{database_connection} -B -e "show tables" | grep -qie "Tables_in_#{database_name}")

    execute 'Create database' do
      command create_database
      not_if tables_exist
    end
  end
end
