# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package('nginx')
install_package('apache2-utils')

install_nginx_logrotate_customizations

elk_info = get_elk_info

kibana_version = elk_info[:kibana_version]
kibana_checksum = elk_info[:kibana_checksum]
download_path = "#{::Chef::Config[:file_cache_path]}/kibana.tar.gz" 

create_ssl_cert(elk_info[:http_ssl])

group 'kibana' do
  append true
end

user 'kibana' do
  supports manage_home: true
  gid 'kibana'
  shell '/bin/false'
  home '/opt/kibana'
end

cookbook_file "/etc/init.d/kibana" do
  source "kibana-4.x-init"
  owner 'root'
  group 'root'
  mode '755'
end

cookbook_file "/etc/default/kibana" do
  source "kibana-4.x-default"
  owner 'root'
  group 'root'
  mode '644'
end

remote_file download_path do
  source "https://download.elastic.co/kibana/kibana/kibana-#{kibana_version}-linux-x64.tar.gz"
  checksum kibana_checksum
  notifies :run, "bash[install_kibana]", :immediately
end

bash "install_kibana" do
  code <<-EOH
    tar -xz --strip-components=1 -C /opt/kibana -f #{download_path}
    chown -R kibana: /opt/kibana
    update-rc.d kibana defaults 96 9
  EOH
  action :nothing
end

