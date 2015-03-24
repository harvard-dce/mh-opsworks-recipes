# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-deploy-key

matterhorn_repo_root = node[:matterhorn_repo_root]
git_data = node[:deploy][:matterhorn][:scm]

ssh_key = git_data.fetch(:ssh_key, '')

if ! git_data[:ssh_key].empty?
  file '/home/matterhorn/.ssh/id_rsa' do
    owner 'matterhorn'
    group 'matterhorn'
    content git_data[:ssh_key]
    mode '0600'
  end

  file '/home/matterhorn/.ssh/config' do
    owner 'matterhorn'
    group 'matterhorn'
    content %q|
Host *
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
  StrictHostKeyChecking no
    |
    mode '0600'
  end
end
