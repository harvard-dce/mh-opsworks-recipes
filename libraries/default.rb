module MhOpsworksRecipes
  module RecipeHelpers
    def get_admin_user_info
      node.fetch(
        :admin_auth, {
          user: 'admin',
          pass: 'password'
        }
      )
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
          export_root: '/var/tmp',
          network: '10.0.0.0/8',
          layer_shortname: 'storage'
        }
      )
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
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg'
          },
          {
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg'
          },
          {
            src: 'dce-config/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
            dest: 'etc/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
          },
          {
            src: 'dce-config/services/edu.harvard.dce.utils.cleanup.FailedZipsScanner.properties',
            dest: 'etc/services/edu.harvard.dce.utils.cleanup.FailedZipsScanner.properties',
          },
          {
            src: 'dce-config/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
            dest: 'etc/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
          },
          {
            src: 'dce-config/workflows/DCE-archive-publish-external.xml',
            dest: 'etc/workflows/DCE-archive-publish-external.xml',
          },
          {
            src: 'dce-config/workflows/DCE-error-handler.xml',
            dest: 'etc/workflows/DCE-error-handler.xml',
          },
          {
            src: 'dce-config/workflows/DCE-ingest-from-prodsys.xml',
            dest: 'etc/workflows/DCE-ingest-from-prodsys.xml',
          },
          {
            src: 'dce-config/workflows/DCE-production.xml',
            dest: 'etc/workflows/DCE-production.xml',
          },
          {
            src: 'dce-config/workflows/DCE-retrieve-from-archive.xml',
            dest: 'etc/workflows/DCE-retrieve-from-archive.xml',
          },
          {
            src: 'dce-config/workflows/DCE-transcode-4x3.xml',
            dest: 'etc/workflows/DCE-transcode-4x3.xml',
          },
          {
            src: 'dce-config/workflows/DCE-transcode-hold-append.xml',
            dest: 'etc/workflows/DCE-transcode-hold-append.xml',
          }
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
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg'
          },
          {
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg'
          },
          {
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox.cfg'
          },
          {
            src: 'dce-config/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
            dest: 'etc/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
          },
          {
            src: 'dce-config/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
            dest: 'etc/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
          },
          {
            src: 'dce-config/workflows/DCE-error-handler.xml',
            dest: 'etc/workflows/DCE-error-handler.xml',
          }
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
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-archive-retrieve.cfg'
          },
          {
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox-hold-for-append.cfg'
          },
          {
            src: 'dce-config/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox.cfg',
            dest: 'etc/load/org.opencastproject.ingest.scanner.InboxScannerService-inbox.cfg'
          },
          {
            src: 'dce-config/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
            dest: 'etc/services/edu.harvard.dce.auth.impl.HarvardDCEAuthServiceImpl.properties',
          },
          {
            src: 'dce-config/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
            dest: 'etc/services/org.opencastproject.execute.impl.ExecuteServiceImpl.properties',
          },
          {
            src: 'dce-config/workflows/DCE-error-handler.xml',
            dest: 'etc/workflows/DCE-error-handler.xml',
          }
        ]
      }
      files.fetch(node_profile.to_sym, [])
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

    def set_service_registry_dispatch_interval(current_deploy_root)
      template %Q|#{current_deploy_root}/etc/services/org.opencastproject.serviceregistry.impl.ServiceRegistryJpaImpl.properties| do
        source 'ServiceRegistryJpaImpl.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          dispatch_interval: 0
        })
      end
    end

    def install_matterhorn_images_properties(current_deploy_root)
      template %Q|#{current_deploy_root}/etc/encoding/matterhorn-images.properties| do
        source 'matterhorn-images.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
      end
    end

    def install_init_scripts(current_deploy_root, matterhorn_repo_root)
      template %Q|/etc/init.d/matterhorn| do
        source 'matterhorn-init-script.erb'
        owner 'matterhorn'
        group 'matterhorn'
        mode '755'
        variables({
          matterhorn_executable: matterhorn_repo_root + '/current/bin/matterhorn'
        })
      end

      template %Q|#{current_deploy_root}/bin/matterhorn| do
        source 'matterhorn-harness.erb'
        owner 'matterhorn'
        group 'matterhorn'
        mode '755'
        variables({
          main_config_file: %Q|#{matterhorn_repo_root}/current/etc/matterhorn.conf|,
          matterhorn_root: matterhorn_repo_root + '/current',
          felix_config_dir: matterhorn_repo_root + '/current/etc'
        })
      end
    end

    def install_matterhorn_conf(current_deploy_root, matterhorn_repo_root, node_profile)
      template %Q|#{current_deploy_root}/etc/matterhorn.conf| do
        source 'matterhorn.conf.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          matterhorn_root: matterhorn_repo_root + '/current',
          node_profile: node_profile
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

    def install_logging_config(current_deploy_root)
      template %Q|#{current_deploy_root}/etc/services/org.ops4j.pax.logging.properties| do
        source 'org.ops4j.pax.logging.properties.erb'
        owner 'matterhorn'
        group 'matterhorn'
        variables({
          main_log_level: 'DEBUG'
        })
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
        admin: 'admin,dist-stub,engage-stub,worker-stub,workspace,serviceregistry',
        ingest: 'ingest-standalone',
        worker: 'worker-standalone,serviceregistry,workspace',
        engage: 'engage-standalone,dist,serviceregistry,workspace'
      }
      execute 'maven build for matterhorn' do
        command %Q|cd #{current_deploy_root} && MAVEN_OPTS='-Xms256m -Xmx960m -XX:PermSize=64m -XX:MaxPermSize=256m' mvn clean install -DdeployTo="#{current_deploy_root}" -Dmaven.test.skip=true -P#{build_profiles[node_profile.to_sym]}|
        retries 3
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
