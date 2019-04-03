# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-crowdstrike

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

return unless on_aws?

bucket_name = get_shared_asset_bucket_name
crowdstrike_data = node.fetch(:crowdstrike)
return unless crowdstrike_data

crowdstrike_cid = crowdstrike_data[:cid]
force_install = crowdstrike_data.fetch(:force_install, "")
falcon_sensor_package = crowdstrike_data.fetch(:falcon_sensor_package, 'falcon-sensor.deb')

install_package("libnl1")
include_recipe "oc-opsworks-recipes::install-awscli"
download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{falcon_sensor_package} ."

bash 'install crowdstrike falcon sensor pacakge' do
  code %Q|
cd /opt &&
/bin/rm -f #{falcon_sensor_package} &&
#{download_command} &&
dpkg -i #{falcon_sensor_package}
/opt/CrowdStrike/falconctl -s -f --cid=#{crowdstrike_cid}
|
  retries 3
  retry_delay 10
  timeout 60
  # don't install if the install dir is present AND we're not doing a force install
  # NOTE: the falcon sensor package updates itself :( so it's futile to try doing a version
  # comparison when decided to install/re-install
  not_if %Q|test -d /opt/CrowdStrike && test -z "#{force_install}"|
  notifies :restart, 'service[falcon-sensor]'
end

service 'falcon-sensor' do
  action :nothing
end
