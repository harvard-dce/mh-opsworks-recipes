# Cookbook Name:: oc-opsworks-recipes
# Recipe:: clean-up-package-cache

execute 'clean package cache' do
  command "yum clean all"
  retries 5
  retry_delay 5
end
