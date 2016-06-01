# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-python-manager-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

username = get_capture_agent_manager_usr_name

[
  %Q|home/#{username}/sites|,
  %Q|home/#{username}/sock|,
  %Q|home/#{username}/logs|
].each do |capture_agent_manager_directory|
  directory capture_agent_manager_directory do
    owner username
    group username
    mode "755"
    recursive true
  end
end
