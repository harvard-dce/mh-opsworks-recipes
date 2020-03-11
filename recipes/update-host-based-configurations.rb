# Cookbook Name:: oc-opsworks-recipes
# Recipe:: update-host-based-configurations

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)

opencast_repo_root = node[:opencast_repo_root]

production_deploy_root = opencast_repo_root + '/current'

public_engage_hostname = get_public_engage_hostname
public_admin_hostname = get_public_admin_hostname
zoom_ingester_url = get_zoom_ingester_url

if File.directory?(production_deploy_root)
  # This is being run during the config lifecycle after a successful deploy,
  # so everytime a node goes online or off and right before deployment.
  # We only care about the fact that it runs before a node changes its online state

  install_multitenancy_config(production_deploy_root, public_admin_hostname, public_engage_hostname, zoom_ingester_url)

  ruby_block "update engage hostname" do
    block do
      editor = Chef::Util::FileEdit.new(production_deploy_root + '/etc/config.properties')
      editor.search_file_replace_line(
        /edu\.harvard\.dce\.external\.host=/,
        "edu.harvard.dce.external.host=#{public_engage_hostname}"
      )
      editor.search_file_replace_line(
        /org\.opencastproject\.file\.repo\.url=/,
        "org.opencastproject.file.repo.url=http://#{public_admin_hostname}"
      )
      editor.write_file
    end
  end
end
