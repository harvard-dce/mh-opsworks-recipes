#!/usr/bin/env bats

ensure_package_is_installed(){
  package=$1
  @test "$package binary is found in PATH" {
    run which $package
      [ "$status" -eq 0 ]
  }
}

for package in maven2 openjdk-7-jdk openjdk-7-jre \
  gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-tools \
  gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly \
  libglib2.0-dev mysql-client gzip tesseract-ocr htop nmap traceroute \
  silversearcher-ag; do
  ensure_package_is_installed $package
done;
