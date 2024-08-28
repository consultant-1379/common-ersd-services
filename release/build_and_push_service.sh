#!/bin/bash

common_ersd_services_docker_image=$1
common_ersd_services_service_path=$2
image_version=$3
GRAFANA_VIEWER_PASSWORD=$4
GRAFANA_ADMIN_PASSWORD=$5

if [[ -n "${GRAFANA_VIEWER_PASSWORD}" ]] && [[ -n "${GRAFANA_ADMIN_PASSWORD}" ]]; then
    grafana_build_arg="--build-arg GRAFANA_VIEWER_PASSWORD=${GRAFANA_VIEWER_PASSWORD} --build-arg GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}"
fi

version=$(echo ${image_version} | awk -F "=" '{print $2}')

echo "COMMAND: docker build -f ${common_ersd_services_service_path} ${grafana_build_arg} -t armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:${version} --pull ${WORKSPACE}"
docker build -f ${common_ersd_services_service_path} ${grafana_build_arg} -t armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:${version} --pull ${WORKSPACE}

echo "COMMAND: docker_image_id=$(docker images armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image} -q)"
docker_image_id=$(docker images armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image} -q)

echo "COMMAND: docker tag ${docker_image_id} armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:latest"
docker tag ${docker_image_id} armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:latest

echo "COMMAND: docker push armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:${version}"
docker push armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:${version}

echo "COMMAND: docker push armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:latest"
docker push armdocker.rnd.ericsson.se/proj_openstack_tooling/${common_ersd_services_docker_image}:latest
