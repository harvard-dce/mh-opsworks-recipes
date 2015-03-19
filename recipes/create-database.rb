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

execute 'Create database' do
  command %Q|/usr/bin/mysql --user="#{username}" --host="#{host}" --port=#{port} --password="#{password}" "#{database_name}" < #{matterhorn_repo_root}/#{db_seed_file}|
end
