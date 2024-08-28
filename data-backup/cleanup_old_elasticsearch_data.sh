#!/bin/bash

RETAINING_LIMIT=30

function delete_old_indices() {
    echo "============================================================================"
    echo "Removing Elastic Search Indices which are older than ${RETAINING_LIMIT}"
    echo "============================================================================"
    echo "COMMAND : docker run --rm --name curator --net commonersdmetrics_default --entrypoint curator_cli armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/bobrik/curator:latest --host $(hostname -f):9200 delete_indices --filter_list '[{\"filtertype\":\"pattern\",\"kind\":\"regex\",\"value\":\"^filebeat-|^expresslogs-|^angularlogs-\"},{\"filtertype\":\"age\",\"source\":\"name\",\"direction\":\"older\",\"timestring\": \"%Y.%m.%d\",\"unit\":\"days\",\"unit_count\":${RETAINING_LIMIT}}]'"
    docker run --rm --name curator --net commonersdmetrics_default --entrypoint curator_cli armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/bobrik/curator:latest --host $(hostname -f):9200 delete_indices --filter_list "[{\"filtertype\":\"pattern\",\"kind\":\"regex\",\"value\":\"^filebeat-|^expresslogs-|^angularlogs-\"},{\"filtertype\":\"age\",\"source\":\"name\",\"direction\":\"older\",\"timestring\": \"%Y.%m.%d\",\"unit\":\"days\",\"unit_count\":$RETAINING_LIMIT}]"
    echo -e "\n"
}

########################
#     SCRIPT START     #
########################
delete_old_indices