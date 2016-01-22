# CHANGELOG

## TO BE RELEASED

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
