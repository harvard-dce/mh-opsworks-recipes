#!/usr/bin/env bats

@test "nfs is exported successfully" {
  showmount -e localhost | grep -qie /var/tmp
}
