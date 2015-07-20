# Cookbook Name:: mh-opsworks-recipes
# Recipe:: convert-mysql-to-multiple-data-files

require 'find'

db_info = node[:deploy][:matterhorn][:database]
host = db_info[:host]
username = db_info[:username]
password = db_info[:password]
port = db_info[:port]
database_name = db_info[:database]

database_connection = %Q|/usr/bin/mysql --user="#{username}" --host="#{host}" --port=#{port} --password="#{password}"|
datadir = `#{database_connection} -B -e 'show variables like "%datadir%"' | grep datadir`.split(' ')[1]

unless File.exists?("#{datadir}#{database_name}")
  Chef::Log.info 'First time database deployment. Converting to per-table innodb storage'

  file '/etc/mysql/conf.d/innodb_tuning.cnf' do
    owner 'root'
    group 'root'
    mode '0600'
    content %Q|# Do not remove this, it's part of the mh-opsworks-recipes::convert-mysql-to-multiple-data-files recipe
[mysqld]
innodb_file_per_table
    |
  end

  execute 'service mysql restart'
else
  Chef::Log.info 'Already converted to per-table innodb storage, or we deployed previously.'
end
