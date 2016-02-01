# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-logstash

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

logstash_major_version = elk_info[:logstash_major_version]
logstash_version = elk_info[:logstash_version]

apt_repository 'logstash' do
  uri "http://packages.elasticsearch.org/logstash/#{logstash_major_version}/debian"
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package("logstash=#{logstash_version}")

cookbook_file "/etc/default/logstash" do
  source "logstash-default"
  owner 'root'
  group 'root'
  mode '644'
end

