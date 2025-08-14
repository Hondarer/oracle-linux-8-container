#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

CONTAINER_NAME=oracle-linux-8

# container-release の作成
echo "Build on $(LANG=C && date)" > ./src/container-release

# ホストのユーザー情報を取得
USER_NAME=$(whoami)
#UID=$(id -u)
GID=$(id -g)

echo "Building with user info: USER_NAME=${USER_NAME}, UID=${UID}, GID=${GID}"

# 既存のコンテナを停止
source ./stop-pod.sh

# 旧イメージの削除
podman rmi ${CONTAINER_NAME} 1>/dev/null 2>/dev/null || true
echo "Clean old container successfully."

# イメージをビルド
echo "Building image..."
podman build -t ${CONTAINER_NAME} \
    --build-arg USER_NAME="${USER_NAME}" \
    --build-arg UID="${UID}" \
    --build-arg GID="${GID}" \
    ./src/

if [ $? -ne 0 ]; then
    echo "Error: Failed to build container."
    exit 1
fi

# 登録されたイメージの表示
podman images ${CONTAINER_NAME}

echo "Container built successfully."
