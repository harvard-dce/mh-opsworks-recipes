# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-opencast-directories

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

[
  get_local_workspace_root,
  get_log_directory,
  get_shared_storage_root + '/inbox',
  get_shared_storage_root + '/inbox-archive-retrieve',
  get_shared_storage_root + '/inbox-hold-for-append',
  get_shared_storage_root + '/inbox-republish',
  get_shared_storage_root + '/inbox-republish-trim',
  get_shared_storage_root + '/archive',
  '/var/run/opencast',
  '/var/lock/opencast'
].each do |opencast_directory|
  directory opencast_directory do
    owner 'opencast'
    group 'opencast'
    mode '755'
    recursive true
  end
end

# create path for nginx to buffer large uploads
directory get_nginx_body_temp_path do
  action :create
  owner 'www-data'
  group 'admin'
  mode '755'
  recursive true
end

