# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-matterhorn-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

[
  get_local_workspace_root,
  get_log_directory,
  get_storage_info[:export_root],
  get_storage_info[:export_root] + '/archive',
].each do |matterhorn_directory|
  directory matterhorn_directory do
    owner 'matterhorn'
    group 'matterhorn'
    mode '755'
  end
end
