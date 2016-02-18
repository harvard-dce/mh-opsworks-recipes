#!/usr/bin/env bats

@test "aws is installed" {
  which aws;
}

@test "aws is the expected version" {
  aws --version command 2>&1 >/dev/null | grep 1.10.5;
}
