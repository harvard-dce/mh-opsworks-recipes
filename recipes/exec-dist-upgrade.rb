# Cookbook Name:: oc-opsworks-recipes
# Recipe:: exec-dist-upgrade

::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "oc-opsworks-recipes::update-package-repo"

execute "dist upgrade" do
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
  command %Q|apt-get -y dist-upgrade|
  retries 5
  retry_delay 15
  timeout 180
end

include_recipe "oc-opsworks-recipes::clean-up-package-cache"
