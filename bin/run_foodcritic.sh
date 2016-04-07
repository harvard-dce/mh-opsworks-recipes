#!/bin/bash

BUNDLE_GEMFILE=test/support/Gemfile bundle install > /dev/null
BUNDLE_GEMFILE=test/support/Gemfile bundle exec foodcritic -f any .

if [ "$?" = "0" ]; then
  echo 'foodcritic linting successful'
else
  # Some items aren't worth worrying about. If you'd like to ignore a
  # foodcritic check, edit the '.foodcritic' file in this repo and add the rule
  echo 'failed! See errors / warnings above'
fi
