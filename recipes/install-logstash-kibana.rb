# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-logstash-kibana

include_recipe 'oc-opsworks-recipes::install-logstash'
include_recipe 'oc-opsworks-recipes::install-kibana'
include_recipe 'oc-opsworks-recipes::configure-elk-nginx-proxy'
