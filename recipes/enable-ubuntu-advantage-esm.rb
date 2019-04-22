# Cookbook Name:: oc-opsworks-recipes
# Recipe:: enable-ubuntu-advantage-esm

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('apt apt-transport-https apt-utils libapt-inst1.5 libapt-pkg4.12 ubuntu-advantage-tools')

esm_auth = node.fetch(:ubuntu_advantage_esm, {})
return if esm_auth.empty?

execute "enable esm" do
  command %Q|ubuntu-advantage enable-esm #{esm_auth[:user]}:#{esm_auth[:password]}|
  retries 5
  retry_delay 15
  not_if "sudo apt-cache policy | grep -i esm"
end

