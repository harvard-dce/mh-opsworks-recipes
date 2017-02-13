# Cookbook Name:: oc-opsworks-recipes
# Recipe:: create-metrics-dependencies

include_recipe "oc-opsworks-recipes::install-awscli"

user "custom_metrics" do
  comment 'The custom metrics reporting user'
  system true
  shell '/bin/false'
end

cookbook_file "custom_metrics_shared.sh" do
  path "/usr/local/bin/custom_metrics_shared.sh"
  owner "root"
  group "root"
  mode "755"
end
