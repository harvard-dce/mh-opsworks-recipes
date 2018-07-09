# CHANGELOG for 5.x development

This log is structured differently from the base `CHANGELOG.md`.

* There is no **TO BE RELEASED** section
* Entries should be headed with just a date; no version numbers

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


