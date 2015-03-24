# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-database

matterhorn_repo_root = node[:matterhorn_repo_root]
db_seed_file = node.fetch(:db_seed_file, 'dce-config/docs/scripts/ddl/mysql5.sql')
db_info = node[:deploy][:matterhorn][:database]

host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]

database_connection = %Q|/usr/bin/mysql --user="#{username}" --host="#{host}" --port=#{port} --password="#{password}" "#{database_name}"|
create_database = %Q|#{database_connection} < #{matterhorn_repo_root}/#{db_seed_file}|
tables_exist = %Q(#{database_connection} -B -e "show tables" | grep -qie "Tables_in_#{database_name}")

execute 'Create database' do
  command create_database
  not_if tables_exist
end
