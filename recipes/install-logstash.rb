# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-logstash

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

logstash_major_version = elk_info['logstash_major_version']
logstash_repo_uri = elk_info['logstash_repo_uri']

apt_repository 'logstash' do
  uri logstash_repo_uri
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "mh-opsworks-recipes::update-package-repo"
pin_package("logstash", "#{logstash_major_version}.*")
install_package("logstash")

cookbook_file "/etc/default/logstash" do
  source "logstash-default"
  owner 'root'
  group 'root'
  mode '644'
end

