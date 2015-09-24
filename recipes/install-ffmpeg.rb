# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ffmpeg

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "awscli::default"
include_recipe "mh-opsworks-recipes::update-package-repo"

%W|libass-dev libfreetype6-dev libmp3lame-dev libogg-dev
libopus-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev
libvorbis-dev libxcb-shm0-dev libxcb-xfixes0-dev
libxcb1-dev zlib1g-dev|.each do |package|
  install_package(package)
end

bucket_name = node.fetch(:shared_asset_bucket_name, 'mh-opsworks-shared-assets')
ffmpeg_version = node.fetch(:ffmpeg_version, '2.7.2')
ffmpeg_archive = %Q|ffmpeg-#{ffmpeg_version}-static.tgz|

package 'ffmpeg' do
  action :remove
  ignore_failure true
end

bash 'extract ffmpeg archive and create symbolic links' do
  code %Q|
cd /opt &&
/bin/rm -Rf ffmpeg-#{ffmpeg_version} &&
/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{ffmpeg_archive} . &&
/bin/tar xvfz #{ffmpeg_archive} &&
cd /usr/local/bin/ &&
/usr/bin/find /opt/ffmpeg-#{ffmpeg_version} -mindepth 1 -type f -executable -exec /bin/ln -sf {} \\;
|
  # retries 10
  # retry_delay 5
  timeout 300
  not_if { ::File.exists?("/opt/#{ffmpeg_archive}") }
end
