# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-package-repo

execute 'enable optional repos' do
  command 'yum-config-manager --enable rhel-7-server-rhui-optional-rpms'
  retries 5
  retry_delay 15
end

# not strictly necessary as the standard yum install commands will refresh
# the package list when needed, but this might save time when many packages
# are being installed sequentially
execute 'update package list' do
  command 'yum makecache'
  timeout 180
  retries 5
  retry_delay 15
  ignore_failure true
end
