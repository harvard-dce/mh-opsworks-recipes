# Cookbook Name:: oc-opsworks-recipes
# Recipe:: set-timezone

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

timezone = node.fetch(:timezone, 'America/New_York')

# need to create a service stub to notify
service 'rsyslog' do
  action :nothing
  supports :restart => true
end

[ "ntp", "ntpdate" ].each do |pkg|
  package "remove #{pkg}" do
    action :purge
    package_name pkg
    ignore_failure true
  end
end

install_package("chrony")

service 'chrony' do
  service_name 'chronyd'
  supports :restart => true, :status => true, :reload => true
  action [:start, :enable]
  provider Chef::Provider::Service::Systemd
end

file '/etc/sysconfig/clock' do
  action :create
  content %|ZONE="#{timezone}"\nUTC=false\n|
  owner 'root'
  group 'root'
  mode '0644'
end

link "/etc/localtime" do
  to "/usr/share/zoneinfo/#{timezone}"
  link_type :symbolic
end
