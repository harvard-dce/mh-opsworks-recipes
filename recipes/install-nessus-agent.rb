# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-nessus-agent

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

bucket_name = get_shared_asset_bucket_name
nessus_data = node.fetch(:nessus, {})

nessus_key = nessus_data[:key]
return if !nessus_key

rpm = nessus_data[:rpm] || 'nessus-agent.rpm'
nessus_host = nessus_data[:host] || 'ns-manager.itsec.harvard.edu'
nessus_port = nessus_data[:port] || '8834'
nessus_group = nessus_data[:group] || 'dce-linux'

if on_aws?
  include_recipe "oc-opsworks-recipes::install-awscli"
  download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{rpm} ."

  bash 'install nessus agent' do
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
    notifies :run, "execute[configure nessus]", :immediately
  end

  execute 'configure nessus' do
    command %Q|/opt/nessus_agent/sbin/nessuscli agent link --key=#{nessus_key} --host=#{nessus_host} --port=#{nessus_port} --groups=#{nessus_group}|
    # only run when notified by the previous block
    action :nothing
  end
end
