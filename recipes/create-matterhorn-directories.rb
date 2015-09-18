# Cookbook Name:: mh-opsworks-recipes
# Recipe:: create-matterhorn-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

[
  get_local_workspace_root,
  get_log_directory,
  get_shared_storage_root + '/inbox',
  get_shared_storage_root + '/inbox-archive-retrieve',
  get_shared_storage_root + '/inbox-hold-for-append',
  get_shared_storage_root + '/inbox-republish',
  get_shared_storage_root + '/archive'
].each do |matterhorn_directory|
  directory matterhorn_directory do
    owner 'matterhorn'
    group 'matterhorn'
    mode '755'
    recursive true
  end
end
