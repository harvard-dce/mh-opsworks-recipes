# Cookbook Name:: oc-opsworks-recipes
# Recipe:: install-ffmpeg

::Chef::Recipe.send(:include, MhOpsworksRecipes::RecipeHelpers)
include_recipe "oc-opsworks-recipes::update-package-repo"

# The list of libraries that've been built against the ffmpeg binary (and are
# therefore required for it to function fully)  was generated on the build
# vagrant image thusly:
# for lib in $(ldd $(which ffmpeg) | cut -d ' ' -f 3); do dpkg -S $lib; done | cut -d ' ' -f 1 | sort | uniq | cut -d ':' -f 1

packages = %Q|libasound2 libass4 libasyncns0 libc6 libcaca0 libdbus-1-3 libenca0 libexpat1 libflac8 libfontconfig1 libfreetype6 libfribidi0 libjson-c2 libmp3lame0 libncursesw5 libogg0 libopus0 libpng12-0 libpulse0 libsdl1.2debian libslang2 libsndfile1 libtheora0 libtinfo5 libva1 libvdpau1 libvorbis0a libvorbisenc2 libwrap0 libx11-6 libxau6 libxcb1 libxcb-shape0 libxcb-shm0 libxcb-xfixes0 libxdmcp6 libxext6 zlib1g libva-drm1 libva-x11-1|

install_package(packages)

bucket_name = get_shared_asset_bucket_name
ffmpeg_version = node.fetch(:ffmpeg_version, '3.2.4')
ffmpeg_archive = %Q|ffmpeg-#{ffmpeg_version}-static.tgz|

if on_aws?
  include_recipe "oc-opsworks-recipes::install-awscli"
  download_command="/usr/local/bin/aws s3 cp s3://#{bucket_name}/#{ffmpeg_archive} ."
else
  download_command="wget https://s3.amazonaws.com/#{bucket_name}/#{ffmpeg_archive}"
end

bash 'extract ffmpeg archive and create symbolic links' do
  code %Q|
cd /opt &&
/bin/rm -Rf ffmpeg-#{ffmpeg_version} &&
#{download_command} &&
/bin/tar xvfz #{ffmpeg_archive} &&
cd /usr/local/bin/ &&
/usr/bin/find /opt/ffmpeg-#{ffmpeg_version} -mindepth 1 -type f -executable -exec /bin/ln -sf {} \\;
|
  # retries 10
  # retry_delay 5
  timeout 300
  not_if { ::File.exists?("/opt/#{ffmpeg_archive}") }
end
