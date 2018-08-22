# CHANGELOG for 5.x development

This log is structured differently from the base `CHANGELOG.md`.

* There is no **TO BE RELEASED** section
* Entries should be headed with just a date; no version numbers

## 08/22/2018

* upgrade pip during moscaler install to handle improved `requirements.txt` dependency format

## 08/10/2018

* activemq & nginx service fixes:
    * update to latest, stable activemq
    * fix for MI-86: activemq/opencast communication borked on first cluster start
    * reworking of nginx recipes to ensure config reloads happen on e.g. ssl cert updates

## 08/02/2018

* cherry-picking a fix for the ua-harvester dependency installation
  note: this commit included some unrelated CHANGELOG updates

## 07/23/2018

* fixing the enabling logic for the earlier newrelic changes

## 07/18/2018

* only run the squid install recipe if external storage (i.e. zadara) is being used

## 07/12/2018

* *REQUIRES MANUAL RECIPE RUN*
  install latest stable nginx & disable `proxy_request_buffering` for admin nginx to allow direct streaming of uploads. 
  For an existing cluster you can either reboot the cluster, or, if that's not desired, the various nginx recipes must be run:
  ```bash
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin" recipes="oc-opsworks-recipes::configure-nginx-proxy"
  ```
  ```bash
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Engage" recipes="oc-opsworks-recipes::configure-engage-nginx-proxy"
  ```
  If you have an analytics node:
  ```bash
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Analytics" recipes="oc-opsworks-recipes::configure-elk-nginx-proxy"
  ```

## 07/11/2018

* *REQUIRES MANUAL RECIPE RUN* *REQUIRES EDITS TO CLUSTER CONFIG*
  OPC-97: install newrelic via recipe. 
  To enable newrelic in a cluster the custom json must include a block like:
  ```
    "newrelic": {
      "agent_version": "4.2.0",
      "admin": {
        "key": "xxxxx"
      },
      "engage": {
        "key": "xxxxx"
      },
    },
  ```
  For an existing cluster you must then execute the install recipe, either manually (command below) or by adding it to the layer's "setup" recipe run list in the cluster config and restarting the cluster instances:
  ```bash
    ./bin/rake stack:commands:execute_recipes_on_layers layers="Admin,Engage" recipes="oc-opsworks-recipes::install-newrelic"
  ```
  **Then** you must also execute a deploy so that the opencast init scripts get updated as well:
  `./bin/rake deployment:redeploy_app opencast:restart`


