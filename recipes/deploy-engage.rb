# Cookbook Name:: oc-opsworks-recipes
# Recipe:: deploy-engage

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

opencast_repo_root = node[:opencast_repo_root]
local_workspace_root = get_local_workspace_root
storage_info = get_storage_info
shared_storage_root = get_shared_storage_root
rest_auth_info = get_rest_auth_info
admin_user_info = get_admin_user_info
stack_name = stack_shortname

capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

cloudfront_url = get_cloudfront_url
live_streaming_url = get_live_streaming_url
live_stream_name = get_live_stream_name

auth_host = node.fetch(:auth_host, 'example.com')
auth_redirect_location = node.fetch(:auth_redirect_location, 'http://example.com/some/url')
auth_activated = node.fetch(:auth_activated, 'true')
auth_key = node.fetch(:auth_key, '')

## Engage specific
user_tracking_authhost = node.fetch(
  :user_tracking_authhost, 'http://example.com'
)
# S3 distribution service
region = node.fetch(:region, 'us-east-1')
s3_distribution_bucket_name = get_s3_distribution_bucket_name
## /Engage specific

git_data = node[:deploy][:opencast][:scm]
public_engage_hostname = get_public_engage_hostname_on_engage
private_hostname = node[:opsworks][:instance][:private_dns_name]
private_admin_hostname = get_private_admin_hostname

activemq_bind_host = private_admin_hostname 

public_admin_hostname = get_public_admin_hostname

hostname = node[:opsworks][:instance][:hostname]

database_connection = get_database_connection

repo_url = git_repo_url(git_data)

include_recipe "oc-opsworks-recipes::create-opencast-directories"

allow_opencast_user_to_restart_daemon_via_sudo

deploy_action = get_deploy_action

newrelic_app_name = alarm_name_prefix

deploy_revision "opencast" do
  deploy_to opencast_repo_root
  repo repo_url
  revision git_data.fetch(:revision, 'master')

  user 'opencast'
  group 'opencast'

  migrate false
  symlinks({})
  create_dirs_before_symlink([])
  purge_before_symlink([])
  symlink_before_migrate({})
  keep_releases 10
  action deploy_action

  before_symlink do
    most_recent_deploy = path_to_most_recent_deploy(new_resource)
    maven_build_for(:presentation, most_recent_deploy)

    # Copy in the configs as distributed in the git repo
    # Some services will be further tweaked by templates
#    copy_files_into_place_for(:engage, most_recent_deploy)
#    copy_dce_configs(most_recent_deploy)

    install_init_scripts(most_recent_deploy, opencast_repo_root)
#    install_opencast_conf(most_recent_deploy, opencast_repo_root, 'engage')
    install_opencast_log_configuration(most_recent_deploy)
    install_opencast_log_management
    install_multitenancy_config(most_recent_deploy, public_admin_hostname, public_engage_hostname)
#    remove_felix_fileinstall(most_recent_deploy)
#    install_smtp_config(most_recent_deploy)
    install_default_tenant_config(most_recent_deploy, public_engage_hostname, private_hostname)
    install_auth_service(
      most_recent_deploy, auth_host, auth_redirect_location, auth_key, auth_activated
    )
#    install_live_streaming_service_config(most_recent_deploy, live_stream_name)
#    install_published_event_details_email(most_recent_deploy, public_engage_hostname)
#    configure_newrelic(most_recent_deploy, newrelic_app_name, :engage)

    # ENGAGE SPECIFIC
    set_service_registry_dispatch_interval(most_recent_deploy)
#    configure_usertracking(most_recent_deploy, user_tracking_authhost)
#    install_otherpubs_service_config(most_recent_deploy, opencast_repo_root, auth_host)
#    install_otherpubs_service_series_impl_config(most_recent_deploy)
#    install_aws_s3_distribution_service_config(most_recent_deploy, region, s3_distribution_bucket_name)
    # /ENGAGE SPECIFIC

#    if using_local_distribution?
#      update_properties_files_for_local_distribution(most_recent_deploy)
#    end

    template %Q|#{most_recent_deploy}/etc/custom.properties| do
      source 'custom.properties.erb'
      owner 'opencast'
      group 'opencast'
      variables({
        opencast_backend_http_port: 8080,
        hostname: private_hostname,
        local_workspace_root: local_workspace_root,
        shared_storage_root: shared_storage_root,
        admin_url: "http://#{public_admin_hostname}",
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        database: database_connection,
        engage_hostname: public_engage_hostname,
        cloudfront_url: cloudfront_url,
        s3_distribution_bucket_name: s3_distribution_bucket_name,
        capture_agent_monitor_url: capture_agent_monitor_url,
        live_streaming_url: live_streaming_url,
        job_maxload: nil,
        stack_name: stack_name,
        activemq_bind_host: activemq_bind_host
      })
    end
  end
end

include_recipe 'oc-opsworks-recipes::register-opencast-to-boot'

unless node[:dont_start_opencast_automatically]
  service 'opencast' do
    action :start
    supports restart: true, start: true, stop: true, status: true
  end
end

include_recipe "oc-opsworks-recipes::monitor-opencast-daemon"
