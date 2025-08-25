#!/bin/bash

# rootless podman-compose では、正しく UID のマッピングができない (userns が利用できない) ため、
# podman を直接操作する

CONTAINER_NAME=oracle-linux-8

# src/keys が存在しない場合は作成
if [ ! -d ./src/keys ]; then
    echo "Creating ./src/keys directory..."
    mkdir -p ./src/keys
fi

# src/packages が存在しない場合は作成
if [ ! -d ./src/packages ]; then
    echo "Creating ./src/packages directory..."
    mkdir -p ./src/packages
fi

# src/fonts が存在しない場合は作成
if [ ! -d ./src/fonts ]; then
    echo "Creating ./src/fonts directory..."
    mkdir -p ./src/fonts
fi

# container-release の作成
echo "Build on $(LANG=C && date)" > ./src/container-release

echo "Building container image..."

# 既存のコンテナを停止
source ./stop-pod.sh

# 旧イメージの削除
podman rmi ${CONTAINER_NAME} 1>/dev/null 2>/dev/null || true
echo "Clean old container successfully."

# イメージをビルド
echo "Building image..."
podman build -t ${CONTAINER_NAME} ./src/

if [ $? -ne 0 ]; then
    echo "Error: Failed to build container."
    exit 1
fi

# 登録されたイメージの表示
podman images ${CONTAINER_NAME}

echo "Container built successfully."
