# Cookbook Name:: mh-opsworks-recipes
# Recipe:: deploy-admin

::Chef::Recipe.send(:include, MhOpsworksRecipes::GitHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
local_workspace_root = node.fetch(
  :local_workspace_root, '/var/matterhorn-workspace'
)

log_directory = node.fetch(
  :matterhorn_log_directory, '/var/log/matterhorn'
)
capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)
rest_auth_info = node.fetch(
  :rest_auth, {
    user: 'user',
    pass: 'pass'
  }
)
admin_user_info = node.fetch(
  :admin_auth, {
    user: 'admin',
    pass: 'password'
  }
)
wowza_host = node.fetch(
  :wowza_host, 'mh-wowza'
)
git_data = node[:deploy][:matterhorn][:scm]
(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first
(private_engage_hostname, engage_attributes) = node[:opsworks][:layers][:engage][:instances].first

default_email_sender = node.fetch(:default_email_sender, 'no-reply@localhost')

engage_hostname = ''
if engage_attributes
  engage_hostname = engage_attributes[:public_dns_name]
end

admin_hostname = ''
if admin_attributes
  admin_hostname = admin_attributes[:public_dns_name]
end


database_connection = node[:deploy][:matterhorn][:database]

storage_info = node.fetch(
  :storage, {
    export_root: '/var/tmp',
    network: '10.0.0.0/8',
    layer_shortname: 'storage'
  }
)

repo_url = git_repo_url(git_data)

[
  local_workspace_root,
  log_directory,
  storage_info[:export_root],
  storage_info[:export_root] + '/archive',
].each do |matterhorn_directory|
  directory matterhorn_directory do
    owner 'matterhorn'
    group 'matterhorn'
    mode '755'
  end
end

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
    execute %Q|cd #{most_recent_deploy} && git submodule update --remote --init --recursive|

    install_init_scripts(most_recent_deploy, matterhorn_repo_root)
    install_matterhorn_conf(most_recent_deploy, matterhorn_repo_root, 'admin')
    install_multitenancy_config(most_recent_deploy, admin_hostname, engage_hostname)
    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy, default_email_sender)
    install_logging_config(most_recent_deploy)
    copy_files_into_place_for(:admin, most_recent_deploy)

    template %Q|#{most_recent_deploy}/etc/config.properties| do
      source 'config.properties.erb'
      owner 'matterhorn'
      group 'matterhorn'
      variables({
        matterhorn_backend_http_port: 8080,
        hostname: admin_hostname,
        local_workspace_root: local_workspace_root,
        export_root: storage_info[:export_root],
        admin_url: "http://#{admin_hostname}",
        admin_hostname: admin_hostname,
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        wowza_host: wowza_host,
        database: database_connection
      })
    end

    maven_build_for(:admin, most_recent_deploy)
  end
end
