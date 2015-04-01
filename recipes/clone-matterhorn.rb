# Cookbook Name:: mh-opsworks-recipes
# Recipe:: clone-matterhorn

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
git_data = node[:deploy][:matterhorn][:scm]

include_recipe 'mh-opsworks-recipes::install-deploy-key'

repo_url = git_repo_url(git_data)

directory matterhorn_repo_root do
  owner 'matterhorn'
  group 'matterhorn'
  mode '755'
end

git 'Clone matterhorn' do
  repository repo_url
  revision git_data[:revision]
  destination matterhorn_repo_root
  user 'matterhorn'
  group 'matterhorn'
end
