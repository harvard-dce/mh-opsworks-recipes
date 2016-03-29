# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-logstash-kibana

include_recipe 'mh-opsworks-recipes::install-kibana'
include_recipe 'mh-opsworks-recipes::install-logstash'
