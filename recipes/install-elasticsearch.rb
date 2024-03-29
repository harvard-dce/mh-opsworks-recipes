# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-elasticsearch

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
::Chef::Recipe.send(:include, MhOpsworksRecipes::DeployHelpers)
::Chef::Resource::RubyBlock.send(:include, MhOpsworksRecipes::RecipeHelpers)

elk_info = get_elk_info
es_cluster_name = elk_info['es_cluster_name']
data_path = elk_info['es_data_path']
es_heap_size = xmx_ram_for_this_node(0.5)
es_host = node[:opsworks][:instance][:private_ip]
region = node[:opsworks][:instance][:region]
stack_name = stack_shortname
enable_snapshots = elk_info['es_enable_snapshots']
es_snapshot_bucket = "#{stack_name}-snapshots"

yum_repository 'elasticsearch' do
  description "Elasticsearch 2.x packages"
  baseurl "http://packages.elastic.co/elasticsearch/2.x/centos"
  action :create
  gpgkey "http://packages.elastic.co/GPG-KEY-elasticsearch"
end

yum_repository 'curator' do
  description "Elasticsearch Curator 3.x packages"
  baseurl "http://packages.elastic.co/curator/3/centos/6"
  action :create
  gpgkey "http://packages.elastic.co/GPG-KEY-elasticsearch"
end

include_recipe "oc-opsworks-recipes::update-package-repo"
install_package("java-1.8.0-openjdk java-1.8.0-openjdk-devel elasticsearch")
pip_install("elasticsearch-curator==3.5.1")

service 'elasticsearch' do
  action :enable
  supports :restart => true
  provider Chef::Provider::Service::Systemd
end

{
  "kopf" => "lmenezes/elasticsearch-kopf/2.0",
  "cloud-aws" => "cloud-aws"
}.each do |plugin_name, install_name|
  execute "uninstall existing #{plugin_name} plugin" do
    only_if { ::Dir.exist?("/usr/share/elasticsearch/plugins/#{plugin_name}") }
    command "/usr/share/elasticsearch/bin/plugin remove #{plugin_name}"
    timeout 10
    retries 5
    retry_delay 10
  end
  execute "install #{plugin_name} plugin" do
    command "/usr/share/elasticsearch/bin/plugin install -b #{install_name}"
    timeout 30
    retries 5
    retry_delay 10
  end
end

cookbook_file "kopf_settings" do
  path '/usr/share/elasticsearch/plugins/kopf/_site/kopf_external_settings.json'
  source "kopf_external_settings.json"
  owner 'root'
  group 'root'
  mode '644'
end

template '/etc/sysconfig/elasticsearch' do
  source 'elasticsearch-sysconfig.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    heap_size: es_heap_size
  })
end

directory "create elasticsearch data dir" do
  path data_path
  owner 'elasticsearch'
  group 'elasticsearch'
  mode '755'
  recursive true
end

cookbook_file 'elasticsearch-logging.yml' do
  path '/etc/elasticsearch/logging.yml'
  owner 'root'
  group 'root'
  mode '644'
end

cookbook_file 'elasticsearch-logrotate.conf' do
  path '/etc/logrotate.d/elasticsearch'
  owner 'root'
  group 'root'
  mode '644'
end

template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    cluster_name: es_cluster_name,
    data_path: data_path,
    es_host: es_host,
    aws_region: region
  })
  notifies :restart, "service[elasticsearch]", :immediately
end

directory "template_dir" do
  path "/etc/elasticsearch/templates"
  owner 'root'
  group 'root'
  mode '755'
end

if enable_snapshots
  ruby_block 'create snapshot bucket' do
    block do
      command = %Q(aws s3 mb s3://#{es_snapshot_bucket} --region #{region})
      Chef::Log.info command
      execute_command(command)
    end
  end

  http_request "register daily snapshot repo" do
    url "http://#{es_host}:9200/_snapshot/s3_daily"
    message %Q|
      {
        "type": "s3",
        "settings": {
          "bucket": "#{es_snapshot_bucket}",
          "region": "#{region}"
        }
      }
    |
    action :put
    retries 2
    retry_delay 30
    not_if "curl -f -s http://#{es_host}:9200/_snapshot/s3_daily > /dev/null"
  end

  # daily cumulative snapshots
  cron_d 'elasticsearch_daily_snapshot' do
    user 'elasticsearch'
    day '*'
    hour '3'
    minute '0'
    command %Q(curator --host #{es_host} snapshot --prefix "daily." --include_global_state False --repository s3_daily indices --regex '^[^\.].*$' 2>&1 | logger -t info)
    path '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end
