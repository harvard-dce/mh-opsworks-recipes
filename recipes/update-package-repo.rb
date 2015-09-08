# Cookbook Name:: mh-opsworks-recipes
# Recipe:: update-package-repo

execute 'fix any half-configured packages' do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command 'dpkg --configure -a'
  timeout 30
  retries 5
  retry_delay 15
end

execute 'update package repository' do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command 'apt-get update'
  timeout 180
  retries 5
  retry_delay 15
  ignore_failure true
end
