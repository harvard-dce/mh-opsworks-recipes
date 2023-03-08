# Cookbook Name:: oc-opsworks-recipes
# Recipe:: configure-nginx-proxy

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

# Updates the SELinux policy to allow nginx network relay
# without this the proxy will get permission denied from upstream
# denials show up in the /var/log/audit/audit.log
execute "allow nginx network relay" do
  command "setsebool -P httpd_can_network_relay 1"
end

include_recipe "oc-opsworks-recipes::update-package-repo"
install_package("nginx")
