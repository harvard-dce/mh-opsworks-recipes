# Cookbook Name:: oc-opsworks-recipes
# Recipe:: deploy-admin

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

using_local_distribution = is_using_local_distribution?

# S3 file archive service
region = node.fetch(:region, 'us-east-1')
s3_file_archive_bucket_name = get_s3_file_archive_bucket_name
s3_file_archive_enabled = !s3_file_archive_bucket_name.to_s.empty?
s3_file_archive_course_list = get_s3_file_archive_course_list
# S3 file archive service

# IBM Watson service credentials
ibm_watson_user_info = get_ibm_watson_user_info
ibm_watson_username = ibm_watson_user_info[:user]
ibm_watson_psw = ibm_watson_user_info[:pass]
ibm_watson_transcript_bucket = get_ibm_watson_transcript_bucket_name

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

live_monitor_url = node.fetch(
  :live_monitor_url, 'rtmp://example.com/live/#{caName}-presenter.delivery.stream-960x270_1_200@xyz'
)

live_streaming_url = get_live_streaming_url
live_stream_name = get_live_stream_name
distribution = using_local_distribution ? 'download' : 'aws.s3'

# LDAP credentials
ldap_conf = get_ldap_conf
ldap_enabled = ldap_conf[:enabled]
ldap_url = ldap_conf[:url]
ldap_userdn = ldap_conf[:userdn]
ldap_psw = ldap_conf[:pass]

# Publish to 1.x/migration settings
publish_1x_conf = get_publish_1x_conf
publish_1x_enabled = publish_1x_conf[:enabled] 
publish_1x_engage_url = publish_1x_conf[:engage_url] 
admin_1x_url = publish_1x_conf[:admin_url] 

auth_host = node.fetch(:auth_host, 'example.com')
auth_redirect_location = node.fetch(:auth_redirect_location, 'http://example.com/some/url')
auth_activated = node.fetch(:auth_activated, 'true')
auth_key = node.fetch(:auth_key, '')

# OPC-149 other oc host for pub list merge
# The ignore_flag default value signals the config consumer
# That the value for the config was not intentionally set and should
# be ignored.
ignore_flag = 'IGNORE_ME'
other_oc_host = node.fetch(:other_oc_host, ignore_flag)
other_oc_prefother_series = node.fetch(:other_oc_prefother_series, ignore_flag)
other_oc_preflocal_series = node.fetch(:other_oc_preflocal_series, ignore_flag)

git_data = node[:deploy][:opencast][:scm]

public_engage_hostname = get_public_engage_hostname
public_admin_hostname = get_public_admin_hostname_on_admin
private_hostname = node[:opsworks][:instance][:private_dns_name]

activemq_bind_host = private_hostname 

database_connection = get_database_connection

repo_url = git_repo_url(git_data)

include_recipe "oc-opsworks-recipes::create-opencast-directories"

allow_opencast_user_to_restart_daemon_via_sudo

deploy_action = get_deploy_action

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
    maven_build_for(:admin, most_recent_deploy)

    # Copy in the configs as distributed in the git repo.
    # Some services will be further tweaked by templates
    copy_files_into_place_for(:admin, most_recent_deploy)
#    copy_dce_configs(most_recent_deploy)

    copy_workflows_into_place_for_admin(most_recent_deploy)

    install_init_scripts(most_recent_deploy, opencast_repo_root)
    install_opencast_log_configuration(most_recent_deploy)
    install_opencast_log_management
    install_multitenancy_config(most_recent_deploy, public_admin_hostname, public_engage_hostname)
    install_elasticsearch_index_config(most_recent_deploy,'adminui')
    install_elasticsearch_index_config(most_recent_deploy,'externalapi')
#    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy)
    install_default_tenant_config(most_recent_deploy, public_admin_hostname, private_hostname)
#    install_auth_service(
#      most_recent_deploy, auth_host, auth_redirect_location, auth_key, auth_activated
#    )
    install_live_streaming_service_config(most_recent_deploy, live_stream_name, live_streaming_url, distribution)
    if ldap_enabled
      install_ldap_config(most_recent_deploy, ldap_url, ldap_userdn, ldap_psw)
    end
    install_publish_1x_service_config(most_recent_deploy, publish_1x_enabled, publish_1x_engage_url)
#    # Admin Specific
    install_otherpubs_service_config(most_recent_deploy, opencast_repo_root, auth_host, other_oc_host, other_oc_prefother_series, other_oc_preflocal_series)
    install_otherpubs_service_series_impl_config(most_recent_deploy)
    install_aws_s3_file_archive_service_config(most_recent_deploy, region, s3_file_archive_bucket_name, s3_file_archive_enabled, s3_file_archive_course_list)
    # OPC-224 (only used during migration)
    install_ingest_1x_config(most_recent_deploy, s3_file_archive_bucket_name, admin_1x_url)
    install_ibm_watson_transcription_service_config(most_recent_deploy, ibm_watson_username, ibm_watson_psw)
    unless ibm_watson_transcript_bucket.nil? or ibm_watson_transcript_bucket.empty?
      setup_transcript_result_sync_to_s3(shared_storage_root, ibm_watson_transcript_bucket)
    end
    install_published_event_details_email(most_recent_deploy, public_engage_hostname)

    if using_local_distribution
      update_workflows_for_local_distribution(most_recent_deploy)
    end

    # ADMIN SPECIFIC
    initialize_database(most_recent_deploy)
    # /ADMIN SPECIFIC

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
        capture_agent_monitor_url: capture_agent_monitor_url,
        live_monitor_url: live_monitor_url,
        job_maxload: nil,
        stack_name: stack_name,
        workspace_cleanup_period: 86400,
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
