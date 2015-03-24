# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-ffmpeg

ppa = node.fetch(:ffmpeg_ppa, "http://ppa.launchpad.net/mc3man/trusty-media/ubuntu")
ppa_key = node.fetch(:ffmpeg_ppa_key, "ED8E640A")

include_recipe "mh-opsworks-recipes::update-package-repo"

apt_repository "ffmpeg" do
  uri ppa
  distribution node['lsb']['codename']
  components ['main']
  keyserver 'keyserver.ubuntu.com'
  key ppa_key
end

apt_package "ffmpeg" do
  options "--force-yes"
  action :upgrade
end
