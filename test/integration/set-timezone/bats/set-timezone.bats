@test "timezone is set properly" {
  timedatectl | grep -qie 'America/New_York'
}
