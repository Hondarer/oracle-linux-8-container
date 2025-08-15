#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

CONTAINER_NAME=oracle-linux-8

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

echo "Starting container with user: ${USER} (UID: ${UID}, GID: ${GID})"

# ホスト側ディレクトリ準備
mkdir -p ./storage/1/home_${USER}
mkdir -p ./storage/1/workspace

# ~/.ssh/id_rsa.pub があれば、.ssh/authorized_keys に設定
if [ -f ~/.ssh/id_rsa.pub ] && [ ! -f ./storage/1/home_${USER}/.ssh/authorized_keys ]; then
    mkdir -p ./storage/1/home_${USER}/.ssh
    cp ~/.ssh/id_rsa.pub ./storage/1/home_${USER}/.ssh/authorized_keys
    # パーミッションの設定
    chmod 700 ./storage/1/home_${USER}/.ssh
    chmod 600 ./storage/1/home_${USER}/.ssh/authorized_keys
fi

# コンテナ起動 (UID マッピング + 環境変数でユーザー情報を渡す)
# --userns=keep-id で UID と GID のマッピングを維持しつつ、
# コンテナ内で初期化操作を行いたいため、root で起動
echo "Starting container with keep-id userns..."
podman run -d \
    --name ${CONTAINER_NAME}_1 \
    --userns=keep-id \
    --user root \
    -p 40022:22 \
    -v ./storage/1/home_${USER}:/home/${USER}:Z \
    -v ./storage/1/workspace:/workspace:Z \
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
podman ps | grep ${CONTAINER_NAME}_1

#echo -e "=== UID/GID Mapping Check ==="
#podman exec ${CONTAINER_NAME}_1 id

#echo -e "=== File Permissions Check ==="
#podman exec ${CONTAINER_NAME}_1 ls -la /workspace

echo "Container started successfully."
