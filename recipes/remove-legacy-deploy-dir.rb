# Cookbook Name:: mh-opsworks-recipes
# Recipe:: remove-legacy-deploy-dir

legacy_deploy_root = node.fetch(:legacy_deploy_root, '/opt/matterhorn')

['/releases', '/shared'].each do |subdir|
  directory %Q|#{legacy_deploy_root}#{subdir}| do
    recursive true
    action :delete
    # Delete only if it's there and a directory
    only_if %Q|[ -e "#{legacy_deploy_root}#{subdir}" ] && [ -d "#{legacy_deploy_root}#{subdir}" ]|
  end
end

link %Q|#{legacy_deploy_root}/current| do
  action :delete
  # Delete only if it's a symlink
  only_if %Q|[ -L "#{legacy_deploy_root}/current" ]|
end
