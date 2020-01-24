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

# Configuration for searching transcripts
search_content_index_url = node.fetch(:transcript_search_endpoint, '')
search_content_lambda_name = node.fetch(:transcript_index_function, '')
search_content_enabled = ! search_content_index_url.empty? && ! search_content_lambda_name.empty? 
## /all-in-one specific

# S3 file archive service, also needs region
s3_file_archive_bucket_name = get_s3_file_archive_bucket_name
s3_file_archive_enabled = !s3_file_archive_bucket_name.to_s.empty?
s3_file_archive_course_list = get_s3_file_archive_course_list

# IBM Watson service credentials
ibm_watson_credentials = get_ibm_watson_credentials
ibm_watson_api_key = ibm_watson_credentials[:api_key]
ibm_watson_username = ibm_watson_credentials[:user]
ibm_watson_psw = ibm_watson_credentials[:pass]

# OPC-446 get helix googlesheet service config
helix_googlesheets_config = get_helix_googlesheet_config
helix_googlesheets_cred = helix_googlesheets_config[:cred]
helix_googlesheets_defaultdur_min = helix_googlesheets_config[:defaultduration_min]
helix_enabled = helix_googlesheets_config[:enabled]
helix_token = helix_googlesheets_config[:token]
helix_sheet_id = helix_googlesheets_config[:helix_sheet_id]

capture_agent_monitor_url = node.fetch(
  :capture_agent_monitor_url, 'http://example.com/monitor_url'
)

live_monitor_url = node.fetch(
  :live_monitor_url, 'http://example.com/monitor_url'
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
# The ignore-flag default value signals the config consumer
# That the value for the config was not intentionally set and should
# be ignored.
ignore_flag = 'IGNORE_ME'
other_oc_host = node.fetch(:other_oc_host, ignore_flag)
other_oc_prefother_series = node.fetch(:other_oc_prefother_series, ignore_flag)
other_oc_preflocal_series = node.fetch(:other_oc_preflocal_series, ignore_flag)
bug_report_email = node.fetch(:bug_report_email, "no_email_set")

git_data = node[:deploy][:opencast][:scm]


activemq_bind_host = private_hostname 

database_connection = get_database_connection

repo_url = git_repo_url(git_data)

include_recipe "oc-opsworks-recipes::create-opencast-directories"

allow_opencast_user_to_restart_daemon_via_sudo

deploy_action = get_deploy_action

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
    install_opencast_log_configuration(most_recent_deploy)
    install_opencast_log_management
    install_multitenancy_config(most_recent_deploy, public_hostname, public_hostname)
    install_elasticsearch_index_config(most_recent_deploy,'adminui')
    install_elasticsearch_index_config(most_recent_deploy,'externalapi')
#    remove_felix_fileinstall(most_recent_deploy)
    install_smtp_config(most_recent_deploy)
    install_default_tenant_config(most_recent_deploy, public_hostname, private_hostname)
    install_auth_service(
      most_recent_deploy, auth_host, auth_redirect_location, auth_key, auth_activated, ldap_url, ldap_userdn, ldap_psw 
    )
    install_live_streaming_service_config(most_recent_deploy, live_stream_name, live_streaming_url, distribution)
    if ldap_enabled
      install_ldap_config(most_recent_deploy, ldap_url, ldap_userdn, ldap_psw)
    end
    install_publish_1x_service_config(most_recent_deploy, publish_1x_enabled, publish_1x_engage_url)
    install_otherpubs_service_config(most_recent_deploy, opencast_repo_root, auth_host, other_oc_host, other_oc_prefother_series, other_oc_preflocal_series, bug_report_email)
    install_otherpubs_service_series_impl_config(most_recent_deploy)
    install_helix_googlesheets_service_config(most_recent_deploy, local_workspace_root, helix_googlesheets_cred, helix_googlesheets_defaultdur_min, helix_enabled, helix_token, helix_sheet_id)
    install_bug_report_email(most_recent_deploy, public_hostname)
    install_aws_s3_file_archive_service_config(most_recent_deploy, region, s3_file_archive_bucket_name, s3_file_archive_enabled, s3_file_archive_course_list)
    # OPC-224 (only used during migration)
    install_ingest_1x_config(most_recent_deploy, s3_file_archive_bucket_name, admin_1x_url)
    install_ibm_watson_transcription_service_config(most_recent_deploy, ibm_watson_api_key, ibm_watson_username, ibm_watson_psw)
    install_published_event_details_email(most_recent_deploy, public_hostname)
    # f/OPC-344-notify-ca
    # External Capture Agent Sync service
    install_capture_agent_sync_config(most_recent_deploy)
#
#    # all-in-one SPECIFIC
    initialize_database(most_recent_deploy)

#    configure_usertracking(most_recent_deploy, user_tracking_authhost)
    install_aws_s3_distribution_service_config(most_recent_deploy, enable_s3, region, s3_distribution_bucket_name, s3_distribution_base_url)
    install_search_content_service_config(most_recent_deploy, search_content_enabled, region, s3_distribution_bucket_name, stack_name, search_content_index_url, search_content_lambda_name)
#    install_opencast_images_properties(most_recent_deploy)
    # OPC-139 Oauth config (for Engage)
    install_oauthconsumerdetails_service_config(most_recent_deploy)

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
        rest_auth: rest_auth_info,
        admin_auth: admin_user_info,
        database: database_connection,
        engage_hostname: public_hostname,
        capture_agent_monitor_url: capture_agent_monitor_url,
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
