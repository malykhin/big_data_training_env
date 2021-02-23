#!/bin/bash

superset fab create-admin \
  --username admin \
  --firstname Superset \
  --lastname Admin \
  --email admin@superset.com \
  --password admin

superset db upgrade

# superset load_examples

superset init

bash -c /usr/bin/docker-entrypoint.sh