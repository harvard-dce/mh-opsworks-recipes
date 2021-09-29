# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-run-one

# run-one is an Ubuntu-native tool that we made much use of in the past
# it's not available in amazon linux, but it's just a shell script, so we've cribbed
# it and install the script via this recipe

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)

bucket_name = get_shared_asset_bucket_name
run_one_archive = "run-one.tgz"

if on_aws?
	include_recipe "oc-opsworks-recipes::install-awscli"
	download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{run_one_archive} ."
else
	download_command="wget -O #{run_one_archive} https://s3.amazonaws.com/#{bucket_name}/#{run_one_archive}"
end

bash 'install run-one' do
  code %Q|cd /opt && /bin/rm -Rf run-one && #{download_command} && /bin/tar xvfz #{run_one_archive}|
  retries 2
  retry_delay 30
  timeout 300
end

link "/usr/bin/run-one" do
  to "/opt/run-one/run-one"
end
