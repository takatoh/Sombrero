#! /usr/bin/env sh
set -e

HOST=${HOST:-0.0.0.0}
PORT=${PORT:-9292}
ENV=${RACK_ENV:-development}

bundle exec rackup -o $HOST -p $PORT -E $ENV
