#!/bin/bash

# version-config.sh - Oracle Linux コンテナのバージョン別共通設定
#
# 使用方法:
#   source ./version-config.sh [OL_VERSION] [INSTANCE_NUM]
#
# 引数:
#   OL_VERSION   - Oracle Linux バージョン (デフォルト: 8)
#   INSTANCE_NUM - インスタンス番号 (デフォルト: 1)
#
# 設定される変数:
#   OL_VERSION, INSTANCE_NUM, CONTAINER_NAME, CONTAINER_INSTANCE,
#   SSH_HOST_PORT, STORAGE_DIR, BASE_IMAGE

# 既に設定済みの場合はスキップ (build-pod.sh から stop-pod.sh を source する場合など)
if [ -n "${CONTAINER_NAME}" ] && [ -z "${1}" ]; then
    return 0 2>/dev/null || true
fi

OL_VERSION="${1:-8}"
INSTANCE_NUM="${2:-1}"

# バージョンの検証
case "${OL_VERSION}" in
    8|10)
        ;;
    *)
        echo "Error: Unsupported Oracle Linux version: ${OL_VERSION}"
        echo "Supported versions: 8, 10"
        exit 1
        ;;
esac

# インスタンス番号の検証
if ! [ "${INSTANCE_NUM}" -ge 1 ] 2>/dev/null; then
    echo "Error: Invalid instance number: ${INSTANCE_NUM}"
    echo "Instance number must be a positive integer."
    exit 1
fi

CONTAINER_NAME="oracle-linux-${OL_VERSION}"
CONTAINER_INSTANCE="${CONTAINER_NAME}_${INSTANCE_NUM}"

# ポート番号: 40000 + (OL_VERSION * 100) + (21 + INSTANCE_NUM)
SSH_HOST_PORT=$((40000 + OL_VERSION * 100 + 21 + INSTANCE_NUM))

STORAGE_DIR="./storage/${OL_VERSION}/${INSTANCE_NUM}"
BASE_IMAGE="oraclelinux:${OL_VERSION}"
