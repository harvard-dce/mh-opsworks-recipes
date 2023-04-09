#!/bin/bash
echo "Generating docs"
install_dependencies() {
  BUNDLE_GEMFILE=test/support/Gemfile bundle install
}

build_docs () {
  BUNDLE_GEMFILE=test/support/Gemfile bundle exec yardoc '**/*.rb' --plugin chef
}

install_dependencies
build_docs

if command -v inotifywait > /dev/null; then
  echo
  echo 'inotifywait installed! auto-regenerating docs. . . '
  echo
  while inotifywait -e close_write,moved_to,create .; do build_docs ; done
fi
