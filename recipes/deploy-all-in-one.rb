# Cookbook Name:: oc-opsworks-recipes
# Recipe:: deploy-all-in-one

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
Chef::Provider::Deploy::Revision.send(:include, MhOpsworksRecipes::DeployHelpers)

opencast_repo_root = node[:opencast_repo_root]
local_workspace_root = get_local_workspace_root
storage_info = get_storage_info
shared_storage_root = get_shared_storage_root
rest_auth_info = get_rest_auth_info
admin_user_info = get_admin_user_info
stack_name = stack_shortname

public_hostname = node[:opsworks][:instance][:public_dns_name]
private_hostname = node[:opsworks][:instance][:private_dns_name]

capture_agent_query_url = node.fetch(
  :capture_agent_query_url, 'http://example.com'
)

## all-in-one specific
user_tracking_authhost = node.fetch(
  :user_tracking_authhost, 'http://example.com'
)

using_local_distribution = is_using_local_distribution?

# S3 distribution service
enable_s3 = !using_local_distribution
region = node.fetch(:region, 'us-east-1')
s3_distribution_bucket_name = get_s3_distribution_bucket_name
s3_distribution_base_url=get_base_media_download_url(public_hostname)
## /all-in-one specific

# S3 file archive service, also needs the aws region
s3_file_archive_bucket_name = get_s3_file_archive_bucket_name

# IBM Watson service credentials
ibm_watson_user_info = get_ibm_watson_user_info
ibm_watson_username = ibm_watson_user_info[:user]
ibm_watson_psw = ibm_watson_user_info[:pass]

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

live_monitor_url = node.fetch(
  :live_monitor_url, 'http://example.com/monitor_url'
)

live_streaming_url = get_live_streaming_url
live_stream_name = get_live_stream_name

auth_host = node.fetch(:auth_host, 'example.com')
auth_redirect_location = node.fetch(:auth_redirect_location, 'http://example.com/some/url')
auth_activated = node.fetch(:auth_activated, 'true')
auth_key = node.fetch(:auth_key, '')

git_data = node[:deploy][:opencast][:scm]


activemq_bind_host = private_hostname 

database_connection = get_database_connection

repo_url = git_repo_url(git_data)

include_recipe "oc-opsworks-recipes::create-opencast-directories"

allow_opencast_user_to_restart_daemon_via_sudo

deploy_action = get_deploy_action

newrelic_app_name = alarm_name_prefix

# chef deploy resource
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
  keep_releases 5
  action deploy_action

  before_symlink do
    most_recent_deploy = path_to_most_recent_deploy(new_resource)
    maven_build_for(:allinone, most_recent_deploy)

    # Copy in the configs as distributed in the git repo.
    # Some services will be further tweaked by templates
    # TODO: these will need to be reworked and re-enabled as we incoporate our dce fork stuff
    copy_files_into_place_for(:admin, most_recent_deploy)
    copy_files_into_place_for(:worker, most_recent_deploy)
    copy_files_into_place_for(:engage, most_recent_deploy)
#    copy_dce_configs(most_recent_deploy)
    copy_workflows_into_place_for_admin(most_recent_deploy)

    install_init_scripts(most_recent_deploy, opencast_repo_root)
#    install_opencast_conf(most_recent_deploy, opencast_repo_root, 'all-in-one')
    install_opencast_log_configuration(most_recent_deploy)
    install_opencast_log_management
    install_multitenancy_config(most_recent_deploy, public_hostname, public_hostname)
    install_elasticsearch_index_config(most_recent_deploy,'adminui')
    install_elasticsearch_index_config(most_recent_deploy,'externalapi')
#    remove_felix_fileinstall(most_recent_deploy)
#    install_smtp_config(most_recent_deploy)
    install_default_tenant_config(most_recent_deploy, public_hostname, private_hostname)
    install_auth_service(
      most_recent_deploy, auth_host, auth_redirect_location, auth_key, auth_activated
    )
    install_live_streaming_service_config(most_recent_deploy, live_stream_name)
    install_otherpubs_service_config(most_recent_deploy, opencast_repo_root, auth_host)
    install_otherpubs_service_series_impl_config(most_recent_deploy)
#    install_aws_s3_file_archive_service_config(most_recent_deploy, region, s3_file_archive_bucket_name)
    install_ibm_watson_transcription_service_config(most_recent_deploy, ibm_watson_username, ibm_watson_psw)
    install_published_event_details_email(most_recent_deploy, public_hostname)
#    configure_newrelic(most_recent_deploy, newrelic_app_name, :admin)  # All in one installation will use admin newrelic key
#
#    # all-in-one SPECIFIC
    initialize_database(most_recent_deploy)

#    configure_usertracking(most_recent_deploy, user_tracking_authhost)
    install_aws_s3_distribution_service_config(most_recent_deploy, enable_s3, region, s3_distribution_bucket_name, s3_distribution_base_url)
#    install_opencast_images_properties(most_recent_deploy)
    # /all-in-one SPECIFIC

    if using_local_distribution
      update_workflows_for_local_distribution(most_recent_deploy)
    end

    template %Q|#{most_recent_deploy}/etc/custom.properties| do
      source 'custom.properties.erb'
      owner 'opencast'
      group 'opencast'
      variables({
        opencast_backend_http_port: 8080,
        hostname: private_hostname,
        local_workspace_root: local_workspace_root,
        shared_storage_root: shared_storage_root,
        admin_url: "http://#{public_hostname}",
        capture_agent_query_url: capture_agent_query_url,
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        database: database_connection,
        engage_hostname: public_hostname,
        capture_agent_monitor_url: capture_agent_monitor_url,
        live_streaming_url: live_streaming_url,
        live_monitor_url: live_monitor_url,
        job_maxload: nil,
        stack_name: stack_name,
        activemq_bind_host: activemq_bind_host
      })
    end
  end
end

unless node[:dont_start_opencast_after_deploy]
  service 'opencast' do
    action :start
    supports restart: true, start: true, stop: true, status: true
  end
end

include_recipe "oc-opsworks-recipes::monitor-opencast-daemon"
