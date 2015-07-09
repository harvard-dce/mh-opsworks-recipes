# Cookbook Name:: mh-opsworks-recipes
# Recipe:: deploy-admin

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
local_workspace_root = get_local_workspace_root
storage_info = get_storage_info
rest_auth_info = get_rest_auth_info
admin_user_info = get_admin_user_info

capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)

auth_host = node.fetch(
  :auth_host, 'http://example.com'
)

auth_activated = node.fetch(
  :auth_activated, 'true'
)

wowza_host = node.fetch(
  :wowza_host, 'mh-wowza'
)
git_data = node[:deploy][:matterhorn][:scm]
(private_engage_hostname, engage_attributes) = node[:opsworks][:layers][:engage][:instances].first

public_engage_hostname = ''
if engage_attributes
  public_engage_hostname = engage_attributes[:public_dns_name]
end

admin_hostname = hostname = node[:opsworks][:instance][:public_dns_name]

database_connection = node[:deploy][:matterhorn][:database]

repo_url = git_repo_url(git_data)

include_recipe "mh-opsworks-recipes::create-matterhorn-directories"

deploy_revision matterhorn_repo_root do
  repo repo_url
  revision git_data.fetch(:revision, 'master')
  enable_submodules true

  user 'matterhorn'
  group 'matterhorn'

  migrate false
  symlinks({})
  create_dirs_before_symlink([])
  purge_before_symlink([])
  symlink_before_migrate({})
  keep_releases 10
  action :deploy

  before_symlink do
    most_recent_deploy = path_to_most_recent_deploy(new_resource)
    execute 'update submodules' do
      command %Q|cd #{most_recent_deploy} && git submodule update --remote --init --recursive|
      retries 5
      retry_delay 5
    end
    maven_build_for(:admin, most_recent_deploy)

    install_init_scripts(most_recent_deploy, matterhorn_repo_root)
    install_matterhorn_conf(most_recent_deploy, matterhorn_repo_root, 'admin')
    install_multitenancy_config(most_recent_deploy, admin_hostname, public_engage_hostname)
    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy)
    install_logging_config(most_recent_deploy)
    copy_files_into_place_for(:admin, most_recent_deploy)
    install_auth_service(most_recent_deploy, auth_host, auth_activated)

    template %Q|#{most_recent_deploy}/etc/config.properties| do
      source 'config.properties.erb'
      owner 'matterhorn'
      group 'matterhorn'
      variables({
        matterhorn_backend_http_port: 8080,
        hostname: hostname,
        local_workspace_root: local_workspace_root,
        export_root: storage_info[:export_root],
        admin_url: "http://#{admin_hostname}",
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        wowza_host: wowza_host,
        database: database_connection,
        engage_hostname: public_engage_hostname
      })
    end
  end
end
