# Cookbook Name:: oc-opsworks-recipes
# Recipe:: exec-dist-upgrade

::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

ruby_block 'perform apt-get dist-upgrade' do
  block do
    command = 'apt-get -y dist-upgrade'
    Chef::Log.info command
    execute_command(command)
  end
end
