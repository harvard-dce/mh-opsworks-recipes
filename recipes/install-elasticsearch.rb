# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-elasticsearch

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info

es_major_version = elk_info[:es_major_version]
es_version = elk_info[:es_version]
es_cluster_name = elk_info[:es_cluster_name]
index_template_path = "#{::Chef::Config[:file_cache_path]}/index-template.json" 

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
end.run_action(:create)

template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  variables({
    cluster_name: es_cluster_name
  })
end

execute 'service elasticsearch restart'

cookbook_file "index-template.json" do
  path index_template_path
  source "index-template.json"
end.run_action(:create)

http_request "put index template" do
  url 'http://localhost:9200/_template/dce'
  message ::File.read(index_template_path)
  action :put
  retries 5
  retry_delay 30
end

