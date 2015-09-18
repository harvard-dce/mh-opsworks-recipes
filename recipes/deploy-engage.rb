# Cookbook Name:: mh-opsworks-recipes
# Recipe:: deploy-engage

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
local_workspace_root = get_local_workspace_root
storage_info = get_storage_info
shared_storage_root = get_shared_storage_root
rest_auth_info = get_rest_auth_info
admin_user_info = get_admin_user_info
cloudfront_url = node[:cloudfront_url]
using_ssl_for_engage = node[:ssl]

capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

live_streaming_url = node.fetch(
  :live_streaming_url, 'rtmp://example.com/streaming_url'
)
live_streaming_suffix = node.fetch(:live_streaming_suffix, '')

auth_host = node.fetch(:auth_host, 'http://example.com')
auth_redirect_location = node.fetch(:auth_redirect_location, 'http://example.com/some/url')
auth_activated = node.fetch(:auth_activated, 'true')

## Engage specific
user_tracking_authhost = node.fetch(
  :user_tracking_authhost, 'http://example.com'
)
## /Engage specific

git_data = node[:deploy][:matterhorn][:scm]
(private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first

public_engage_hostname = node[:opsworks][:instance][:public_dns_name]
private_hostname = node[:opsworks][:instance][:private_dns_name]

admin_hostname = ''
if admin_attributes
  admin_hostname = admin_attributes[:public_dns_name]
end

hostname = node[:opsworks][:instance][:hostname]

database_connection = node[:deploy][:matterhorn][:database]

repo_url = git_repo_url(git_data)

include_recipe "mh-opsworks-recipes::create-matterhorn-directories"

allow_matterhorn_user_to_restart_daemon_via_sudo

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
    maven_build_for(:engage, most_recent_deploy)

    # Copy in the configs as distributed in the git repo
    # Some services will be further tweaked by templates
    copy_files_into_place_for(:engage, most_recent_deploy)
    copy_configs_for_load_service(most_recent_deploy)
    copy_services_into_place(most_recent_deploy)

    install_init_scripts(most_recent_deploy, matterhorn_repo_root)
    install_matterhorn_conf(most_recent_deploy, matterhorn_repo_root, 'engage')
    install_multitenancy_config(most_recent_deploy, admin_hostname, public_engage_hostname)
    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy)
    install_logging_config(most_recent_deploy)
    install_auth_service(
      most_recent_deploy, auth_host, auth_redirect_location, auth_activated
    )
    install_live_streaming_service_config(most_recent_deploy, live_streaming_suffix)

    # ENGAGE SPECIFIC
    #TODO - this should probably be checked into the repo
    set_service_registry_dispatch_interval(most_recent_deploy)
    configure_usertracking(most_recent_deploy, user_tracking_authhost)
    # /ENGAGE SPECIFIC

    template %Q|#{most_recent_deploy}/etc/config.properties| do
      source 'config.properties.erb'
      owner 'matterhorn'
      group 'matterhorn'
      variables({
        matterhorn_backend_http_port: 8080,
        hostname: private_hostname,
        local_workspace_root: local_workspace_root,
        shared_storage_root: shared_storage_root,
        admin_url: "http://#{admin_hostname}",
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        database: database_connection,
        engage_hostname: public_engage_hostname,
        cloudfront_url: cloudfront_url,
        capture_agent_monitor_url: capture_agent_monitor_url,
        live_streaming_url: live_streaming_url,
        using_ssl_for_engage: using_ssl_for_engage,
      })
    end
  end
end

execute "start matterhorn if it isn't already running" do
  user 'matterhorn'
  command "pgrep -u matterhorn java > /dev/null; if [ $? = 1 ]; then sudo /etc/init.d/matterhorn start; fi"
end
