# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-elasticsearch

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

es_major_version = elk_info[:es_major_version]
es_version = elk_info[:es_version]
es_cluster_name = elk_info[:es_cluster_name]
data_path = elk_info[:es_data_path]

apt_repository 'elasticsearch' do
  uri "http://packages.elasticsearch.org/elasticsearch/#{es_major_version}/debian"
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package("elasticsearch=#{es_version}")

execute "install kopf plugin" do
  not_if { ::Dir.exist?("/usr/share/elasticsearch/plugins/kopf") }
  command '/usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf/2.0'
  timeout 30
  retries 5
  retry_delay 10
end

cookbook_file "kopf_external_settings.json" do
  path '/usr/share/elasticsearch/plugins/kopf/_site/kopf_external_settings.json'
  source "kopf_external_settings.json"
  owner 'root'
  group 'root'
  mode '644'
end.run_action(:create)

template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    cluster_name: es_cluster_name,
    data_path: data_path
  })
end

execute 'service elasticsearch restart'

directory "/etc/elasticsearch/templates" do
  owner 'root'
  group 'root'
  mode '755'
end.run_action(:create)

cookbook_file "/etc/elasticsearch/templates/useractions.json" do
  source "useractions.json"
  owner 'root'
  group 'root'
  mode '644'
end.run_action(:create)

http_request "delete existing templates" do
  url 'http://localhost:9200/_template/dce-*'
  action :delete
  retries 2
  retry_delay 30
  ignore_failure true
end

http_request "put index template" do
  url 'http://localhost:9200/_template/dce-useractions'
  message ::File.read("/etc/elasticsearch/templates/useractions.json")
  action :put
  retries 2
  retry_delay 30
end

