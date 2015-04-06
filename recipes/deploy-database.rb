# Cookbook Name:: mh-opsworks-recipes
# Recipe:: deploy-database

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
db_seed_file = node.fetch(:db_seed_file, 'dce-config/docs/scripts/ddl/mysql5.sql')
db_info = node[:deploy][:matterhorn][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]

git_data = node[:deploy][:matterhorn][:scm]
repo_url = git_repo_url(git_data)

deploy_revision matterhorn_repo_root do
  repo repo_url
  revision git_data.fetch(:revision, 'master')
  enable_submodules true

  user 'matterhorn'
  group 'matterhorn'

  migrate false
  symlinks({})
  create_dirs_before_symlink([])
  purge_before_symlink([])
  symlink_before_migrate({})
  keep_releases 10
  action :deploy

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
