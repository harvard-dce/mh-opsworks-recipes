# Cookbook Name:: mh-opsworks-recipes
# Recipe:: install-mh-base-packages

execute "apt-get update"

%w|maven2 openjdk-7-jdk openjdk-7-jre
  gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-tools
  gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly
  libglib2.0-dev mysql-client gzip tesseract-ocr htop nmap traceroute
  silversearcher-ag|.each do |package_name|
    package package_name
  end
