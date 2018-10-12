# Cookbook Name:: oc-opsworks-recipes
# Recipe:: enable-enhanced-networking

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::install-awscli"
install_package('dkms')

bucket_name = get_shared_asset_bucket_name
ena_version = node.fetch(:ena_version, "1.6.0")

cookbook_file 'enable_enhanced_networking.sh' do
  path "/usr/local/bin/enable_enhanced_networking.sh"
  owner "root"
  group "root"
  mode "700"
end

execute 'fully enable enhanced networking' do
  # This doesn't do anything if the driver is already the correct version for specified kernel
  command %Q|/usr/local/bin/enable_enhanced_networking.sh "#{ena_version}" "#{bucket_name}"|
end
