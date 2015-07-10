# Cookbook Name:: mh-opsworks-recipes
# Recipe:: clean-up-package-cache

execute 'clean package cache' do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command "apt-get clean"
  retries 5
  retry_delay 5
end
