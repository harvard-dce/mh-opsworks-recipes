# CHANGELOG

## TO BE RELEASED

* Fix the squid3 proxy ACL to correct rules for s3 endpoints - the zadara docs
  were very, very wrong. This does not require an explicit chef recipe run.

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
