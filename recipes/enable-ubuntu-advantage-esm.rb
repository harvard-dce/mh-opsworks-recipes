# Cookbook Name:: oc-opsworks-recipes
# Recipe:: enable-ubuntu-advantage-esm

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
install_package('apt apt-transport-https apt-utils libapt-inst1.5 libapt-pkg4.12 ubuntu-advantage-tools')

esm_token = node.fetch(:ubuntu_advantage_esm, {})
return if esm_token.empty? || !esm_token[:token]

execute "enable esm" do
  command %Q|ua attach #{esm_token[:token]}|
  retries 5
  retry_delay 15
end
