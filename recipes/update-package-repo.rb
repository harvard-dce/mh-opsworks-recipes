# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-package-repo

execute 'enable epel' do
  command 'yum-config-manager --enable epel'
  retries 5
  retry_delay 15
end

execute 'update package repository' do
  command 'yum update'
  timeout 180
  retries 5
  retry_delay 15
  ignore_failure true
end
