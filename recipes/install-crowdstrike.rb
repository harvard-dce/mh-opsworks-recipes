# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-crowdstrike

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "mh-opsworks-recipes::update-package-repo"

bucket_name = get_shared_asset_bucket_name
crowdstrike_deb = node.fetch(:crowdstrike_deb, 'falcon-sensor_2.0.22-1202_amd64.deb')
crowdstrike_version = node.fetch(:crowdstrike_version, '2.0.0022.1202')
::Chef::Log.info("crowdstrike version #{crowdstrike_version}")

if on_aws?
  install_package("auditd libauparse0")
  include_recipe "mh-opsworks-recipes::install-awscli"
  download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{crowdstrike_deb} ."

  bash 'install crowdstrike falcon host pacakge' do
    code %Q|
cd /opt &&
/bin/rm -f #{crowdstrike_deb} &&
#{download_command} &&
dpkg -i #{crowdstrike_deb}
|
    retries 5
    retry_delay 10
    timeout 300
    # don't install if the install dir is present AND the version matches
    not_if "test -d /opt/CrowdStrike && /opt/CrowdStrike/CsConfig -g --version | /bin/grep -q -F '#{crowdstrike_version}.'"
  end
end
