#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

source "$(dirname "$0")/version-config.sh" "${1:-8}"

# Check if the container image exists
if [ ! -f image/${CONTAINER_NAME}.tar.gz ]; then
    echo "Error: image/${CONTAINER_NAME}.tar.gz not found."
    exit 1
fi

gunzip -c image/${CONTAINER_NAME}.tar.gz | podman load
