#!/bin/bash

#### This script will create a snapshot of elasticsearch indices and copy it to NFS ####

EXTERNAL_NFS="/export/PS"
BACKUP_ROOT="${EXTERNAL_NFS}/elasticsearch_backups"
BACKUP_FOLDER_NAME=$(date "+%Y%m%d%H%M%S")
ELASTICSEARCH_BACKUP_DIRECTORY="${BACKUP_ROOT}/${BACKUP_FOLDER_NAME}"
KIBANA_BACKUP_DIRECTORY="${EXTERNAL_NFS}/kibana_backups/${BACKUP_FOLDER_NAME}"
LOCATION_OF_SNAPSHOTS="/usr/share/elasticsearch/elasticsearch_backups/elasticsearch_backups"
API_SNAPSHOT_REPO_URL="$(hostname -f):9200/_snapshot/elasticsearch_repo"
API_SNAPSHOT_URL="${API_SNAPSHOT_REPO_URL}/elasticsearch_snapshot"

function notify_of_failure() {
    echo "==========================================="
    echo "Something went wrong. Contacting Bumblebee"
    echo "==========================================="

    echo "COMMAND : curl -X POST https://${THUNDERBEE_FUNCTIONAL_USER}:${THUNDERBEE_FUNCTIONAL_USER_API_TOKEN_OF_FEM4S11}@fem4s11-eiffel004.eiffel.gic.ericsson.se:8443/jenkins/job/Send_Failed_Elasticsearch_Backup_Notifications/build"
    notify_output=$(curl -X POST "https://${THUNDERBEE_FUNCTIONAL_USER}:${THUNDERBEE_FUNCTIONAL_USER_API_TOKEN_OF_FEM4S11}@fem4s11-eiffel004.eiffel.gic.ericsson.se:8443/jenkins/job/Send_Failed_Elasticsearch_Backup_Notifications/build")
    echo "${notify_output}"
    if [[ ${notify_output^^} == *"ERROR"* ]]; then
        echo "ERROR : Failed to contact FEM4s11, attempting to contact FEM47s11!"
        echo "COMMAND : curl -X POST https://${THUNDERBEE_FUNCTIONAL_USER}:${THUNDERBEE_FUNCTIONAL_USER_API_TOKEN_OF_FEM47S11}@fem47s11-eiffel004.eiffel.gic.ericsson.se:8443/jenkins/job/Send_Failed_Elasticsearch_Backup_Notifications/build"
        notify_output=$(curl -X POST "https://${THUNDERBEE_FUNCTIONAL_USER}:${THUNDERBEE_FUNCTIONAL_USER_API_TOKEN_OF_FEM47S11}@fem47s11-eiffel004.eiffel.gic.ericsson.se:8443/jenkins/job/Send_Failed_Elasticsearch_Backup_Notifications/build")
        echo "${notify_output}"
        if [[ ${notify_output^^} == *"ERROR"* ]]; then
            echo "ERROR : Failed to contact FEM47s11!"
        fi
    fi
    exit 1
    echo -e "\n"
}

function determine_indices() {
    if [[ -z "${indices}" ]]; then
        indices="expresslogs*,filebeat*,angularlogs*"
    fi
}

