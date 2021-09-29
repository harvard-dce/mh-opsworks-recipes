# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-crowdstrike

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

bucket_name = get_shared_asset_bucket_name
crowdstrike = node.fetch(:crowdstrike, {})

return if !crowdstrike[:cid]
rpm = crowdstrike[:rpm] || 'crowdstrike-falcon-sensor.rpm'

if on_aws?
  include_recipe "oc-opsworks-recipes::install-awscli"
  download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{rpm} ."

  bash 'install crowdstrike falcon sensor' do
    code %Q|
cd /opt &&
/bin/rm -f #{rpm} &&
#{download_command} &&
yum install -y #{rpm}
|
    retries 3
    retry_delay 10
    timeout 300
    # Search list of installed packages for this specific one.
    # This should work becaues even though this falcon sensor software updates itself,
    # the entry in the yum registry will remain static
    not_if "rpm -qa | grep $(rpm -qp /opt/#{rpm} 2>/dev/null)"
    notifies :run, "execute[set cid]", :immediately
  end

  execute 'set cid' do
    command "/opt/CrowdStrike/falconctl -s -f --cid=#{crowdstrike[:cid]}"
    # only run when notified by the previous block
    action :nothing
  end
end
