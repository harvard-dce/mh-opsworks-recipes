# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-ffmpeg

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

# see https://github.com/harvard-dce/ffmpeg-build for ffmpeg build process

bucket_name = get_shared_asset_bucket_name
ffmpeg_version = node.fetch(:ffmpeg_version, '4.4.1')
ffmpeg_archive = %Q|ffmpeg-#{ffmpeg_version}-amazon-linux-static.tgz|

# remove any existing installs to force new installation
if force_ffmpeg_install?
  bash 'delete existing install(s)' do
    code %Q|cd /opt && /bin/rm -Rf ffmpeg-*|
  end
end

if on_aws?
	include_recipe "oc-opsworks-recipes::install-awscli"
	download_command="aws s3 cp s3://#{bucket_name}/#{ffmpeg_archive} ."
else
	download_command="wget -O #{ffmpeg_archive} https://s3.amazonaws.com/#{bucket_name}/#{ffmpeg_archive}"
end

bash 'extract ffmpeg archive and create symbolic links' do
  code %Q|cd /opt && /bin/rm -Rf ffmpeg-#{ffmpeg_version} && #{download_command} && /bin/tar xvfz #{ffmpeg_archive}|
  retries 2
  retry_delay 30
  timeout 300
  not_if %Q(test -e /usr/local/bin/ffmpeg && /usr/local/bin/ffmpeg >2&1 > /dev/null | grep -q "version #{ffmpeg_version}")
end

[ "ffmpeg", "ffprobe" ].each do |prog|
  link "/usr/local/bin/#{prog}" do
    to "/opt/ffmpeg-#{ffmpeg_version}/#{prog}"
  end
  link "/usr/bin/#{prog}" do
    to "/opt/ffmpeg-#{ffmpeg_version}/#{prog}"
  end
end