function create_snapshot_repo() {
    echo "===================================="
    echo "Creating Elasticsearch snapshot repo"
    echo "===================================="

    echo "COMMAND : curl -X PUT ${API_SNAPSHOT_REPO_URL} -H 'Content-Type: application/json'"
    create_snapshot_repo_output=$(curl -X PUT "${API_SNAPSHOT_REPO_URL}" -H 'Content-Type: application/json' -d'
    {
      "type": "fs",
      "settings": {
        "location": "elasticsearch_backups"
      }
    }
    ')

    echo "${create_snapshot_repo_output}"

    if [[ ${create_snapshot_repo_output^^} == *"ERROR"* ]]; then
        echo "ERROR : Failed to create snapshot! Exiting..."
        notify_of_failure
    fi
    echo -e "\n"
}

function create_backup_directory() {
    local backup_directory="${1}"
    echo "INFO : Creating backup directory: ${backup_directory}"
    echo "COMMAND : mkdir -p ${backup_directory}"
    mkdir -p "${backup_directory}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to create the backup directory: ${backup_directory}"
        notify_of_failure
    fi
    chmod 777 "${backup_directory}"
    echo -e "\n"
}

function create_snapshot() {
    echo "====================================================================="
    echo "Creating Elasticsearch snapshot for the following indices: ${indices}"
    echo "====================================================================="

    echo "COMMAND : docker ps | grep elasticsearch | awk '{print \$1}'"
    elasticsearch_container_id=$(docker ps | grep "elasticsearch" | awk '{print $1}')
    echo "INFO : Elasticsearch Container ID: ${elasticsearch_container_id}"

    echo "COMMAND : docker exec -it ${elasticsearch_container_id} mkdir ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" mkdir ${LOCATION_OF_SNAPSHOTS}

    echo "COMMAND : docker exec -it ${elasticsearch_container_id} chmod 777 ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" chmod 777 ${LOCATION_OF_SNAPSHOTS}

    echo "COMMAND : curl -X PUT ${API_SNAPSHOT_URL}?wait_for_completion=true -H 'Content-Type: application/json'"
    create_snapshot_output=$(curl -X PUT "${API_SNAPSHOT_URL}?wait_for_completion=true" -H 'Content-Type: application/json' -d'
    {
      "indices": "'${indices}'",
      "ignore_unavailable": true,
      "include_global_state": false,
      "metadata": {
        "taken_by": "Production vApp",
        "taken_because": "Regular backup"
      }
    }
    ')
    echo "${create_snapshot_output}"

    if [[ "${create_snapshot_output^^}" == *"ERROR"* ]]; then
        echo "ERROR : Failed to create snapshot! Exiting..."
        notify_of_failure
    fi
    echo -e "\n"
}

function copy_snapshot_to_backup_directory() {
    local backup_directory="${1}"
    echo "====================================================="
    echo "Copying Elasticsearch snapshot to ${backup_directory}"
    echo "====================================================="

    echo "COMMAND : docker cp ${elasticsearch_container_id}:${LOCATION_OF_SNAPSHOTS}/. ${backup_directory}"
    docker cp "${elasticsearch_container_id}:${LOCATION_OF_SNAPSHOTS}/." "${backup_directory}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to copy snapshots to ${backup_directory}! Exiting..."
        notify_of_failure
    fi
    echo -e "\n"
}

function cleanup_snapshot() {
    echo "=============================="
    echo "Cleaning up backed up snapshot"
    echo "=============================="
    echo "COMMAND : curl -X DELETE ${API_SNAPSHOT_URL}"
    curl -X DELETE "${API_SNAPSHOT_URL}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to delete snapshot"
        notify_of_failure
    fi
    echo -e "\n"
    echo "COMMAND : docker exec -it ${elasticsearch_container_id} rm -rf ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" rm -rf ${LOCATION_OF_SNAPSHOTS}
    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to delete snapshot directory: ${LOCATION_OF_SNAPSHOTS}"
        notify_of_failure
    fi
    echo -e "\n"
}

function execute_logic() {
    determine_indices
    create_snapshot_repo
    create_snapshot
    if [[ "${indices}" == *"kibana"* ]]; then
        create_backup_directory "${KIBANA_BACKUP_DIRECTORY}"
        copy_snapshot_to_backup_directory "${KIBANA_BACKUP_DIRECTORY}"
    else
        create_backup_directory "${ELASTICSEARCH_BACKUP_DIRECTORY}"
        copy_snapshot_to_backup_directory "${ELASTICSEARCH_BACKUP_DIRECTORY}"
    fi
    cleanup_snapshot
}

function usage() {
    local script_name=$(basename "$0")
    echo "Optional Parameters: "
    echo "-i|--indices - comma separated list of indices to overwrite. Current supported default indices: angularlogs, expresslogs, filebeat"
    echo ""
    echo "Usage:"
    echo "   Example 1:"
    echo "   ${script_name}"
    echo "   Example 2:"
    echo "   ${script_name} --indices .kibana_*"
    exit 1
}

########################
#     SCRIPT START     #
########################
short_args="i:,h"
long_args="indices:,help"

args=$(getopt -o ${short_args} -l ${long_args} -n "$0"  -- "$@" )
eval set -- "${args}"

while true; do
    case "$1" in
     -i|--indices)
        export indices=$2
        shift 2 ;;
     -h|--help)
        usage
        ;;
     --)
        shift
        break ;;
    esac
done

execute_logic
