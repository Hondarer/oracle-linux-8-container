#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

CONTAINER_NAME=oracle-linux-8

# 既存のコンテナを停止・削除
podman stop ${CONTAINER_NAME}_1 1>/dev/null 2>/dev/null || true
podman rm ${CONTAINER_NAME}_1 1>/dev/null 2>/dev/null || true

echo "Container stopped successfully."
