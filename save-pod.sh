#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

source "$(dirname "$0")/version-config.sh" "${1:-8}"

# Check if the container image exists
if ! podman images | grep -q "${CONTAINER_NAME}"; then
    #source ./build-pod.sh
    echo "Error: image ${CONTAINER_NAME} not found."
    echo "Please ensure ${CONTAINER_NAME} is registered before running this script."
    exit 1
fi

mkdir -p image
podman save ${CONTAINER_NAME} | gzip -9 > image/${CONTAINER_NAME}.tar.gz
ls -l image/${CONTAINER_NAME}.tar.gz
