#!/usr/bin/env bats

@test "utility packages are installed" {
  for package in htop nmap traceroute silversearcher-ag screen tmux iotop mytop pv nethogs; do
    run dpkg -l "$package"
      [ "$status" -eq 0 ]
  done;
}
