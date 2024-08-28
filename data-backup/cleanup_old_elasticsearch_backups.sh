#!/bin/bash

#### This script will find folders older than the retention period and delete them ####

RETENTION_PERIOD=3
BACKUP_LOCATIONS="/export/PS/elasticsearch_backups/*,/export/PS/kibana_backups/*"

function delete_old_backups() {
    echo "============================================================================"
    echo "Removing backups older than ${RETENTION_PERIOD} days from ${BACKUP_LOCATIONS}"
    echo "============================================================================" 
    for backup_location in $(echo ${BACKUP_LOCATIONS} |  sed "s/,/ /g"); do
        echo "COMMAND : find ${backup_location} -type d -mtime +${RETENTION_PERIOD} -exec rm -rf {} \;"
        find ${backup_location} -type d -mtime +${RETENTION_PERIOD} -exec rm -rf {} \;
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to remove backups older than ${RETENTION_PERIOD} days from ${backup_location}"
            exit 1
        fi
    done
    echo -e "\n"
}

########################
#     SCRIPT START     #
########################
delete_old_backups
