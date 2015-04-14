# Cookbook Name:: mh-opsworks-recipes
# Recipe:: clean-up-package-installs

execute 'clean stale packages' do
  command "apt-get clean"
  retries 5
  retry_delay 5
end
