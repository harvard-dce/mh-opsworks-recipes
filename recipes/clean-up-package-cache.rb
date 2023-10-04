# Cookbook Name:: oc-opsworks-recipes
# Recipe:: clean-up-package-cache

execute 'clean package cache' do
  command "yum clean all"
  retries 5
  retry_delay 5
end

execute 'clean pip cache' do
  command "/usr/bin/scl enable rh-python38 -- python -m pip cache purge"
  retries 5
  retry_delay 5
end
