# CHANGELOG

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
