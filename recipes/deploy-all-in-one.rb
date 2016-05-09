# Cookbook Name:: mh-opsworks-recipes
# Recipe:: deploy-all-in-one

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

matterhorn_repo_root = node[:matterhorn_repo_root]
local_workspace_root = get_local_workspace_root
storage_info = get_storage_info
shared_storage_root = get_shared_storage_root
rest_auth_info = get_rest_auth_info
admin_user_info = get_admin_user_info

capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)

## all-in-one specific
user_tracking_authhost = node.fetch(
  :user_tracking_authhost, 'http://example.com'
)
# S3 distribution service
region = node.fetch(:region, 'us-east-1')
s3_distribution_bucket_name = get_s3_distribution_bucket_name
## /all-in-one specific

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

cloudfront_url = get_cloudfront_url
live_streaming_url = get_live_streaming_url
live_stream_name = get_live_stream_name

auth_host = node.fetch(:auth_host, 'example.com')
auth_redirect_location = node.fetch(:auth_redirect_location, 'http://example.com/some/url')
auth_activated = node.fetch(:auth_activated, 'true')

git_data = node[:deploy][:matterhorn][:scm]

public_hostname = node[:opsworks][:instance][:public_dns_name]
private_hostname = node[:opsworks][:instance][:private_dns_name]

database_connection = get_database_connection

repo_url = git_repo_url(git_data)

include_recipe "mh-opsworks-recipes::create-matterhorn-directories"

allow_matterhorn_user_to_restart_daemon_via_sudo

deploy_action = get_deploy_action

newrelic_app_name = alarm_name_prefix

deploy_revision "matterhorn" do
  deploy_to matterhorn_repo_root
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
  action deploy_action

  before_symlink do
    most_recent_deploy = path_to_most_recent_deploy(new_resource)
    maven_build_for(:allinone, most_recent_deploy)

    # Copy in the configs as distributed in the git repo.
    # Some services will be further tweaked by templates
    copy_files_into_place_for(:admin, most_recent_deploy)
    copy_files_into_place_for(:worker, most_recent_deploy)
    copy_files_into_place_for(:engage, most_recent_deploy)
    copy_configs_for_load_service(most_recent_deploy)
    copy_services_into_place(most_recent_deploy)

    copy_workflows_into_place_for_admin(most_recent_deploy)

    install_init_scripts(most_recent_deploy, matterhorn_repo_root)
    install_matterhorn_conf(most_recent_deploy, matterhorn_repo_root, 'all-in-one')
    install_matterhorn_log_management
    install_multitenancy_config(most_recent_deploy, public_hostname, public_hostname)
    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy)
    install_auth_service(
      most_recent_deploy, auth_host, auth_redirect_location, auth_activated
    )
    install_live_streaming_service_config(most_recent_deploy, live_stream_name)
    install_otherpubs_service_config(most_recent_deploy, matterhorn_repo_root, auth_host)
    install_published_event_details_email(most_recent_deploy, public_hostname)
    configure_newrelic(most_recent_deploy, newrelic_app_name)

    # all-in-one SPECIFIC
    initialize_database(most_recent_deploy)

    configure_usertracking(most_recent_deploy, user_tracking_authhost)
    install_otherpubs_service_config(most_recent_deploy, matterhorn_repo_root, auth_host)
    install_aws_s3_distribution_service_config(most_recent_deploy, region, s3_distribution_bucket_name)
    install_matterhorn_images_properties(most_recent_deploy)
    # /all-in-one SPECIFIC

    if using_local_distribution?
      update_properties_files_for_local_distribution(most_recent_deploy)
    end

    template %Q|#{most_recent_deploy}/etc/config.properties| do
      source 'config.properties.erb'
      owner 'matterhorn'
      group 'matterhorn'
      variables({
        matterhorn_backend_http_port: 8080,
        hostname: private_hostname,
        local_workspace_root: local_workspace_root,
        shared_storage_root: shared_storage_root,
        admin_url: "http://#{public_hostname}",
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        database: database_connection,
        engage_hostname: public_hostname,
        cloudfront_url: cloudfront_url,
        s3_distribution_bucket_name: s3_distribution_bucket_name,
        capture_agent_monitor_url: capture_agent_monitor_url,
        live_streaming_url: live_streaming_url,
        job_maxload: nil,
      })
    end
  end
end

unless node[:dont_start_matterhorn_after_deploy]
  service 'matterhorn' do
    action :start
    supports restart: true, start: true, stop: true, status: true
  end
end

include_recipe "mh-opsworks-recipes::monitor-matterhorn-daemon"
