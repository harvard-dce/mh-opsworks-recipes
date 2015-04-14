# Cookbook Name:: mh-opsworks-recipes
# Recipe:: update-package-repo

execute 'update package repository' do
  command 'apt-get update'
  retries 5
  retry_delay 15
end
