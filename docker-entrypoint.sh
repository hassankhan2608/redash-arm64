#!/bin/sh
# Entrypoint for Redash

set -e

if [ "$1" = 'server' ] || [ "$1" = 'worker' ] || [ "$1" = 'scheduler' ]; then
  exec python manage.py "$@"
else
  exec "$@"
fi
