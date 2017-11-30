# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-yourkit

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

opencast_repo_root = node[:opencast_repo_root]
shared_assets_bucket = get_shared_asset_bucket_name
agent_url = "https://s3.amazonaws.com/#{shared_assets_bucket}/libyjpagent.so"
yourkit_dir = "#{opencast_repo_root}/yourkit"
agent_filepath = "#{yourkit_dir}/libyjpagent.so"

directory yourkit_dir do
  owner 'opencast'
  group 'opencast'
  mode '0755'
end

remote_file agent_filepath do
  source agent_url
  action :create_if_missing
  owner 'root'
  group 'root'
  mode '0644'
end

