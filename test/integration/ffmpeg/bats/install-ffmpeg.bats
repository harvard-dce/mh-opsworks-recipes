#!/usr/bin/env bats

@test "ffmpeg is installed" {
  which ffmpeg;
}
