# Cookbook Name:: mh-opsworks-recipes
# Recipe:: update-host-based-configurations

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]

production_deploy_root = matterhorn_repo_root + '/current'

(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first
(private_engage_hostname, engage_attributes) = node[:opsworks][:layers][:engage][:instances].first

public_engage_hostname = engage_hostname = ''
if engage_attributes
  engage_hostname = engage_attributes[:private_dns_name]
  public_engage_hostname = engage_attributes[:public_dns_name]
end

admin_hostname = ''
if admin_attributes
  admin_hostname = admin_attributes[:public_dns_name]
end

if File.directory?(production_deploy_root)
  # This is being run during the config lifecycle after a successful deploy,
  # so everytime a node goes online or off and right before deployment.
  # We only care about the fact that it runs before a node changes its online state

  install_multitenancy_config(production_deploy_root, admin_hostname, public_engage_hostname)

  ruby_block "update engage hostname" do
    block do
      editor = Chef::Util::FileEdit.new(production_deploy_root + '/etc/config.properties')
      editor.search_file_replace_line(
        /edu\.harvard\.dce\.external\.host=/,
        "edu.harvard.dce.external.host=#{engage_hostname}"
      )
      editor.search_file_replace_line(
        /org\.opencastproject\.file\.repo\.url=/,
        "org.opencastproject.file.repo.url=http://#{admin_hostname}"
      )
      editor.write_file
    end
  end
end
