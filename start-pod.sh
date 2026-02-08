#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

source "$(dirname "$0")/version-config.sh" "${1:-8}" "${2:-1}"

# 既存のコンテナを停止
source ./stop-pod.sh

# Check if the container image exists
if ! podman images | grep -q "${CONTAINER_NAME}"; then
    #source ./build-pod.sh
    echo "Error: image ${CONTAINER_NAME} not found."
    echo "Please ensure ${CONTAINER_NAME} is registered before running this script."
    exit 1
fi

# ホストのユーザー情報を取得
# USER, UID は OS にて設定済
GID=$(id -g)

echo "Starting container ${CONTAINER_INSTANCE} (OL${OL_VERSION}) with user: ${USER} (UID: ${UID}, GID: ${GID})"

# ストレージ移行ガイダンス
if [ "${OL_VERSION}" = "8" ] && [ -d "./storage/1" ] && [ ! -d "./storage/8" ]; then
    echo ""
    echo "Note: Storage structure has changed from ./storage/1/ to ./storage/8/1/"
    echo "To migrate existing data: mkdir -p ./storage/8 && mv ./storage/1 ./storage/8/1"
    echo ""
fi

# ホスト側ディレクトリ準備
mkdir -p ${STORAGE_DIR}/home_${USER}
mkdir -p ${STORAGE_DIR}/workspace

# ~/.ssh/id_rsa.pub があれば、.ssh/authorized_keys に設定
if [ -f ~/.ssh/id_rsa.pub ] && [ ! -f ${STORAGE_DIR}/home_${USER}/.ssh/authorized_keys ]; then
    mkdir -p ${STORAGE_DIR}/home_${USER}/.ssh
    cp ~/.ssh/id_rsa.pub ${STORAGE_DIR}/home_${USER}/.ssh/authorized_keys
    # パーミッションの設定
    chmod 700 ${STORAGE_DIR}/home_${USER}/.ssh
    chmod 600 ${STORAGE_DIR}/home_${USER}/.ssh/authorized_keys
fi

# コンテナ起動 (UID マッピング + 環境変数でユーザー情報を渡す)
# --userns=keep-id で UID と GID のマッピングを維持しつつ、
# コンテナ内で初期化操作を行いたいため、root で起動
echo "Starting container with keep-id userns..."
podman run -d \
    --name ${CONTAINER_INSTANCE} \
    --userns=keep-id \
    --user root \
    -p ${SSH_HOST_PORT}:22 \
    -v ${STORAGE_DIR}/home_${USER}:/home/${USER}:Z \
    -v ${STORAGE_DIR}/workspace:/workspace:Z \
    --restart unless-stopped \
    --env HOST_USER=${USER} \
    --env HOST_UID=${UID} \
    --env HOST_GID=${GID} \
    ${CONTAINER_NAME}

if [ $? -ne 0 ]; then
    echo "Error: Failed to start container."
    exit 1
fi

# 確認

echo -e "=== Container Info ==="
podman ps | grep ${CONTAINER_INSTANCE}

#echo -e "=== UID/GID Mapping Check ==="
#podman exec ${CONTAINER_INSTANCE} id

#echo -e "=== File Permissions Check ==="
#podman exec ${CONTAINER_INSTANCE} ls -la /workspace

echo "Container ${CONTAINER_INSTANCE} started successfully. (SSH port: ${SSH_HOST_PORT})"
