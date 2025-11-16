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
{
    echo "# Container Build Information"
    printf "%-18s = %s\n" "BUILD_TYPE" "local"
    printf "%-18s = %s\n" "BUILD_DATE" "$(date +%Y-%m-%dT%H:%M:%S%z)"
    printf "%-18s = %s\n" "BUILD_HOST" "$(uname -n 2>/dev/null || echo 'unknown')"

    # Git コミットハッシュと変更状態の取得
    GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')
    if [ "${GIT_COMMIT}" != "unknown" ]; then
        # 未コミットの変更がある場合は + を付与
        git diff-index --quiet HEAD 2>/dev/null || GIT_COMMIT="${GIT_COMMIT}+"
    fi
    printf "%-18s = %s\n" "GIT_COMMIT" "${GIT_COMMIT}"

    printf "%-18s = %s\n" "GIT_BRANCH" "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"

    # タグの取得
    GIT_TAG=$(git describe --exact-match --tags 2>/dev/null || echo '(none)')
    printf "%-18s = %s\n" "GIT_TAG" "${GIT_TAG}"

    # バージョンの抽出 (タグから v プレフィックスを除去)
    if [ "${GIT_TAG}" != "(none)" ]; then
        VERSION=${GIT_TAG#v}
    else
        VERSION="dev"
    fi
    printf "%-18s = %s\n" "VERSION" "${VERSION}"

    printf "%-18s = %s\n" "BUILDER" "${USER}"
} > ./src/container-release

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
