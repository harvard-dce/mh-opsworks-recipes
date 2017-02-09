# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-deploy-key

git_data = node[:deploy][:opencast][:scm]

ssh_key = git_data.fetch(:ssh_key, '')

if ! git_data[:ssh_key].empty?
  file '/home/opencast/.ssh/id_rsa' do
    owner 'opencast'
    group 'opencast'
    content git_data[:ssh_key]
    mode '0600'
  end

  file '/home/opencast/.ssh/config' do
    owner 'opencast'
    group 'opencast'
    content %q|
Host *
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
  StrictHostKeyChecking no
    |
    mode '0600'
  end
end
