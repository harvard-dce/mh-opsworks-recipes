# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-host-based-configurations

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)

opencast_repo_root = node[:opencast_repo_root]

production_deploy_root = opencast_repo_root + '/current'

public_engage_hostname = get_public_engage_hostname
public_engage_protocol = get_public_engage_protocol
public_admin_hostname = get_public_admin_hostname
public_admin_protocol = get_public_admin_protocol

if File.directory?(production_deploy_root)
  # This is being run during the config lifecycle after a successful deploy,
  # so everytime a node goes online or off and right before deployment.
  # We only care about the fact that it runs before a node changes its online state

  install_multitenancy_config(production_deploy_root, public_admin_hostname, public_admin_protocol, public_engage_hostname, public_engage_protocol)

end
