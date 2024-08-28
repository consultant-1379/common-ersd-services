#!/bin/bash

#### This script will copy a snapshot of elasticsearch from a backup directory on the NFS to elasticsearch indices and restore it ####

LOCATION_OF_SNAPSHOTS="/usr/share/elasticsearch/elasticsearch_backups/elasticsearch_backups"
ELASTICSEARCH_API_URL="$(hostname -f):9200"
API_SNAPSHOT_REPO_URL="${ELASTICSEARCH_API_URL}/_snapshot/elasticsearch_repo"
API_SNAPSHOT_URL="${API_SNAPSHOT_REPO_URL}/elasticsearch_snapshot"
RESTORE_API_SNAPSHOT_URL="${API_SNAPSHOT_URL}/_restore?wait_for_completion=true"

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

    if [[ "${create_snapshot_repo_output^^}" == *"ERROR"* ]]; then
        echo "ERROR : Failed to create snapshot! Exiting..."
        exit 1
    fi
    echo -e "\n"
}

function copy_snapshot_from_backup_directory() {
    echo "===================================================="
    echo "Copying Elasticsearch snapshot from backup directory"
    echo "===================================================="

    echo "COMMAND : docker ps | grep elasticsearch | awk '{print \$1}'"
    elasticsearch_container_id=$(docker ps | grep "elasticsearch" | awk '{print $1}')
    echo "INFO : Elasticsearch Container ID: ${elasticsearch_container_id}"

    echo "COMMAND : docker exec -it ${elasticsearch_container_id} mkdir ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" mkdir ${LOCATION_OF_SNAPSHOTS}

    echo "COMMAND : docker exec -it ${elasticsearch_container_id} chmod 777 ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" chmod 777 ${LOCATION_OF_SNAPSHOTS}

    echo "COMMAND : docker cp ${backup_dir}/. ${elasticsearch_container_id}:${LOCATION_OF_SNAPSHOTS}/."
    docker cp ${backup_dir}/. ${elasticsearch_container_id}:${LOCATION_OF_SNAPSHOTS}/.

    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to copy snapshots from ${backup_dir}! Exiting..."
        exit 1
    fi
    echo -e "\n"
}


function determine_indices() {
    if [[ -z "${indices}" ]]; then
        indices="filebeat*,expresslogs*,angularlogs*"
    fi
}

function delete_any_existing_indices() {
    echo "INFO : Deleting any existing indices: ${indices}"
    for index_pattern in $(echo ${indices} |  sed "s/,/ /g"); do
        echo "COMMAND : curl -X DELETE ${ELASTICSEARCH_API_URL}/${index_pattern}"
        curl -X DELETE "${ELASTICSEARCH_API_URL}/${index_pattern}"
        if [[ $? -ne 0 ]]; then
            echo "ERROR : Failed to delete the index pattern ${index_pattern}!"
            exit_code=1
        fi
        echo -e "\n"
    done
    if [[ ${exit_code} -eq 1 ]]; then
        echo "ERROR : Failed to delete one or more index patterns! Please check above logs"
        exit 1
    fi
}

function restore_snapshot() {
    echo "================================"
    echo "Restoring Elasticsearch snapshot"
    echo "================================"
    echo "COMMAND : curl -X POST ${RESTORE_API_SNAPSHOT_URL} -H 'Content-Type: application/json'"
    restore_snapshot_output=$(curl -X POST "${RESTORE_API_SNAPSHOT_URL}" -H 'Content-Type: application/json' -d'
    {
      "indices": "'${indices}'",
      "ignore_unavailable": true,
      "include_global_state": true
    }
    ')
    echo "${restore_snapshot_output}"

    if [[ ${restore_snapshot_output^^} == *"ERROR"* ]]; then
        echo "ERROR : Failed to restore snapshot! Cleaning up directory and then exiting!"
        cleanup_snapshot_directory
        exit 1
    fi
    echo -e "\n"
}

function cleanup_snapshot_directory() {
    echo "COMMAND : docker exec -it ${elasticsearch_container_id} rm -rf ${LOCATION_OF_SNAPSHOTS}"
    docker exec -it "${elasticsearch_container_id}" rm -rf ${LOCATION_OF_SNAPSHOTS}
    if [[ $? -ne 0 ]]; then
        echo "ERROR : Failed to delete snapshot directory: ${LOCATION_OF_SNAPSHOTS}"
        exit 1
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
        exit 1
    fi
    echo -e "\n"
    cleanup_snapshot_directory
}

function usage() {
    local script_name=$(basename "$0")
    echo "Required Parameters: "
    echo "-b|--backup_dir - directory where the snapshot was backed up to"
    echo "Optional Parameters: "
    echo "-i|--indices - comma separated list of indices to restore. Current supported default indices: angularlogs, expresslogs, filebeat"
    echo ""
    echo "Usage:"
    echo "   Example 1: "
    echo "   ${script_name} -b /export/PS/elasticsearch_backups/20191014152804"
    echo "   Example 2: "
    echo "   ${script_name} -b /export/PS/kibana_backup -i .kibana_*"
    exit 1
}

########################
#     SCRIPT START     #
########################
short_args="b:,i:,h"
long_args="backup_dir:,indices:,help"

args=$(getopt -o ${short_args} -l ${long_args} -n "$0"  -- "$@" )
eval set -- "${args}"

while true; do
    case "$1" in
     -b|--backup_dir)
        export backup_dir=$2
        shift 2 ;;
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

if [[ -z "${backup_dir}" ]]; then
    echo "ERROR : You must pass in the snapshot backup directory"
    usage
fi

create_snapshot_repo
copy_snapshot_from_backup_directory
determine_indices
delete_any_existing_indices
restore_snapshot
cleanup_snapshot
