# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-awscli

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-python"

if on_aws?
  awscli_version = node.fetch(:awscli_version, '1.20.6')

  execute 'install awscli' do
    command %Q|/usr/bin/python3 -m pip install awscli==#{awscli_version}|
    retries 5
    retry_delay 10
    timeout 300
  end
end
