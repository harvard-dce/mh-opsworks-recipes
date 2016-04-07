#!/usr/bin/env bats

@test "base packages are installed" {
  for package in autofs5 curl dkms gzip libglib2.0-dev maven mediainfo \
    mysql-client openjdk-7-jdk openjdk-7-jre postfix python-pip rsyslog-gnutls \
    run-one tesseract-ocr; do

    run dpkg -l "$package"
      [ "$status" -eq 0 ]
  done;
}
