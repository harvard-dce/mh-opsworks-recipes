require 'uri'
require 'mixlib/shellout'

module MhOpsworksRecipes
  module RecipeHelpers

    def execute_command(command)
      command = Mixlib::ShellOut.new(command)
      command.run_command
      command.error!
      command.stdout
    end

    def get_database_connection
      node[:deploy][:matterhorn][:database]
    end

    def get_memory_limit
      80
    end

    def install_package(name)
      #
      # Yes, I know about the "package" resource, but for some reason using a timeout
      # with it causes a compile-time error.
      #
      # We really want to be able to timeout and retry installs to get faster package
      # mirrors. This is an annoying quirk with the ubuntu package mirror repos.
      #
      execute "install #{name}" do
        environment 'DEBIAN_FRONTEND' => 'noninteractive'
        command %Q|apt-get install -y #{name}|
        retries 5
        retry_delay 15
        timeout 180
      end
    end

    def pin_package(name, version)
      apt_preference name do
        pin "version #{version}"
        pin_priority "700"
      end
    end

    def get_shared_asset_bucket_name
      node.fetch(:shared_asset_bucket_name, 'mh-opsworks-shared-assets')
    end

    def get_cluster_seed_bucket_name
      node.fetch(:cluster_seed_bucket_name, 'dce-deac-test-cluster-seeds')
    end

    def get_seed_file
      node.fetch(:cluster_seed_file, 'cluster_seed.tgz')
    end

    def on_aws?
      if node[:vagrant_environment] == true
        Chef::Log.info "deploying to a vagrant cluster"
        false
      else
        true
      end
    end

    def dev_or_testing_cluster?
      ['development', 'test'].include?(node[:cluster_env])
    end

    def engage_node?
      node[:opsworks][:instance][:hostname].match(/^engage/)
    end

    def admin_node?
      node[:opsworks][:instance][:hostname].match(/^admin/)
    end

    def monitoring_node?
      node[:opsworks][:instance][:hostname].match(/^monitoring\-master/)
    end

    def database_node?
      node[:opsworks][:instance][:hostname].match(/^(db-master|all-in-one|local-support)/)
    end

    def worker_node?
      node[:opsworks][:instance][:hostname].match(/^worker/)
    end

    def mh_node?
      engage_node? || admin_node? || worker_node?
    end

    def analytics_node?
      node[:opsworks][:instance][:hostname].match(/^analytics/)
    end

    def utility_node?
      node[:opsworks][:instance][:hostname].match(/^utility/)
    end

    def get_db_seed_file
      node.fetch(:db_seed_file, 'dce-config/docs/scripts/ddl/mysql5.sql')
    end

    def get_deploy_action
      valid_actions = [:deploy, :force_deploy, :rollback]
      requested_action = node.fetch(:deploy_action, :deploy).to_sym
      Chef::Log.info "requested_action: #{requested_action}"
      if valid_actions.include?(requested_action)
        requested_action
      else
        :deploy
      end
    end

    def install_nginx_logrotate_customizations
      cookbook_file "nginx-logrotate.conf" do
        path "/etc/logrotate.d/nginx"
        owner "root"
        group "root"
        mode "644"
      end
    end

    def nginx_log_root_dir
      node.fetch(:nginx_log_root_dir, '/var/log')
    end

    def get_live_stream_name
      node.fetch(:live_stream_name, '#{caName}-#{flavor}.stream-#{resolution}_1_200@')
    end

    def get_live_streaming_url
      node.fetch(:live_streaming_url, 'rtmp://example.com/streaming_url')
    end

    def get_public_engage_hostname_on_engage
      return node[:public_engage_hostname] if node[:public_engage_hostname]

      node[:opsworks][:instance][:public_dns_name]
    end

    def get_public_admin_hostname_on_admin
      return node[:public_admin_hostname] if node[:public_admin_hostname]

      node[:opsworks][:instance][:public_dns_name]
    end

    def get_public_admin_hostname
      return node[:public_admin_hostname] if node[:public_admin_hostname]

      (private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first

      admin_hostname = ''
      if admin_attributes
        admin_hostname = admin_attributes[:public_dns_name]
      end
      admin_hostname
    end

    def get_base_media_download_domain(engage_hostname)
      uri = URI(get_base_media_download_url(engage_hostname))
      uri.host
    end

    def get_base_media_download_url(engage_hostname)
      # engage_hostname is passed in because we don't have the engage instance
      # chef attributes when we're deploying the engage instance. The chef
      # attributes don't make it into the shared chef environment until the
      # node comes online.

      cloudfront_url = get_cloudfront_url
      base_media_download_url = ''

      if cloudfront_url && (! cloudfront_url.empty?)
        Chef::Log.info "Cloudfront url: #{cloudfront_url}"
        base_media_download_url = %Q|https://#{cloudfront_url}|
      else
        Chef::Log.info "s3 distribution: #{engage_hostname}"
        base_media_download_url = %Q|https://#{get_s3_distribution_bucket_name}.s3.amazonaws.com|
      end
      base_media_download_url
    end

    def get_public_engage_hostname
      return node[:public_engage_hostname] if node[:public_engage_hostname]

      (private_engage_hostname, engage_attributes) = node[:opsworks][:layers][:engage][:instances].first

      public_engage_hostname = ''
      if engage_attributes
        public_engage_hostname = engage_attributes[:public_dns_name]
      end
      public_engage_hostname
    end

    def get_public_engage_ip
      (private_engage_hostname, engage_attributes) = node[:opsworks][:layers][:engage][:instances].first
      engage_attributes[:ip]
    end

    def get_public_admin_ip
      (private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first
      admin_attributes[:ip]
    end

    def get_cloudfront_url
      node[:cloudfront_url]
    end

    def get_admin_user_info
      node.fetch(
        :admin_auth, {
          user: 'admin',
          pass: 'password'
        }
      )
    end

    def get_ibm_watson_user_info
      node.fetch(
        :ibm_watson_service_auth, {
          user: 'admin',
          pass: 'password'
        }
      )
    end

    def get_ibm_watson_transcript_bucket_name
      node[:ibm_watson_transcript_sync_bucket_name]
    end

    def get_s3_distribution_bucket_name
      node[:s3_distribution_bucket_name]
    end

    def get_s3_file_archive_bucket_name
      node[:s3_file_archive_bucket_name]
    end

    def topic_name
      stack_name = node[:opsworks][:stack][:name]
      stack_name.downcase.gsub(/[^a-z\d\-_]/,'_')
    end

    def calculate_disk_partition_metric_name(partition)
      if partition == '/'
        'SpaceFreeOnRootPartition'
      else
        metric_suffix = partition.gsub(/[^a-z\d]/,'_')
        "SpaceFreeOn#{metric_suffix}"
      end
    end

    def rds_name
      %Q|#{stack_shortname}-database|
    end

    def alarm_name_prefix
      hostname = node[:opsworks][:instance][:hostname]
      alarm_name_prefix = %Q|#{topic_name}_#{hostname}|
    end

    def stack_shortname
      stack_name = node[:opsworks][:stack][:name].gsub(/[^a-z\d\-]/,'-')
    end

    def stack_and_hostname
      alarm_name_prefix
    end

    def toggle_maintenance_mode_to(mode)
      rest_auth_info = get_rest_auth_info
      (private_admin_hostname, admin_attributes) = node[:opsworks][:layers][:admin][:instances].first
      hostname = ''

      hostname = node[:opsworks][:instance][:private_dns_name]

      if private_admin_hostname
        command = %Q|/usr/bin/curl -s --digest -u "#{rest_auth_info[:user]}:#{rest_auth_info[:pass]}" -H "X-Requested-Auth: Digest" -F host=http://#{hostname} -F maintenance=#{mode} http://#{private_admin_hostname}/services/maintenance|
        # Chef::Log.info "command: #{command}"
        execute "toggle maintenance mode to #{mode}" do
          user 'matterhorn'
          command command
          retries 5
          retry_delay 30
        end
      end
    end

    def get_rest_auth_info
      node.fetch(
        :rest_auth, {
          user: 'user',
          pass: 'pass'
        }
      )
    end

    def get_storage_info
      node.fetch(
        :storage, {
          shared_storage_root: '/var/tmp',
          export_root: '/var/tmp',
          network: '10.0.0.0/8',
          layer_shortname: 'storage'
        }
      )
    end

    def get_storage_hostname
      storage_info = get_storage_info

      if storage_info[:type] == 'external'
        storage_info[:nfs_server_host]
      else
        layer_shortname = storage_info[:layer_shortname]
        (storage_hostname, storage_available) = node[:opsworks][:layers][layer_shortname.to_sym][:instances].first

        storage_hostname
      end
    end

    def get_shared_storage_root
      storage_info = get_storage_info
      storage_info[:shared_storage_root] || storage_info[:export_root]
    end

    def get_local_workspace_root
      node.fetch(
        :local_workspace_root, '/var/matterhorn-workspace'
      )
    end

    def get_log_directory
      node.fetch(
        :matterhorn_log_directory, '/var/log/matterhorn'
      )
    end

    def allow_matterhorn_user_to_restart_daemon_via_sudo
      file '/etc/sudoers.d/matterhorn' do
        owner 'root'
        group 'root'
        content %Q|matterhorn ALL=NOPASSWD:/etc/init.d/matterhorn\n|
        mode '0600'
      end
    end

    def git_repo_url(git_data)
      git_user = git_data[:user]

      repo = ''
      if git_user
        # Using a repo in the form of "https://user:pass@repo_url"
        user = git_data[:user]
        password = git_data[:password]
        repo = git_data[:repository]
        fixed_repo = repo.gsub(/\Ahttps?:\/\//,'')
        repo = %Q|https://#{user}:#{password}@#{fixed_repo}|
      else
        # Using a repo with an SSH key, or with no auth
        repo = git_data[:repository]
      end
      repo
    end

    def get_elk_info
      stack_name = stack_shortname
      {
          'es_major_version' => '2.4',
          'es_repo_uri' => 'http://packages.elasticsearch.org/elasticsearch/2.x/debian',
          'es_cluster_name' => stack_name,
          'es_index_prefix' => "useractions-#{stack_name}",
          'es_data_path' => "/vol/elasticsearch_data",
          'es_enable_snapshots' => true,
          'logstash_major_version' => '1:2.4',
          'logstash_repo_uri' => 'http://packages.elasticsearch.org/logstash/2.4/debian',
          'logstash_tcp_port' => '5000',
          'logstash_stdout_output' => false,
          'kibana_major_version' => '4.6',
          'kibana_repo_uri' => 'https://packages.elastic.co/kibana/4.6/debian',
          'curator_major_version' => '3.5',
          'curator_repo_uri' => 'http://packages.elastic.co/curator/3/debian',
          'http_auth' => {},
          'http_ssl' => get_dummy_cert,
          'harvester_repo' => 'https://github.com/harvard-dce/dce-user-analytics.git',
          'harvester_release' => 'master',
          'zoom_key' => nil,
          'zoom_secret' => nil,
          'geolite2_db_archive' => 'GeoLite2-City_20171003.tar.gz'
      }.merge(node.fetch(:elk, {}))
    end

    def get_dummy_cert
      {
        # Dummy self-signed cert.
        certificate: "-----BEGIN CERTIFICATE-----\nMIIDvzCCAqegAwIBAgIJANg1Xye10w+RMA0GCSqGSIb3DQEBCwUAMHYxCzAJBgNV\nBAYTAlVTMQswCQYDVQQIDAJNQTESMBAGA1UEBwwJQ2FtYnJpZGdlMSAwHgYDVQQK\nDBdIYXJ2YXJkIERDRSBTZWxmLXNpZ25lZDEkMCIGA1UEAwwbc2VsZi1zaWduZWQu\nZGNlLmhhcnZhcmQuZWR1MB4XDTE1MDcxMzIwMzQyOFoXDTI1MDcxMDIwMzQyOFow\ndjELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAk1BMRIwEAYDVQQHDAlDYW1icmlkZ2Ux\nIDAeBgNVBAoMF0hhcnZhcmQgRENFIFNlbGYtc2lnbmVkMSQwIgYDVQQDDBtzZWxm\nLXNpZ25lZC5kY2UuaGFydmFyZC5lZHUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\nggEKAoIBAQCt36/OLrRa3vui1ns7ey67btL/AN6lw2scwO0iurKUw5vomfEqjhks\n04dsBKTheSjYH4UroKN9ubJeVIZ+FL3ewSVLVMLG10TSya1vm2J0xR3nrWnbL9uo\nz7lERmQSXzllr5PHj+q3aI3ewTXQk8Ic71NFGBGDcDBRPdWEzyqsfvFvMVACGUBH\nrDyWO4WBbLp3gzbwITnQhGXz+f9cha1IiBYrrbysDDuw81Fa2HEiDiA3ghGVR4q9\nDwVjpf1YpZyaMxRs28pUZ8Eu5gyfemznQIW1pRnyN2/77IZsFooMzQ+q0jxjjTzb\nuNoQSL+Gfpo5Rxvg+bR5+qyz4v07eFeRAgMBAAGjUDBOMB0GA1UdDgQWBBQQKYCF\n2ey1VaoiL0p10diP4nH7mjAfBgNVHSMEGDAWgBQQKYCF2ey1VaoiL0p10diP4nH7\nmjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAyHRUGjkwKbnJDKAT8\n9Lce8qNxEtuwz+87/YgM2rrXNkSN9WfrZNFsM2T5sCtC5hxzI/cK34e8Mlcejx3+\nBG7ioH+3qyanIVvqMWJ1UGliWZ3W3Ol20ZgPYrkQrWMZBQfTJGNZsu3qCrloy91s\nwXxIPtjMPiDvmW8s96oDX9eceFofcFIvMBW60Y68nBQakzN0bdPobB0zpIg3VrKe\nMBPsYtmTtTGEf4MgKzjYWq0detrmZqF4pq4l8qzU66VTSmgjjEDgg0kq/abx+/Ut\nK8bq+Wo7AjgVVZf/IaUUr8B6/uOdnQQRDyBjqCH+lH3g/ZpZ2OJBvtWGj7DtZHWI\ny5IO\n-----END CERTIFICATE-----\n",
        # Dummy self-signed key.
        key: "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCt36/OLrRa3vui\n1ns7ey67btL/AN6lw2scwO0iurKUw5vomfEqjhks04dsBKTheSjYH4UroKN9ubJe\nVIZ+FL3ewSVLVMLG10TSya1vm2J0xR3nrWnbL9uoz7lERmQSXzllr5PHj+q3aI3e\nwTXQk8Ic71NFGBGDcDBRPdWEzyqsfvFvMVACGUBHrDyWO4WBbLp3gzbwITnQhGXz\n+f9cha1IiBYrrbysDDuw81Fa2HEiDiA3ghGVR4q9DwVjpf1YpZyaMxRs28pUZ8Eu\n5gyfemznQIW1pRnyN2/77IZsFooMzQ+q0jxjjTzbuNoQSL+Gfpo5Rxvg+bR5+qyz\n4v07eFeRAgMBAAECggEAWEyauXiaevN2kzGdD431I5aabIoCh+gAA3AufU6W1lmo\nWa2j/dqACnW59i89lIu1JFyNgqRnorelT6ZZTro12mP4DpOS/uvftbRZ8a3ViDt6\nfmdgtMFPKiGjknq042ecfHl38QazSkU8lv1D2RLQp2UawqIAcuGMiBWA05tproNK\nvSyKs3MueGeOvWTQh2bvQVHH0OOC594QexxquDme9DJDgEgQq1UKJW8Hzu3oQbQJ\n9/UFjcPXmkO/+2DN0nLW+O8w1HtvVfr6Pa0UusR5WgFgNlvMBAc3XG+2V5iG/5By\ngTV0zkoBf4F5UqBOn9x/+kY/hrS6CPm+fgYn1ErwAQKBgQDX2u0rXDtsqOZJSB5K\neZBaUGHLZjzXNenCRcMKm+m/DGR8UjAKhEPdBGrQgP2g4LqpHbhWBLrdWaauUM/d\nX5XHeY6sed+VhSIg30HrNUa8dG93rDTnErBaUQb4tLs3iKmFOxpsZEbFO0Pw2mRH\nNH3kXSgr/rvOdG6PUwarfr7fgQKBgQDONfwt4NFV8EqMjNZANp2yh9MP7HH6bisi\nvaM6T/90Om//q4ciWnGEe8IDbZYln01/tzOjRIsY/xSDM2Hccbn3GLAFxeDPMIKH\nTr0cSxJKU++a7Dl9zvcg9jzdjCsDUfoUyNn209syzcziSX5/TaAKXzQbRhhrC/bK\nE9RaBouAEQKBgQCK4tpnY9j4eVRzImwbD0zKT54c+ZN8Bbx6u9hbIyarPpYJR/iR\nS7k+pHD154lJ0k9IMU9CSZjSg7SzxFt63N3Kk3Qxldk+o4LqE7yeUpFJAMIYBj2j\n0GqYMjqCHAe6G7y3dOfzhjHjBdcZSevrxOKb5TTL2gONO21H2uwXvF2kAQKBgF7q\nrncXooOiJU5ojT3lZdUFe/s6ZIRXLXfCPl3a8MS5GVBfzcXcR6AprvYQ/Sm4F94P\nn68pH7WTxAdYIVVs66J3NJ6TpJT5yTsq3RUm4PZhiEqRLS1hlJMRhJadrDbNBwWG\nJf3dKmpKHGKUXauPOXlMtRlQvHCZgzEky3vcw11hAoGBAJoXXOOXpMAHcpgWVttT\nYauJB3ekj8lVMX2l4lEyQ0o/1ODemJ1u+571TCqnRtQF9RwtwkR7m3+ivmgF/njV\n6dCrgelCpFYGHDVuw/Ieiqz7Fx8J++9SvXi9NM9a7fI2Td6/V3d1dYi/VHifYr5F\nQmBPCO5TwRB13PcVR2u7PuW1\n-----END PRIVATE KEY-----\n",
        chain: ''
      }
    end

    def cert_defined(ssl_info)
      ! ssl_info[:certificate].empty? && ! ssl_info[:key].empty?
    end

    def create_ssl_cert(ssl_info)
      directory '/etc/nginx/ssl' do
        owner 'root'
        group 'root'
        mode '0700'
      end

      # Store the certificate and key
      # Concatenate the cert and the chain cert
      cert_content = %Q|#{ssl_info[:certificate]}\n#{ssl_info[:chain]}\n|
      file "/etc/nginx/ssl/certificate.cert" do
        owner 'root'
        group 'root'
        content cert_content
        mode '0600'
      end

      file "/etc/nginx/ssl/certificate.key" do
        owner 'root'
        group 'root'
        content ssl_info[:key] + "\n"
        mode '0600'
      end
    end

    def get_capture_agent_manager_info
      node.fetch(
        :capture_agent_manager, {
          capture_agent_manager_app_name: 'cadash',
          capture_agent_manager_usr_name: 'capture_agent_manager',
          capture_agent_manager_secret_key: 'super_secret_key',
          capture_agent_manager_gunicorn_log_level: 'debug',
          log_config: '/home/capture_agent_manager/sites/cadash/logging.yaml',
          ca_stats_user: 'usr',
          ca_stats_passwd: 'pwd',
          ca_stats_json_url: 'http://fake-ca-status.com/ca-status.json',
          epipearl_user: 'usr',
          epipearl_passwd: 'pwd',
          ldap_host: 'ldap-hostname.some-domain.com',
          ldap_base_search: 'dc=some-domain,dc=com',
          ldap_bind_dn: 'cn=fake_usr,dc=some-domain,dc=com',
          ldap_bind_passwd: 'pwd',
          capture_agent_manager_git_repo: 'https://github.com/harvard-dce/cadash',
          capture_agent_manager_git_revision: 'master',
          capture_agent_manager_database_usr: 'usr',
          capture_agent_manager_database_pwd: 'pwd'
        }
      )
    end

    def get_capture_agent_manager_app_name
      ca_info = get_capture_agent_manager_info
      ca_info[:capture_agent_manager_app_name]
    end

    def get_capture_agent_manager_usr_name
      ca_info = get_capture_agent_manager_info
      ca_info[:capture_agent_manager_usr_name]
    end
    
    def get_moscaler_info
      {
          'moscaler_type' => 'disabled',
          'moscaler_release' => 'master',
          'moscaler_debug' => false,
          'offpeak_instances' => 2,
          'peak_instances' => 10,
          'weekend_instances' => 1,
          'cron_interval' => '*/2',
          'min_workers' => 1,
          'idle_uptime_threshold' => 50,
          'autoscale_up_increment' => 2,
          'autoscale_down_increment' => 1,
          'autoscale_pause_cycles' => 1,
          'autoscale_strategies' => []
        }.merge(node.fetch(:moscaler, {}))
    end

    def configure_cloudwatch_log(log_name, log_file, datetime_format)

      unless on_aws?
        return
      end

      stack_name = stack_shortname
      log_group_name = stack_name + "_" + log_name

      create_log_group(log_group_name)

      service 'awslogs' do
        action :nothing
      end

      template "/var/awslogs/etc/config/#{log_name}.conf" do
        source 'cwlog_stream.conf.erb'
        owner 'root'
        group 'root'
        mode 0644
        variables ({
            :log_name => log_name,
            :hostname => node[:opsworks][:instance][:hostname],
            :stack_name => stack_name,
            :log_file => log_file,
            :datetime_format => datetime_format
        })
        notifies :restart, 'service[awslogs]', :delayed
      end
    end

    def create_log_group(log_group_name)

      region = node.fetch(:region, 'us-east-1')
      retention_days = node.fetch(:cwlogs_retention_days, '30')

      execute 'create log group' do
        command %Q|aws logs create-log-group --region #{region} --log-group-name #{log_group_name}|
        returns [0, 255]
        ignore_failure true
      end

      execute 'set log group retention policy' do
        command %Q|aws logs put-retention-policy --region #{region} --log-group-name #{log_group_name} --retention-in-days #{retention_days}|
        retries 3
        retry_delay 10
      end

    end

    def configure_nginx_cloudwatch_logs
      configure_cloudwatch_log("nginx-access", "/var/log/nginx/access.log", "%d/%b/%Y:%H:%M:%S %z")
      configure_cloudwatch_log("nginx-error", "/var/log/nginx/error.log", "%d/%b/%Y:%H:%M:%S %z")
    end

    def get_nginx_worker_procs
      number_of_cpus = execute_command(%Q(nproc)).chomp.to_i
      if admin_node? || engage_node?
        [(number_of_cpus / 2), 4].max
      else
        4
      end
    end
  end

  module DeployHelpers
    def files_for(node_profile)
      files = {
        admin: [
          {
            src: 'dce-config/email/errorDetails',
            dest: 'etc/email/errorDetails'
          },
          {
            src: 'dce-config/email/eventDetails',
            dest: 'etc/email/eventDetails'
          },
          {
            src: 'dce-config/email/metasynchDetails',
            dest: 'etc/email/metasynchDetails'
          },
          {
            src: 'dce-config/services/org.ops4j.pax.logging.properties',
            dest: 'etc/services/org.ops4j.pax.logging.properties'
          },
        ],
        worker: [
          {
            src: 'dce-config/email/errorDetails',
            dest: 'etc/email/errorDetails'
          },
          {
            src: 'dce-config/email/eventDetails',
            dest: 'etc/email/eventDetails'
          },
          {
            src: 'dce-config/email/metasynchDetails',
            dest: 'etc/email/metasynchDetails'
          },
          {
            src: 'dce-config/encoding/DCE-h264-movies.properties',
            dest: 'etc/encoding/DCE-h264-movies.properties'
          },
          {
            src: 'dce-config/encoding/engage-images.properties',
            dest: 'etc/encoding/engage-images.properties'
          },
          {
            src: 'dce-config/encoding/matterhorn-images.properties',
            dest: 'etc/encoding/matterhorn-images.properties'
          },
          {
            src: 'dce-config/workflows/DCE-error-handler.xml',
            dest: 'etc/workflows/DCE-error-handler.xml',
          },
          {
            src: 'dce-config/services/org.ops4j.pax.logging.properties',
            dest: 'etc/services/org.ops4j.pax.logging.properties'
          },
        ],
        engage: [
          {
            src: 'dce-config/email/errorDetails',
            dest: 'etc/email/errorDetails'
          },
          {
            src: 'dce-config/email/eventDetails',
            dest: 'etc/email/eventDetails'
          },
          {
            src: 'dce-config/email/metasynchDetails',
            dest: 'etc/email/metasynchDetails'
          },
          {
            src: 'dce-config/workflows/DCE-error-handler.xml',
            dest: 'etc/workflows/DCE-error-handler.xml',
          },
          {
            src: 'dce-config/services/org.ops4j.pax.logging.properties',
            dest: 'etc/services/org.ops4j.pax.logging.properties'
          },
        ]
      }
      files.fetch(node_profile.to_sym, [])
    end

    def install_published_event_details_email(current_deploy_root, engage_hostname)
      template %Q|#{current_deploy_root}/etc/email/publishedEventDetails| do
        source 'publishedEventDetails.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          engage_hostname: engage_hostname
        })
      end
    end

    def configure_usertracking(current_deploy_root, user_tracking_authhost)
      template %Q|#{current_deploy_root}/etc/services/org.opencastproject.usertracking.impl.UserTrackingServiceImpl.properties| do
        source 'UserTrackingServiceImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          user_tracking_authhost: user_tracking_authhost
        })
      end
    end

    def download_episode_defaults_json_file(current_deploy_root)
      private_assets_bucket_name = node.fetch(:private_assets_bucket_name, 'default-private-bucket')

      episode_default_storage_dir = %Q|#{current_deploy_root}/etc/default_data|

      directory episode_default_storage_dir  do
        owner 'matterhorn'
        group 'matterhorn'
        mode '755'
        recursive true
      end

      if node[:vagrant_environment] != true
        execute 'download the EpisodeDefaults.json file into the correct location' do
          command %Q|cd #{episode_default_storage_dir} && aws s3 cp s3://#{private_assets_bucket_name}/EpisodeDefaults.json EpisodeDefaults.json|
          retries 10
          retry_delay 5
          timeout 300
        end
      end
    end

    def install_otherpubs_service_config(current_deploy_root, matterhorn_repo_root, auth_host, other_oc_host, other_oc_prefother_series, other_oc_preflocal_series)
      download_episode_defaults_json_file(current_deploy_root)

      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.otherpubs.service.OtherpubsService.properties| do
        source 'edu.harvard.dce.otherpubs.service.OtherpubsService.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          auth_host: auth_host,
          other_oc_host: other_oc_host,
          other_oc_prefother_series: other_oc_prefother_series,
          other_oc_preflocal_series: other_oc_preflocal_series,
          matterhorn_repo_root: matterhorn_repo_root
        })
      end
    end

    def install_otherpubs_service_series_impl_config(current_deploy_root)

      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.otherseries.service.OtherSeriesServiceImpl.properties| do
        icommons_api_token = node.fetch(:icommons_api_token, 'replace-with-an-icommons-api-token-or-manually-create-series-mappings')
        source 'edu.harvard.dce.otherseries.service.OtherSeriesServiceImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          icommons_api_token: icommons_api_token
        })
      end
    end

    # nodes that don't dispatch should also not do hearbeat service health checks
    def set_service_registry_dispatch_interval(current_deploy_root)
      template %Q|#{current_deploy_root}/etc/services/org.opencastproject.serviceregistry.impl.ServiceRegistryJpaImpl.properties| do
        source 'ServiceRegistryJpaImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          dispatch_interval: 0,
          heartbeat_interval: 0
        })
      end
    end

    def install_matterhorn_log_management
      compress_after_days = 7
      delete_after_days = 180
      log_dir = node.fetch(:matterhorn_log_directory, '/var/log/matterhorn')

      cron_d 'compress_matterhorn_logs' do
        user 'matterhorn'
        predefined_value '@daily'
        command %Q(find #{log_dir} -maxdepth 1 -type f -name 'matterhorn.log.2*' -not -name '*.gz' -mtime #{compress_after_days} -exec /bin/gzip {} \\;)
        path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      end

      cron_d 'delete_matterhorn_logs' do
        user 'matterhorn'
        predefined_value '@daily'
        command %Q(find #{log_dir} -maxdepth 1 -type f -name 'matterhorn.log.2*.gz' -mtime #{delete_after_days} -delete)
        path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      end
    end

    def xmx_ram_ratio_for_this_node
      # ratio of xmx (max heap) to total available ram
      # this is just the max allowed, not how much is initially allocated
      if node[:opsworks][:instance][:hostname].match(/^worker/)
        0.25
      else
        0.8
      end
    end

    def xmx_xms_ratio_for_this_node
      # ratio of xms (initial heap) to xmx (max heap)
      # this reserves/allocates initial heap size
      if node[:opsworks][:instance][:hostname].match(/^engage/)
        0.5
      else
        0.10
      end
    end

    def initialize_database(current_deploy_root)
      db_info = node[:deploy][:matterhorn][:database]
      db_seed_file = node.fetch(:db_seed_file, 'dce-config/docs/scripts/ddl/mysql5.sql')

      host = db_info[:host]
      username = db_info[:username]
      password = db_info[:password]
      port = db_info[:port]
      database_name = db_info[:database]

      database_connection = %Q|/usr/bin/mysql --user="#{username}" --host="#{host}" --port=#{port} --password="#{password}" "#{database_name}"|
      create_tables = %Q|#{database_connection} < #{current_deploy_root}/#{db_seed_file}|
      tables_exist = %Q(#{database_connection} -B -e "show tables" | grep -qie "Tables_in_#{database_name}")

      execute 'Create tables' do
        command create_tables
        not_if tables_exist
      end
    end

    def xmx_ram_for_this_node(xmx_ram_ratio)
      auto_configure_java_xmx_memory = node.fetch(:auto_configure_java_xmx_memory, true)
      if auto_configure_java_xmx_memory
        ram_finder = Mixlib::ShellOut.new(%q(grep MemTotal /proc/meminfo | sed -r 's/[^0-9]//g'))
        ram_finder.run_command
        ram_finder.error!
        total_ram_in_meg = ram_finder.stdout.chomp.to_i / 1024
        # configure Xmx value as a percent of the total ram for this
        # node, with a minimum of 4096
        [(total_ram_in_meg * xmx_ram_ratio).to_i, 4096].max
      else
        4096
      end
    end

    def using_local_distribution?
      ! node[:cloudfront_url] && ! node[:s3_distribution_bucket_name]
    end

    def update_properties_files_for_local_distribution(current_deploy_root)
      ruby_block "update engage hostname" do
        block do
          ['engage.properties', 'admin.properties', 'all-in-one.properties'].each do |properties_file|
            editor = Chef::Util::FileEdit.new(current_deploy_root + '/etc/profiles/' + properties_file)
            editor.search_file_replace(
              /mh-harvard-dce-distribution-service-aws-s3/,
              "matterhorn-distribution-service-download"
            )
            editor.write_file
          end
        end
      end
    end

    def install_init_scripts(current_deploy_root, matterhorn_repo_root)
      log_dir = node.fetch(:matterhorn_log_directory, '/var/log/matterhorn')

      xmx_ram_ratio = xmx_ram_ratio_for_this_node
      java_xmx_ram = xmx_ram_for_this_node(xmx_ram_ratio)
      java_xms_ram = java_xmx_ram * xmx_xms_ratio_for_this_node

      xms_ram_ratio = xmx_xms_ratio_for_this_node
      # round(-1) will round to nearest divisible by 10 so we get an even number
      java_xms_ram = [(java_xmx_ram * xms_ram_ratio).to_i.round(-1), 2048].max

      start_check_sleep_seconds = enable_yourkit_agent? ? 30 : 20

      template %Q|/etc/init.d/matterhorn| do
        source 'matterhorn-init-script.erb'
        owner 'matterhorn'
        group 'matterhorn'
        mode '755'
        variables({
          matterhorn_executable: matterhorn_repo_root + '/current/bin/matterhorn',
          start_check_sleep_seconds: start_check_sleep_seconds
        })
      end

      template %Q|#{current_deploy_root}/bin/matterhorn| do
        source 'matterhorn-harness.erb'
        owner 'matterhorn'
        group 'matterhorn'
        mode '755'
        variables({
          java_xmx_ram: java_xmx_ram,
          java_xms_ram: java_xms_ram,
          main_config_file: %Q|#{matterhorn_repo_root}/current/etc/matterhorn.conf|,
          matterhorn_root: matterhorn_repo_root + '/current',
          felix_config_dir: matterhorn_repo_root + '/current/etc',
          matterhorn_log_directory: log_dir,
          enable_newrelic: enable_newrelic?,
          enable_G1GC: enable_G1GC?,
          enable_yourkit_agent: enable_yourkit_agent?,
          yourkit_dir: matterhorn_repo_root + '/yourkit'
        })
      end
    end

    def install_matterhorn_conf(current_deploy_root, matterhorn_repo_root, node_profile)
      log_dir = node.fetch(:matterhorn_log_directory, '/var/log/matterhorn')
      java_debug_enabled = node.fetch(:java_debug_enabled, 'true')

      template %Q|#{current_deploy_root}/etc/matterhorn.conf| do
        source 'matterhorn.conf.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          matterhorn_root: matterhorn_repo_root + '/current',
          node_profile: node_profile,
          matterhorn_log_directory: log_dir,
          java_debug_enabled: java_debug_enabled
        })
      end
    end

    def install_multitenancy_config(current_deploy_root, admin_hostname, engage_hostname)
      template %Q|#{current_deploy_root}/etc/load/org.opencastproject.organization-mh_default_org.cfg| do
        source 'mh_default_org.cfg.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          hostname: admin_hostname,
          admin_hostname: admin_hostname,
          engage_hostname: engage_hostname
        })
      end
    end

    def install_default_tenant_config(current_deploy_root, public_dns_name, private_dns_name)
      lti_oauth_info = get_lti_auth_info
      template %Q|#{current_deploy_root}/etc/security/mh_default_org.xml| do
        source 'mh_default_org.xml.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          lti_oauth: lti_oauth_info,
          unproxied_name: public_dns_name,
          proxy_name: public_dns_name
        })
      end
    end

    def get_lti_auth_info
      node.fetch(:lti_oauth,
        {
          consumer: 'consumerkey',
          secret: 'sharedsecret'
        }
      )
    end

    def install_smtp_config(current_deploy_root)
      smtp_auth = node.fetch(:smtp_auth, {})
      default_email_sender = smtp_auth.fetch(:default_email_sender, 'no-reply@localhost')

      template %Q|#{current_deploy_root}/etc/services/org.opencastproject.kernel.mail.SmtpService.properties| do
        source 'org.opencastproject.kernel.mail.SmtpService.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          default_email_sender: default_email_sender,
        })
      end
    end

    def enable_newrelic?
      node[:newrelic]
    end

    def enable_newrelic_layer?(layer_name)
       nr_layers = node.fetch(:newrelic,{}) #  must be a hash
       nr_layers.key?(layer_name)
    end

    def enable_yourkit_agent?
      node[:enable_yourkit_agent]
    end

    def enable_G1GC?
       node[:enable_G1GC] and node[:opsworks][:instance][:hostname].match(/^(admin|engage)/)
    end

    def configure_newrelic(current_deploy_root, node_name, layer_name)
      if enable_newrelic_layer?(layer_name)
            log_dir = node.fetch(:matterhorn_log_directory, '/var/log/matterhorn')
            newrelic_layers = node.fetch(:newrelic,{})
            newrelic_layer = newrelic_layers.fetch(layer_name,{})
            newrelic_key = newrelic_layer[:key]

            environment_name = node[:opsworks][:stack][:name]
            template %Q|#{current_deploy_root}/etc/newrelic.yml| do
              source 'newrelic.yml.erb'
              owner 'matterhorn'
              group 'matterhorn'
              variables({
                newrelic_key: newrelic_key,
                node_name: node_name,
                environment_name: environment_name,
                log_dir: log_dir
              })
            end
      end 
    end

    def install_live_streaming_service_config(current_deploy_root,live_stream_name)
      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.live.impl.LiveServiceImpl.properties| do
        source 'edu.harvard.dce.live.impl.LiveServiceImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          live_stream_name: live_stream_name
        })
      end
    end

    def install_aws_s3_distribution_service_config(current_deploy_root, region, s3_distribution_bucket_name)
      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.distribution.aws.s3.AwsS3DistributionServiceImpl.properties| do
        source 'edu.harvard.dce.distribution.aws.s3.AwsS3DistributionServiceImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          region: region,
          s3_distribution_bucket_name: s3_distribution_bucket_name
        })
      end
    end

    def install_aws_s3_file_archive_service_config(current_deploy_root, region, s3_file_archive_bucket_name)
      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.episode.aws.s3.AwsS3ArchiveElementStore.properties| do
        source 'edu.harvard.dce.episode.aws.s3.AwsS3ArchiveElementStore.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          region: region,
          s3_file_archive_bucket_name: s3_file_archive_bucket_name
        })
      end
    end

    def install_ibm_watson_transcription_service_config(current_deploy_root, ibm_watson_username, ibm_watson_psw)
      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.transcription.ibm.watson.IBMWatsonTranscriptionService.properties| do
        source 'edu.harvard.dce.transcription.ibm.watson.IBMWatsonTranscriptionService.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          ibm_watson_username: ibm_watson_username,
          ibm_watson_psw: ibm_watson_psw  
        })
      end
    end

    def setup_transcript_result_sync_to_s3(shared_storage_root, transcript_bucket_name)
      transcript_path = shared_storage_root + '/files/collection/transcripts'
      cron_d 'sync_transcripts_to_s3' do
        user 'matterhorn'
        predefined_value '@daily'
        command %Q|cd #{transcript_path}; aws s3 sync --quiet . s3://#{transcript_bucket_name}|
        path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      end
    end

    def install_auth_service(current_deploy_root, auth_host, redirect_location, auth_key, auth_activated = 'true')
      template %Q|#{current_deploy_root}/etc/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties| do
        source 'edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          auth_host: auth_host,
          redirect_location: redirect_location,
          auth_activated: auth_activated,
          auth_key: auth_key
        })
      end
    end

    def copy_workflows_into_place_for_admin(current_deploy_root)
      execute 'copy workflows into place for admin' do
        command %Q|find #{current_deploy_root}/dce-config/workflows -maxdepth 1 -type f -exec cp -t #{current_deploy_root}/etc/workflows {} +|
        retries 3
        retry_delay 10
      end
    end

    def copy_configs_for_load_service(current_deploy_root)
      execute 'copy service configs' do
        command %Q|find #{current_deploy_root}/dce-config/load -maxdepth 1 -type f -exec cp -t #{current_deploy_root}/etc/load {} +|
        retries 3
        retry_delay 10
      end
    end

    def copy_services_into_place(current_deploy_root)
      execute 'copy services' do
        command %Q|find #{current_deploy_root}/dce-config/services -maxdepth 1 -type f -exec cp -t #{current_deploy_root}/etc/services {} +|
        retries 3
        retry_delay 10
      end
    end

    def copy_files_into_place_for(node_profile, current_deploy_root)
      files_for(node_profile).each do |file_config|
        source_file = %Q|#{current_deploy_root}/#{file_config[:src]}|
        destination_file = %Q|#{current_deploy_root}/#{file_config[:dest]}|
        file destination_file do
          owner 'matterhorn'
          group 'matterhorn'
          mode '644'
          content lazy { ::File.read(source_file) }
          action :create
        end
      end
    end

    def maven_build_for(node_profile, current_deploy_root)
      # TODO - if failed builds continue to be an issue because of ephemeral
      # node_modules or issues while maven pulls down artifacts,
      # run this in a begin/rescue block and retry a build immediately
      # after failure a few times before permanently failing
      build_profiles = {
        admin: '-Padmin,dist-stub,engage-stub,worker-stub,workspace,serviceregistry',
        ingest: '-Pingest-standalone',
        worker: '-Pworker-standalone,serviceregistry,workspace',
        engage: '-Pengage-standalone,dist,serviceregistry,workspace'
      }
      skip_unit_tests = node.fetch(:skip_java_unit_tests, 'true')
      retry_this_many = 3
      if skip_unit_tests.to_s == 'false'
        retry_this_many = 0
      end
      execute 'maven build for matterhorn' do
        command %Q|cd #{current_deploy_root} && MAVEN_OPTS='-Xms256m -Xmx960m -XX:PermSize=64m -XX:MaxPermSize=256m' mvn clean install -DdeployTo="#{current_deploy_root}" -Dmaven.test.skip=#{skip_unit_tests} #{build_profiles[node_profile.to_sym]}|
        retries retry_this_many
        retry_delay 30
      end
    end

    def remove_felix_fileinstall(current_deploy_root)
      file %Q|#{current_deploy_root}/etc/load/org.apache.felix.fileinstall-matterhorn.cfg| do
        action :delete
      end
    end

    def path_to_most_recent_deploy(resource)
      deploy_root = resource.deploy_to + '/releases/'
      all_entries = Dir.new(deploy_root).entries
      deploy_directories = all_entries.find_all do |f|
        File.directory?(deploy_root + f) && ! f.match(/\A\.\.?\Z/)
      end
      most_recent_deploy = deploy_directories.sort_by{ |x| File.mtime(deploy_root + x) }.last
      deploy_root + most_recent_deploy
    end
  end
end
