name             'mh-opsworks-recipes'
maintainer       'Dan Collis-Puro'
maintainer_email 'dan@collispuro.net'
license          'All rights reserved'
description      'Installs/Configures mh-opsworks-recipes'
long_description 'Installs/Configures mh-opsworks-recipes'
version          '0.1.0'
issues_url       'http://github.com/harvard-dce/mh-opsworks-recipes/issues' if respond_to?(:issues_url)
source_url       'http://github.com/harvard-dce/mh-opsworks-recipes/'if respond_to?(:source_url)

recipe(
  'mh-opsworks-recipe::default',
  'This cookbook does nothing by default'
)
recipe(
  'mh-opsworks-recipes::nfs-client',
  'Sets up an instance to connect to an NFS export.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_info

=== Effects
* nfs-client packages installed
* autofs tooling to mount the NFS drive.
* autofs is restarted if we do not have an active mount
* install a cloudwatch alarm and metric if we are on aws
'
)
recipe(
  'mh-opsworks-recipes::nfs-export',
  'Sets up an instance to export a directory via nfs

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_info and get_shared_storage_root

=== Effects
* install nfs server packages
* configure /etc/exports with the directory and cidr block from the config
* ensure the export is owned by the matterhorn user
'
)
recipe(
  'mh-opsworks-recipes::deploy-admin',
  'Sets up an instance to be an admin node

See the chef "deploy_revision" resource to understand how our deploys work.

=== Attributes
* Many. See MhOpsworksRecipes::RecipeHelpers and MhOpsworksRecipes::DeployHelpers

=== Effects
* does a maven build with the admin profile
* configures after a successful build
* restarts matterhorn if it is not running already
* runs mh-opsworks-recipes::monitor-matterhorn-daemon to install cloudwatch
  metrics and alarms
* registers the matterhorn service to start on instance boot
'
)
recipe(
  'mh-opsworks-recipes::set-timezone',
  'Sets the timezone on a node

=== Attributes
* <tt>node[:timezone]</tt>

=== Effects
* Sets the timezone to "America/New_York" or whatever you set in <tt>node[:timezone]</tt>
'
)
recipe(
  'mh-opsworks-recipes::install-utils',
  'Installs utility packages useful on all nodes for debugging

=== Attributes
* none

=== Effects
* the package repo lists are updated
* utility packages are installed
* the package cache is cleared to save space
'
)
recipe(
  'mh-opsworks-recipes::remove-alarms',
  'Removes cloudwatch alarms associated with an instance

This should be run during the opsworks "shutdown" lifecycle events

=== Attributes
* none

=== Effects
* the python aws cli is used to get a list of alarms associated with the instance
* that list of alarms is removed via the python aws cli
'
)
recipe(
  'mh-opsworks-recipes::deploy-worker',
  'Sets up an instance to be a worker node

See the deploy-admin docs for more info.'
)
recipe(
  'mh-opsworks-recipes::deploy-engage',
  'Sets up an instance to be the engage node

See the deploy-admin docs for more info.'
)
recipe(
  'mh-opsworks-recipes::install-kibana',
  'Sets up a node to work as a Kibana analytics instance

You should add a layer as defined in
{mh-opsworks/README.analytics.md}[https://github.com/harvard-dce/mh-opsworks/blob/master/README.analytics.md].
That layer will use this recipe to install kibana.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_elk_info primarily

=== Effects
* A kibana user is and group is created
* kibana is installed
'
)
recipe(
  'mh-opsworks-recipes::install-ffmpeg',
  'Install our custom build of ffmpeg to the node

This installs our custom ffmpeg build created by
{ffmpeg-build}[https://github.com/harvard-dce/ffmpeg-build].

You must build a new version of ffmpeg and upload it to aws according to the
docs in the ffmpeg-build project above.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_shared_asset_bucket_name
* <tt>node[:ffmpeg_version]</tt>

=== Effects
* shared library packages for ffmpeg are installed
* ffmpeg, ffprobe, ffplay, ffserver, and x264 are installed and symlinked to
  /usr/local/bin
'
)
recipe(
  'mh-opsworks-recipes::install-awscli',
  'Installs the commandline aws-cli client

The default version is <tt>1.10.5</tt>. You can install whatever version you
want by setting the parameter below.

=== Attributes
* <tt>node[:awscli_version]</tt>

=== Effects
* the python-pip package is installed
* the aws-cli is installed into /usr/local/bin
'
)
recipe(
  'mh-opsworks-recipes::load-seed-data',
  'loads seed database and files as part of the cluster seed functionality

This downloads a cluster seed from aws, extracts the files and loads and
applies local modifications to the database. It is run by the
<tt>cluster:apply_seed_file</tt> rake task in mh-opsworks.

This should only be run on development clusters, as defined by
MhOpsworksRecipes::RecipeHelpers.dev_or_testing_cluster?

=== Attributes
* Many, mostly related to hostnames and file paths.

=== Effects
* files in the current cluster are replaced with the files from the seed
* the database in the current cluster is replaced with the database from the
  seed
* the newly applied database is modified to reflect the current cluster
  environment
'
)
recipe(
  'mh-opsworks-recipes::install-nodejs',
  'installs static binaries of nodejs and npm

This installs the official static binaries of nodejs and npm to
<tt>/usr/local/bin/</tt>

=== Attributes
* <tt>node[:node_version]</tt>, defaults to <tt>0.12.1</tt>

=== Effects
* the ubuntu node packages are removed
* the official node static binaries are installed.
'
)
recipe(
  'mh-opsworks-recipes::reset-database',
  'resets the matterhorn database a clean post-first-deploy state

This should only be run on development clusters, as defined by
MhOpsworksRecipes::RecipeHelpers.dev_or_testing_cluster?.

This is part of the cluster seed infrastructure implemented in mh-opsworks.

=== Attributes
* <tt>node[:db_seed_file]</tt>, defaults to <tt>dce-config/docs/scripts/ddl/mysql5.sql</tt>

=== Effects
* The database is deleted
* The default database seed is applied as defined by <tt>node[:db_seed_file]</tt>
'
)
recipe(
  'mh-opsworks-recipes::deploy-database',
  'deploys the default database seed to this node

Only used in local opsworks clusters where we are not using RDS.

=== Attributes
* Many, but <tt>node[:db_seed_file]</tt> is probably most important as it controls what seed file is loaded

=== Effects
* The db seed file is loaded into the database
'
)
recipe(
  'mh-opsworks-recipes::stop-matterhorn',
  'stops matterhorn via the matterhorn service config

=== Attributes
* none

=== Effects
* matterhorn is stopped
'

)
recipe(
  'mh-opsworks-recipes::start-matterhorn',
  'start matterhorn via the matterhorn service config

=== Attributes
* <tt>node[:dont_start_matterhorn_automatically]</tt> if set to true will abort starting matterhorn

=== Effects
* matterhorn is started
'
)
recipe(
  'mh-opsworks-recipes::install-logstash',
  'Sets up logstash on a node

See also <tt>mh-opsworks-recipes::install-kibana</tt>. This installs the
logstash part of our analytics layer.

=== Attributes
* <tt>node[:logstash_major_version]</tt> the major version of logstash to configure the apt repo
* <tt>node[:logstash_version]</tt> the version of logstash to install

=== Effects
* logstash is installed
* logstash is configured
'
)
recipe(
  'mh-opsworks-recipes::fix-raid-mapping',
  'fix RAID mapping of ebs volumes

Fixes {this bug}[https://github.com/aws/opsworks-cookbooks/issues/188] which is
apparently still a thing. It should be run on all nodes.

=== Attributes
* none

=== Effects
* regenerates initramfs to ensure it supports software RAIDed volumes
* instances that (optionally) use software RAIDed EBS volumes now start
  correctly after a reboot
'
)
recipe(
  'mh-opsworks-recipes::deploy-all-in-one',
  'FIXME: deploys an all-in-one node.'
)
recipe(
  'mh-opsworks-recipes::rsyslog-to-loggly',
  'installs and configures rsyslog to send logs to loggly.com

=== Attributes
* <tt>node[:loggly]</tt> - include the "token" and "url" keys. If absent nothing will be configured.

=== Effects
* the rsyslog-gnutls package is installed
* if the loggly token and URL are present, configure rsyslog to send tagged
  logs to loggly
  '
)
recipe(
  'mh-opsworks-recipes::install-deploy-key',
  'Installs a private deploy ssh key for the matterhorn user

=== Attributes
* <tt>node[:deploy][:matterhorn][:scm]</tt>, which comes from the opsworks app configuration

=== Effects
* the private key is put into <tt>/home/matterhorn/.ssh/</tt>
* a basic ssh config is installed to <tt>/home/matterhorn/.ssh/config</tt>
'
)
recipe(
  'mh-opsworks-recipes::restart-matterhorn',
  'restarts the matterhorn service

=== Attributes
* <tt>node[:dont_start_matterhorn_automatically]</tt> if set to true will abort starting matterhorn

=== Effects
* matterhorn will be restarted
'
)
recipe(
  'mh-opsworks-recipes::maintenance-mode-on',
  'Sets matterhorn maintenance mode on for this node

=== Attributes
* none

=== Effects
* We send an API request to the admin node to put this node into maintenance
  mode
'
)
recipe(
  'mh-opsworks-recipes::update-package-repo',
  'Updates the package repo to ensure we have the latest package lists

=== Attributes
* none

=== Effects
* half-configured packages are fixed
* the package list is updated
'
)
recipe(
  'mh-opsworks-recipes::create-mysql-alarms',
  'create cloudwatch metrics and alarms against the RDS instance

=== Attributes
* MhOpsworksRecipes::RecipeHelpers

=== Effects
* Numerous cloudwatch alarms are created for space, CPU, storage, RAM, and IO
* These alarms are bound directly to the RDS instance
'
)
recipe(
  'mh-opsworks-recipes::populate-maven-cache',
  'Download and extract a maven cache seed

This grabs and extracts a tarball containing a maven cache from the shared
asset bucket. This speeds up builds greatly on new nodes.  You can update the
seed via the <tt>admin:republish_maven_cache</tt> rake task in mh-opsworks.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_shared_asset_bucket_name

=== Effects
* The maven cache is downloaded and extracted to <tt>/root/.m2/</tt>
'
)
recipe(
  'mh-opsworks-recipes::maintenance-mode-off',
  'Sets matterhorn maintenance mode off for this node

=== Attributes
* none

=== Effects
* We send an API request to the admin node to turn off maintenance mode for
  this node
'
)
recipe(
    'mh-opsworks-recipes::install-ua-harvester',
    'installs the user analytics harvester as part of the ELK analytics

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_elk_info
* MhOpsworksRecipes::RecipeHelpers.get_rest_auth_info

=== Effects
* Install python, redis and run-one packages
* Create a ua_harvester user
* git checkout and install {mh-user-action-harvester}[https://github.com/harvard-dce/mh-user-action-harvester.git]
* set up a cron job to harvest actions every 2 minutes
* create an sqs queue for analytics processing
'
)
recipe(
  'mh-opsworks-recipes::configure-ua-harvester',
  'generates the .env configuration file for the useraction harvester

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_elk_info

=== Effects
* generates the .env config file
'
)
recipe(
  'mh-opsworks-recipes::remove-admin-indexes',
  'Remove solr indexes on the admin node

Remove the solr indexes from the admin node as part of resetting a cluster to a
pristine state.

This is part of the cluster seed infrastructure implemented in mh-opsworks.

=== Attributes
* none. Can only be run on a dev or testing cluster as defined by MhOpsworksRecipes::RecipeHelpers.dev_or_testing_cluster?

=== Effects
* Removes the solr index files on the admin node
'
)
recipe(
  'mh-opsworks-recipes::remove-engage-indexes',
  'Remove solr indexes on the engage node.

See <tt>mh-opsworks-recipes::remove-admin-indexes</tt>.
'
)
recipe(
  'mh-opsworks-recipes::install-mysql-backups',
  'Install mysql backups and metrics / alarms related to backup freshness

This runs as root and authenticates to mysql via the /root/.my.cnf written by
<tt>mh-opsworks-recipes::write-root-my-dot-cnf</tt>.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_info

=== Effects
* A daily full mysql dump is put on the shared storage directory
* A metric and alarm is added to ensure the daily backups are happening.
* Cron jobs are installed to ensure the backups and metrics happen
'
)
recipe(
  'mh-opsworks-recipes::install-elasticsearch',
  'install elasticsearch as part of the ELK user analytics stack

See mh-opsworks-recipes::install-kibana and the other ELK-related recipes for
more info.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_elk_info primarily

=== Effects
* configure the custom elasticsearch (and other related) repos
* install and configure elasticsearch and the python-elasticsearch-curator
* enable the elasticsearch service at boot
* install and configure kopf
* install our custom useractions template
* optionally enable dumping snapshots to an s3 bucket
'
)
recipe(
  'mh-opsworks-recipes::write-root-my-dot-cnf',
  'write a /root/.my.cnf on the node that connects to the database
  
=== Attributes
* <tt>node[:deploy][:matterhorn][:database]</tt>, the default opsworks database attributes

=== Effects
* Installs a <tt>/root/.my.cnf</tt> file that connects the root user on this
  node to the default matterhorn MySQL instance.
'
)
recipe(
  'mh-opsworks-recipes::symlink-nginx-log-dir',
  'Copies contents and symlinks /var/log/nginx to an alternate directory

=== Attributes
* <tt>node[:nginx_log_root_dir]</tt> The root directory for the new location.
  We create the <tt>nginx</tt> dir for you.
* <tt>node[:old_nginx_log_root_dir]</tt> The old root directory for the nginx logs. Defaults to <tt>/var/log/</tt>.

=== Effects
* Does not do anything if <tt>node[:old_nginx_log_root_dir]/nginx</tt> is already a symlink
* Copy the files from old_nginx_log_root_dir to nginx_log_root_dir
* Rename the old directory to <tt>node[:old_nginx_log_root_dir]/nginx_old</tt>
* Set up the symlink
* Reload nginx to bind logs correctly to the new dir
'
)
recipe(
  'mh-opsworks-recipes::configure-nginx-proxy',
  'A basic nginx proxy configuration

=== Attributes
* none

=== Effects
* Installs nginx
* Proxies *:80 back to localhost:8080
* Configures improved log rotation
* Sets up a <tt>/etc/nginx/proxy-includes</tt> directory to hold additional customizations
* Reloads nginx afterwards
'
)
recipe(
  'mh-opsworks-recipes::create-matterhorn-user',
  'Creates the matterhorn user

=== Attributes
* none

=== Effects
* Creates a matterhorn group and user
* Creates the <tt>/home/matterhorn/.ssh</tt> directory
'
)
recipe(
  'mh-opsworks-recipes::install-custom-metrics',
  'Installs metrics for disk, RAID sync, mysql availability, load, memory and others

=== Attributes
* None

=== Effects
* Installs scripts and cron jobs that submit metrics to cloudwatch
* Installs a mysql availability metric on the admin node (which should have a
  working <tt>/root/.my.cnf</tt> by default)
'
)
recipe(
  'mh-opsworks-recipes::clean-up-package-cache',
  'Cleans up the cached dpkgs to save disk space

=== Attributes
* none

=== Effects
* Cleans up the package cache
'
)
recipe(
  'mh-opsworks-recipes::install-logstash-kibana',
  'Installs kibana and logstash

This runs <tt>mh-opsworks-recipes::install-kibana</tt> and
<tt>mh-opsworks-recipes::install-logstash</tt>
'
)
recipe(
  'mh-opsworks-recipes::remove-legacy-deploy-dir',
  'Allows you to remove a legacy deploy dir when changing where matterhorn is deployed

=== Attributes
* <tt>node[:legacy_deploy_root]</tt>

=== Effects
* Removes the /releases, /shared, and /current dirs and symlinks under
  <tt>node[:legacy_deploy_root]</tt>
'
)
recipe(
  'mh-opsworks-recipes::install-mh-base-packages',
  'Install base packages for matterhorn nodes

=== Attributes
* none

=== Effects
* Installs openjdk, python, etc.
* Installs nodejs via <tt>mh-opsworks-recipes::install-nodejs</tt>
'
)
recipe(
  'mh-opsworks-recipes::create-cluster-seed-file',
  'Creates a cluster seed from the current cluster to be applied to a different cluster

=== Attributes
* Many, mostly about the current cluster.

This should only be run on development clusters, as defined by
MhOpsworksRecipes::RecipeHelpers.dev_or_testing_cluster?

=== Effects
* A seed file including the files, database, and a manifest of the current cluster config is created
* This is uploaded to an s3 bucket as defined by <tt>node[:cluster_seed_bucket_name]</tt>
'
)
recipe(
  'mh-opsworks-recipes::enable-postfix-smarthost',
  'Enables a postfix smarthost through a configured SES endpoint

This allows you to send email directly over the SMTP server on localhost via
the postfix smarthost.

=== Attributes
* <tt>node[:smtp_auth]</tt>

=== Effects
* postfix is installed
* postfix is configured to relay over the SES endpoint (or other SMTP server)
  as defined in <tt>node[:smtp_auth]</tt>
* postfix is reload afterwards.
'
)
recipe(
  'mh-opsworks-recipes::create-file-uploader-user',
  'Creates a system to allow for the direct upload of files into the matterhorn inbox

=== Attributes
* <tt>node[:file_uploader_public_ssh_key]</tt>
* MhOpsworksRecipes::RecipeHelpers.get_storage_info
* MhOpsworksRecipes::RecipeHelpers.get_shared_storage_root

=== Effects
* Installs rsync
* Creates the <tt>rsync_uploads</tt> dir on the nfs export
* Creates a <tt>file_uploader</tt> user
* Installs a "forced command" ssh key that allows the <tt>file_uploader</tt>
  use to upload via rsync to the <tt>rsync_uploads</tt> dir
* Install a cron job to move uploads into the matterhorn inbox
* Install a cron job to remove stale unfinished uploads
'
)
recipe(
  'mh-opsworks-recipes::monitor-matterhorn-daemon',
  'Add metrics and alarms to monitor the status of the matterhorn daemon

Installs metrics, alarms, and cron jobs that monitoring the matterhorn daemon
if we are on aws

=== Attributes
* none

=== Effects
* Install a metric script
* Install a cron job to run it
* Create a cloudwatch alarm hitched up to the matterhorn availability metric
'
)
recipe(
  'mh-opsworks-recipes::set-bash-as-default-shell',
  'Sets bash (instead of dash) as the default shell

Ubuntu uses dash (instead of bash) as the default non-interactive shell. It is supposedly fully bash compatible but - surprise! Nope.

=== Attributes
* none

=== Effects
* sets bash instead of dash as the default non-interactive shell
'
)
recipe(
  'mh-opsworks-recipes::configure-elk-nginx-proxy',
  'Sets up an nginx proxy that allows connections to elasticsearch on the local network

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_elk_info primarily

=== Effects
* A configured and restarted nginx linked to elasticsearch
* HTTP basic auth protection for the kibana interface
'
)
recipe(
  'mh-opsworks-recipes::enable-enhanced-networking',
  'Compile and install an updated network driver to enable full nic speed

This downloads resources from the <tt>shared_asset_bucket</tt> and uses them to
compile and install an updated driver to enable full network speed. If we
already have the driver installed, nothing happens.

=== Attributes
* <tt>node[:ixgbevf_version]</tt> the desired driver version
* <tt>MhOpsworksRecipes::RecipeHelpers.get_shared_asset_bucket_name

=== Effects
* The new driver is installed and you must restart. This driver is in the
  default AMI so you should be good.
'
)
recipe(
  'mh-opsworks-recipes::install-job-queued-metrics',
  'Install a matterhorn jobs queued metric. Part of the experimental horizontal scaling feature

This uses pyhorn and some logic to count the number of queued jobs, and then
spins up workers when we see jobs starting to stack up.

=== Attributes
* <tt>node[:scale_up_when_queued_jobs_gt]</tt> Start another worker when there is more than this number of jobs waiting to be processed

=== Effects
* Installs a metric and alarm to hook into the opsworks custom scaling functionality
'
)
recipe(
  'mh-opsworks-recipes::remove-all-matterhorn-files',
  'Removes all matterhorn files on shared storage and distributed to s3

This removes all files from the clusters shared nfs mount and distributed to
s3.  You probably should not use this directly.

This is part of the cluster seed infrastructure implemented in mh-opsworks.

This should only be run on development clusters, as defined by
MhOpsworksRecipes::RecipeHelpers.dev_or_testing_cluster?

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_info and get_shared_storage_root

=== Effects
* File are removed locally and on s3
'
)
recipe(
  'mh-opsworks-recipes::install-moscaler',
  'Installs the mo-scaler horizontal scaling manager

Depending on `custom_json` settings, will configure mo-scaler using either a time-based
scaling strategy or one of the auto-scaling methods.

=== Attributes
* <tt>node[:moscaler]</tt> - defines several options. See the recipe for more details.

=== Effects
* Creates the moscaler user
* Installs mo-scaler
* Generates a `.env` file in /home/moscaler/mo-scaler based on attributes defined in <tt>node[:moscaler]</tt>
* Sets up cron jobs to scale according to the attributes defined in <tt>node[:moscaler]</tt>
'
)
recipe(
  'mh-opsworks-recipes::create-metrics-dependencies',
  'Installs shared code used by all cloudwatch metrics scripts

=== Attributes
* none

=== Effects
* Installs the shared cloudwatch metrics script used to define the region and
  base namespace
'
)
recipe(
  'mh-opsworks-recipes::register-matterhorn-to-boot',
  'FIXME'
)
recipe(
  'mh-opsworks-recipes::configure-engage-nginx-proxy',
  'Configure the nginx proxy on the engage node

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_info and get_shared_storage_root

=== Effects
* Configures an nginx proxy, including access to the transcoded files on the filesystem
* Reloads nginx after configuration
'
)
recipe(
  'mh-opsworks-recipes::create-matterhorn-directories',
  'Creates the base directories for matterhorn

This ensure the base directories on this node are created with the correct
permissions both for our local workspace and on the nfs shared directory

=== Attributes
* <tt>MhOpsworksRecipes::RecipeHelpers.get_local_workspace_root</tt> and others related to file paths

=== Effects
* Creates the directories and ensures they are owned by the matterhorn user.
'
)
recipe(
  'mh-opsworks-recipes::update-nginx-config-for-ganglia',
  'Updates the nginx proxy (probably on the admin node) to link <tt>/ganglia</tt> to the ganglia node

This runs during the "configure" lifecycle event.

=== Attributes
* none

=== Effects
* Installs the ganglia proxy config when the ganglia node is present
* Reloads the nginx service
'
)
recipe(
  'mh-opsworks-recipes::update-host-based-configurations',
  'Updates matterhorn nodes with the public admin and engage hostnames

This is probably no longer necessary. It updates the public engage and admin
hostnames during the configuration lifecycle event, the idea being that we
would spin up all nodes simultaneously and then start matterhorn at the end.

=== Attributes
* MhOpsworksRecipes::DeployHelpers.install_multitenancy_config
* MhOpsworksRecipes::RecipeHelpers.get_public_engage_hostname
* MhOpsworksRecipes::RecipeHelpers.get_public_admin_hostname

=== Effects
* updates etc/config.properties with hostnames
'
)
recipe(
  'mh-opsworks-recipes::create-alerts-from-opsworks-metrics',
  'Creates alerts for nodes from custom and built-in cloudwatch metrics

This is run during the setup phase of the opsworks lifecycle and adds
cloudwatch alarms for an instance. Some alarms have limits calculated on the
instance size (load) while others are simply percentages (disk, nfs).

=== Attributes
* Many, mostly from MhOpsworksRecipes::RecipeHelpers

=== Effects
* cloudwatch alarms are created
* They are removed when the instance shuts down.
'
)
recipe(
  'mh-opsworks-recipes::convert-mysql-to-multiple-data-files',
  'Converts MySQL innodb to use a file per table rather than one big one

This is not relevant for RDS database and is only useful for a self-hosted
MySQL database. It should be run during the setup lifecycle event.

=== Attributes
* <tt>node[:deploy][:matterhorn][:database]</tt>, the default opsworks database attributes

=== Effects
* MySQL is converted to use a single file per innodb table
* This only happens if the database install is brand new and the main
  matterhorn database has not been created.
'
)
recipe(
  'mh-opsworks-recipes::create-squid-proxy-for-storage-cluster',
  'Create a squid proxy to use for zadara s3 backups

This is used as a bridge between our zadara controller and the s3 bucket used
for s3-backed snapshot storage.

{More information
here}[https://support.zadarastorage.com/entries/69891364-Setup-Backup-To-S3-B2S3-Through-a-Proxy-In-Your-AWS-VPC]
and README.zadara.md in mh-opsworks.

=== Attributes
* MhOpsworksRecipes::RecipeHelpers.get_storage_hostname

=== Effects
* squid3 is installed
* squid3 is configured to allow proxy requests from the zadara controller
* squid3 is restarted to apply the new proxy config.
'
)
recipe(
  'mh-opsworks-recipes::configure-capture-agent-manager-gunicorn',
  'Sets up start script for gunicorn with capture-agent-manager app

This is relevant for the utility node, where the capture-agent-manager `cadash`
should run.

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_app_name
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* gunicorn installed under the virtualenv for the capture-agent-manager-app root dir
  (usually /home/user/sites/<app>/venv)
* script to start gunicorn running the capture-agent-manager-app under app root dir
'
)
recipe(
  'mh-opsworks-recipes::configure-capture-agent-manager-nginx-proxy',
  'Sets up an nginx proxy that allows connections to flask-gunicorn apps via https-only

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_app_name
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* A configured and restarted nginx linked to flask-gunicorn capture-agent-manager app
* HTTPS-only setup
'
)
recipe(
  'mh-opsworks-recipes::configure-capture-agent-manager-supervisor',
  'Installs and sets up supervisor for gunicorn apps to run as service-daemon

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_app_name
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* configured capture-agent-manager app as a supervisor task under `/etc/supervisord/conf.d/<app>.conf`
* supervisor restarted
'
)
recipe(
  'mh-opsworks-recipes::create-capture-agent-manager-directories',
  'Creates directories(logs, app, etc) for capture-agent-manager flask-gunicorn app

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* directories for app(sites), logs, sock created under capture-agent-manager user
'
)
recipe(
  'mh-opsworks-recipes::create-capture-agent-manager-user',
  'Create user and group to run capture-agent-manager flask-gunicorn app as

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* capture-agent-manager user and group created
* .ssh dir in home dir
'
)
recipe(
  'mh-opsworks-recipes::install-capture-agent-manager-packages',
  'Installs packages specific to the capture-agent-manager

=== attributes
none

=== effects
* packages needed for capture-agent-manager app to run like: redis, nginx, python,
  and supervisor, among others
* the package cache is cleared to save space
'
)
recipe(
  'mh-opsworks-recipes::install-capture-agent-manager',
  'Sets up flask-gunicorn app for capture-agent-manager

=== attributes
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_info
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_app_name
* MhOpsworksRecipes::RecipeHelpers.get_capture_agent_manager_usr_name

=== effects
* capture-agent-manager app cloned or checked out under capture-agent-manager `$HOME/sites`
* environment vars for capture-agent-manager app are configured in a source file
* pip dependencies installed in virtualenv under capture-agent-manager `$HOME/sites/venv`
* configured logrotate file for capture-agent-manager app log
'
)
recipe(
    'mh-opsworks-recipes::install-cwlogs',
    'Installs the AWS Cloudwatch Log Agent and configures some basic log streams

=== attributes
* MhOpsworksRecipes::RecipeHelpers.configure_cloudwatch_log
* MhOpsworksRecipes::RecipeHelpers.configure_nginx_cloudwatch_logs

=== effects
* installs the cloudwatch log agent
* creates log stream configurations for syslog, matterhorn.log and nginx logs on appropriate nodes
'
)

depends 'nfs', '~> 2.1.0'
depends 'apt', '~> 2.9.2'
depends 'cron', '~> 1.6.1'
depends 'nodejs', '~> 2.4.4'
