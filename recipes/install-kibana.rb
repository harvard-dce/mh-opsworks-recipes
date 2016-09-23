# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-kibana

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

include_recipe "mh-opsworks-recipes::update-package-repo"
install_package('nginx')
install_package('apache2-utils')

install_nginx_logrotate_customizations
configure_nginx_cloudwatch_logs

elk_info = get_elk_info

kibana_major_version = elk_info['kibana_major_version']
kibana_repo_uri = elk_info['kibana_repo_uri']

create_ssl_cert(elk_info['http_ssl'])

apt_repository 'kibana' do
  uri kibana_repo_uri
  components ['stable', 'main']
  keyserver 'ha.pool.sks-keyservers.net'
  key '46095ACC8548582C1A2699A9D27D666CD88E42B4'
end

include_recipe "mh-opsworks-recipes::update-package-repo"
pin_package("kibana", "#{kibana_major_version}.*")
install_package("kibana")

execute 'configure kibana to start on boot' do
  command "sudo update-rc.d kibana defaults 95 10"
end


