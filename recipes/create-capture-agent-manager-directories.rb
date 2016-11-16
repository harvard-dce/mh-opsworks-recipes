# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-python-manager-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

usr_name = get_capture_agent_manager_usr_name

[
  %Q|home/#{usr_name}/sites|,
  %Q|home/#{usr_name}/db|,
  %Q|home/#{usr_name}/logs|
].each do |capture_agent_manager_directory|
  directory capture_agent_manager_directory do
    owner usr_name
    group usr_name
    mode "755"
    recursive true
  end
end
