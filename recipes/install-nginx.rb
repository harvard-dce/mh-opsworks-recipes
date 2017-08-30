# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

nginx_version = node.fetch(:nginx_version, "1.14")

package 'nginx' do
  action          :purge
  options         "--auto-remove"
  retries         3
  retry_delay     5
  ignore_failure  true
  not_if          "dpkg -s nginx | grep -i version | grep '#{ nginx_version }[\.\-]'"
end

apt_repository 'nginx' do
  uri           'http://nginx.org/packages/ubuntu/'
  components    ['nginx']
  distribution  'trusty'
  action        :add
  keyserver     'keyserver.ubuntu.com'
  key           'ABF5BD827BD9BF62'
end

include_recipe "oc-opsworks-recipes::update-package-repo"
pin_package("nginx", "#{nginx_version}.*")
install_package('nginx')
