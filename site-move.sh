#!/bin/bash

# Get all of the variables from the site-variables.env file
set -o allexport; source site-variables.env; set +o allexport

# generate passwords
export MYSQL_ROOT_PASSWORD="$(pwgen -s 20 1)"

# docker compose to pull in dbs and update

docker-compose -f docker-compose.yml -f docker-compose-move.yml build
docker-compose -f docker-compose.yml -f docker-compose-move.yml run drupal-move
