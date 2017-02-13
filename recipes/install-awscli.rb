# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-awscli

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

if on_aws?
  include_recipe "oc-opsworks-recipes::update-package-repo"
  install_package('python-pip')
  awscli_version = node.fetch(:awscli_version, '1.10.5')

  execute 'install awscli' do
    command %Q|pip install awscli==#{awscli_version}|
    retries 5
    retry_delay 10
    timeout 300
  end
end
