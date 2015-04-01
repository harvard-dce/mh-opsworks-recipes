@test "sh is properly set to bash" {
  ls -fali /bin/sh | grep -qie bash
}
