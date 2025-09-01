#! /usr/bin/env sh
set -e

HOST=0.0.0.0

bundle exec rackup -o $HOST
