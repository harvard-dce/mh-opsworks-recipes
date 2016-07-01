# CHANGELOG

## TO BE RELEASED

## 1.7.0 - 7/5/2016

* Added stack short name to config.properties so that we can show the cluster name when sending notification emails.  

## 1.6.0 - 6/24/2016

* Configuration for the newrelic is now different for each layer (admin,work,engage)
"stack": {
    "chef": {
    "custom_json": {
      "newrelic": {
        "admin": { "key": "admin_newrelic_key" },
        "workers": { "key": "worker_newrelic_key" }
      }
    ...
If the newrelic key or a layer name is omitted, new relic will not be run for the stack or the layer.
all-in-one deployment will use admin key.

## 1.5.0 - 6/10/2016

* Configuration for the new Matterhorn aws s3 file archive service (s3 bucket name).
* *[OPTIONAL]* Changes to the `install-ua-harvester` recipe. Changed naming path 
  of the s3 bucket used to store the useraction harvester's last action timestamp 
  value. Only relevant for analytics node and only affects new clusters. Also 
  bumped harvest batch size from the default 1000/per

## 1.4.0 - 6/8/2016

* *[OPTIONAL]* Recipes to install and configure the utility node to host the
  capture-agent-manager flask-gunicorn webapp. The utility node is optional and
  only for DCE production cluster.

* *[OPTIONAL] EDITS TO THE CLUSTER CONFIG* *REQUIRES MANUAL CHEF RECIPE RUNS*:
  recipes, etc to install and configure the utility node to host the capture-agent
  manager flask-gunicorn webapp. See README.capture-agent-manager.md in
  mh-opsworks for setup instructions.

  The manual recipe run can be executed any time since they affect only the
  utility node

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Utility"
        recipes="mh-opsworks-recipes::create-capture-agent-manager-user,mh-opsworks-recipes::create-capture-agent-manager-directories,mh-opsworks-recipes:install-capture-agent-manager-packages,mh-opsworks-recipes:install-capture-agent-manager,mh-opsworks-recipes:configure-capture-agent-manager-gunicorn,mh-opsworks-recipes:configure-capture-agent-manager-nginx-proxy,mh-opsworks-recipes:configure-capture-agent-manager-supervisor"


## 1.3.3 - 5/19/2016

* Fix `mh-opsworks-recipes::install-ec2-scaling-manager` to correctly update
  the cron jobs when run. Implement basic serverspec tests to ensure the
  default attributes and a run with customized attributes works. Nothing to
  run.
* Fix all-in-one node provisioning, primarily for local vagrant development.
  Nothing to run.
* Only update apt repo if it's more than 30 minutes old. Nothing to be run.
* Recipe level docs. There are no functional changes in this feature. Nothing
  to run.
* Implement foodcritic linting via [travis](https://travis-ci.org). Nothing to
  run.
* Use the service resource to idiomatically start services. Nothing to run, just
  make sure that matterhorn starts correctly after a deploy.
* Fix and improve test-kitchen bats tests. Nothing to run.
* Better docs.

## 1.3.2 - 4/22/2016

* Local opsworks cluster support, in concert with changes made to mh-opsworks
  proper.  Modify some chef recipes to only run functions when on AWS. Nothing
  is required to be run outside of a normal deploy. See `README.local-opsworks.md`
  in mh-opsworks for full info on how this feature works.

## 1.3.1 - 4/14/2016

* Start matterhorn at boot via cron's @reboot functionality. Runs automatically
  as part of a deploy.
* *REQUIRES MANUAL CHEF RECIPE RUNS* * MUST BE RUN BEFORE THE DEPLOY*
  Change the `dont_start_matterhorn_after_deploy` stack `custom_json` override
  to `dont_start_matterhorn_automatically` because it has a larger scope now.
  When set to `true`, this allows you to start ec2 instances without starting the
  matterhorn daemon.  This hooks into the init script (no other way, really) and
  will prevent matterhorn from booting until you unset it or set it to `false`.
  That's a lot of scary words for something that'll only impact you if you
  explictly use it. If you want to start matterhorn after disabling it with the
  variable, you: 1) remove or edit the variable in your cluster config via
  "cluster:edit", and 2) run "matterhorn:restart" via the mh-opsworks tooling.
  Using the mh-opsworks tooling will propagate the `custom_json` change and
  ensure matterhorn can start properly.

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin, Workers, Engage" recipes="mh-opsworks-recipes::install-mh-base-packages"

## 1.3.0 - 4/7/2016

* *REQUIRES MANUAL CHEF RECIPES RUNS* *MUST BE RUN BEFORE THE DEPLOY*  Update the
  version of node on the cluster to work around an npm / gzipping bug.

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin, Workers, Engage" recipes="mh-opsworks-recipes::install-mh-base-packages"

* *REQUIRES MANUAL CHEF RECIPE RUNS* Hang more alarms on database metrics to catch
  problems relating to disk IO. Lower the CPU threshold.  This can be done any
  time before or after a deploy.

        # This is currently on the "Ganglia" layer in prod,
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="mh-opsworks-recipes::create-mysql-alarms"

* *REQUIRES MANUAL CHEF RECIPE RUNS* Add a metric and alarm to check if
  instances fail to start up. This can be done any time before or after a
  deploy.

        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::install-custom-metrics,mh-opsworks-recipes::create-alerts-from-opsworks-metrics"

* *OPTIONAL EDITS TO THE CLUSTER CONFIG* *REQUIRES MANUAL CHEF RECIPE RUNS*:
  Recipes, etc for setting up Analytics layer/node. See README.analytics.md in
  mh-opsworks for setup instructions.
  The manual recipe run can be executed any time after a successful deploy.

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Engage" recipes="mh-opsworks-recipes::configure-engage-nginx-proxy"

## 1.2.0 - 3/23/2016

* Allow for cluster state to be turned into a "seed file" and applied to
  another cluster.  See `README.cluster_seed_files.txt` in
  https://github.com/harvard-dce/mh-opsworks/ for more information on how this
  feature works. Does not require specific chef recipes be run for a
  deployment.
* Fix the squid3 proxy ACL to correct rules for s3 endpoints - the zadara docs
  were very, very wrong. This does not require an explicit chef recipe run.
* *REQUIRES MANUAL CHEF RECIPE RUNS*:
  Updated loggly TLS certificate. Manual recipe run can be executed any time
  after a successful deploy.

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin, Workers, Engage" recipes="mh-opsworks-recipes::rsyslog-to-loggly"

## 1.1.6 - 3/3/2016

* *REQUIRES EDITS TO THE CLUSTER CONFIG* *REQUIRES MANUAL CHEF RECIPE RUNS*:
  Before doing a deploy and after the morning scaled instances have started,
  you must edit the production cluster config `custom_json` to set:

        "matterhorn_repo_root": "/opt/matterhorn/deploy",
        "nginx_log_root_dir": "/opt/matterhorn",

  `matterhorn_repo_root` already exists and should be updated -
  `nginx_log_root_dir` is new and should be created. Proceed to update chef
  recipes and do your deploy normally after that.

  This new feature clarifies the name of the deployed app and allows it to
  easily be moved into a separate subdirectory under /opt/matterhorn.  The manual
  recipe run below can be run at any time after a successful deploy.

        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin, Workers, Engage" recipes="mh-opsworks-recipes::remove-legacy-deploy-dir"

* *REQUIRES MANUAL CHEF RECIPE RUNS*: Open up nginx logs to be world-readable
  by default. This happens post daily log rotation

        # After the recipes have been updated. . .
        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::configure-nginx-proxy" layers="Admin, Workers"
        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::configure-engage-nginx-proxy" layers="Engage"

## 1.1.5 - 2/25/2016

* Create a squid3 proxy to be used by the zadara storage array to get to s3 for
  object store backups.  See
  [mh-opsworks](https://github.com/harvard-dce/mh-opsworks/blob/master/README.zadara.md)
  for more information about how to use this recipe. This recipe is independent
  of deployments.

* *REQUIRES MANUAL CHEF RECIPE RUNS:* Set the bash prompt to be in color and
  put the cluster name in there. When a cluster includes "production" in the
  name, make it red so that users know they're working in production.  This is
  not tied to deployment and can be run at any time

        ./bin/rake stack:commands:execute_recipes_on_instances recipes="mh-opsworks-recipes::set-bash-as-default-shell"

* *REQUIRES MANUAL CHEF RECIPE RUNS*: This recipe can be run at any time and
  is deploy independent.  Switch to daily mysql backups as a way of having a
  historical record of database state. RDS gives you the ability to restore to
  any point in time back to the beginning of your retention period (30 days for
  production), obviating the value and pretty major resource drain hourly MySQL
  dumps impose on production. Be sure to confirm which layer you're running
  your mysql backups on before running the command below:

        # This is currently on the "Ganglia" layer in prod,
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="mh-opsworks-recipes::install-mysql-backups"

* Ignore 401s in newrelic logging.

## 1.1.4 - 2/18/2016

* *REQUIRES MANUAL CHEF RECIPE RUNS*: Copy and symlink the nginx log dir to
  /opt/matterhorn/nginx. This should be registered into the engage layer's
  `setup` recipes and run whenever. It does not have to be run during a deploy.

        ./bin/rake stack:commands:execute_recipes_on_instances recipes="mh-opsworks-recipes::symlink-nginx-log-dir" hostnames="engage1"

  Remove the `/var/log/nginx_old` directory after you've manually confirmed logs
  are going to the right place.
* Allow java unit tests to be run during a (re)deploy. They do not run by
  default.  If you want to run them by default for all deploys set
  `skip_java_unit_tests` to `false` in your cluster config's `custom_json`
  config. You can run unit tests manually via the
  `deployment:redeploy_app_with_unit_tests` rake task.
* *REQUIRES MANUAL CHEF RECIPE RUNS*: Use maven3 instead of maven2, prepares us
  for matterhorn 1.6.x

    # Right before the deploy. . .
        ./bin/rake stack:commands:update_chef_recipes stack:commands:execute_recipes_on_layers layers="Admin, Workers, Engage" recipes="mh-opsworks-recipes::install-mh-base-packages"

* *REQUIRES MANUAL CHEF RECIPE RUNS* Install a cloudwatch metric and alarm to
  track nfs mount space available. Does not require anything to be done during
  a deployment.

        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::install-custom-metrics,mh-opsworks-recipes::create-alerts-from-opsworks-metrics"

* Install awscli directly, without the awscli recipe. Simplifies dependencies
  significantly. Does not require manual chef recipe runs, it'll run
  automatically when needed by other recipes.

## 1.1.3 - 2/17/2016

* HOTFIX - define dependencies better to ensure we stay with chef 11 compatible
  cookbooks. Fixes `awscli` cookbook which depends on the broken
  `build-essential` cookbook.

## 1.1.2 - 2/10/2016

* Allow the "create-file-uploader-user" recipe to fail, to work around
  mysterious "usermod: no options" chef bug. Does not require anything to be
  done during a deployment. The recipe always works the first time it's run, it's
  just the second time that we sometimes see this failure.

## 1.1.1 - 2/3/2016

* Allow java debug to be set to `true` or `false` via the `java_debug_enabled`
  stack `custom_json` parameter. It currently defaults to "true" (so, enabled)
  because most clusters are going to be development or testing clusters.
* Install the newrelic agent when '{"newrelic": {"key": "your key"}' is
  included in the stack's `custom_json`. See the main mh-opsworks README for
  info.
* *REQUIRES MANUAL CHEF RECIPE RUNS* Make the mysql dumps more bandwidth
  efficient by using "--compress" on the mysqldump client and an inline gzip
  when saving to shared storage. This causes bandwidth during mysql dumps to
  drop by 4 or 5 times without an appreciable performance penalty.  This recipe
  can by run at any time, be sure to confirm the instance your dumps are
  happening on by finding this recipe in your active cluster config.

        # This is currently on the "Ganglia" layer in prod,
        # the value below is for dev clusters.
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin" recipes="mh-opsworks-recipes::install-mysql-backups"
* *REQUIRES OPTIONAL CHEF RECIPE RUNS*  Installs the `file_uploader` user onto
  the instance of your choice. This allows you to use an rsync backchannel for
  uploads directly to the matterhorn inbox in combination with a couple cron jobs
  to copy and maintain these uploads. If you want to use this feature, add it to
  the setup lifecycle in the appropriate layer in your cluster config and then
  run this recipe.  This recipe does not need to be run at any particular time
  relative to a deployment.

        # The current value for the admin node
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin" recipes="mh-opsworks-recipes::create-file-uploader-user"

## 1.1.0 - 1/28/2016

* All clusters should now include a `private_assets_bucket_name` in their
  cluster config, which can be the same as the `cluster_config_bucket_name` as
  that's a private bucket too and includes some shared assets.
* *REQUIRES CHEF RECIPE RUNS* Rotate nginx logs more aggressively than a week,
  but still keep a year. All this change does is install a new logrotate file,
  overriding the default. The recipes can be run whenever.

        # After the recipes have been updated. . .
        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::configure-nginx-proxy" layers="Admin, Workers"
        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::configure-engage-nginx-proxy" layers="Engage"

* *REQUIRES MANUAL CHEF RECIPE RUNS* Remove the "ok-action" alarms - they are
  too chatty and not useful. These recipe runs can happen post-deploy.

        ./bin/rake stack:commands:execute_recipes_on_layers recipes="mh-opsworks-recipes::create-alerts-from-opsworks-metrics"
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Ganglia" recipes="mh-opsworks-recipes::create-mysql-alarms"
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin" recipes="mh-opsworks-recipes::install-mysql-backups"
        ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin,Workers,Engage,Utility,Asset Server" recipes="mh-opsworks-recipes::nfs-client"

  Be sure to double-check all layers and recipe combinations.

## 1.0.7 - 1/21/2016

* Clean up s3 distribution configuration. Remove asset server hooks.
* *REQUIRES MANUAL CHEF RECIPE RUNS* engage nginx uid cookie & usertracking
  session id + uid log for identifying shopping period viewers
* *REQUIRES MANUAL CHEF RECIPE RUNS* Use mo-scaler --scale-available option

## 1.0.6 - 1/18/2016

* Configuration for the new Matterhorn S3 distribution service.

## 1.0.5 - 1/14/2016

* Hot fix for Otherpubs sevice config

## 1.0.4 - 1/14/2016

* *REQUIRES MANUAL CHEF RECIPE RUNS* Send X-Forwarded-For header from the nginx
  proxies so that user-tracking gets correct client ip
* Get rid of the no longer necessary ffmpeg package removal
* Modify `mh_default` and otherpubs config for MATT-1822 auto populate admin UI upload

## 1.0.3 - 1/8/2016

* Fix find's mtime invocation to ensure we're compressing and reaping files at
  the correct times. *Requires that the MySQL backup installation chef recipe be
  run on the admin node.*
* Relax the `matterhorn_availability` alert to require errors over two 2 minute
  periods instead of just one.
* Modify the matterhorn init script to check that the daemon started properly,
  working around the race condition related to bundle loading. See the relevant
  commit for details.

## 1.0.2 - 1/6/2016

* Only set the `org.opencastproject.server.maxload` property on worker nodes -
  all other nodes can have an unlimited number of jobs.

## 1.0.1 - 1/5/2016

* Allow the default "start matterhorn if it's not running after deploy" to be
  overridden via the `:dont_start_matterhorn_after_deploy` chef `custom_json`
  attribute.

## 1.0.0 - 1/4/2016

* Initial release
