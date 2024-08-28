#!/bin/bash
export COMPOSE_PROJECT_NAME="commonersdmetrics"
export HOSTNAME=$(hostname -f)

time docker-compose -f docker-compose-production.yml pull
if [[ $? -ne 0 ]]; then
    exit 1
fi
time docker-compose -f docker-compose-production.yml up -d
if [[ $? -ne 0 ]]; then
    exit 1
fi
docker system prune --force -a
