#!/usr/bin/env bats

@test "base packages are installed" {
  for package in maven openjdk-7-jdk openjdk-7-jre \
    gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-tools \
    gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly \
    libglib2.0-dev mysql-client gzip tesseract-ocr; do

    run dpkg -l "$package"
      [ "$status" -eq 0 ]
  done;
}
