#!/bin/bash
#
# Dev Container 用エントリーポイントスクリプト
# VS Code の Dev Container として使用する際に、ユーザー環境をセットアップします。
# このスクリプトは root 権限で実行されることを想定しています。
#

# root 権限チェック
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    exit 1
fi

# 環境変数からユーザー情報を取得
HOST_USER=${HOST_USER:-vscode}
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

echo "Setting up Dev Container for user: ${HOST_USER} (UID: ${HOST_UID}, GID: ${HOST_GID})"

# グループの作成 (存在しない場合)
if ! getent group "${HOST_GID}" >/dev/null 2>&1; then
    groupadd -g "${HOST_GID}" "${HOST_USER}"
    echo "Created group: ${HOST_USER} (GID: ${HOST_GID})"
else
    EXISTING_GROUP=$(getent group "${HOST_GID}" | cut -d: -f1)
    echo "Group GID ${HOST_GID} already exists as: ${EXISTING_GROUP}"
    # 既存グループ名が HOST_USER と異なる場合、グループ名を変更
    if [ "${EXISTING_GROUP}" != "${HOST_USER}" ]; then
        groupmod -n "${HOST_USER}" "${EXISTING_GROUP}"
        echo "Renamed group ${EXISTING_GROUP} to ${HOST_USER}"
    fi
fi

# ユーザーの作成 (存在しない場合)
if ! getent passwd "${HOST_UID}" >/dev/null 2>&1; then
    useradd -u "${HOST_UID}" -g "${HOST_GID}" -G wheel -d "/home/${HOST_USER}" -m -s /bin/bash "${HOST_USER}"
    echo "Created user: ${HOST_USER} (UID: ${HOST_UID})"
else
    EXISTING_USER=$(getent passwd "${HOST_UID}" | cut -d: -f1)
    echo "User UID ${HOST_UID} already exists as: ${EXISTING_USER}"
    # 既存ユーザー名が HOST_USER と異なる場合、ユーザー名を変更
    if [ "${EXISTING_USER}" != "${HOST_USER}" ]; then
        usermod -l "${HOST_USER}" "${EXISTING_USER}"
        usermod -d "/home/${HOST_USER}" -m "${HOST_USER}"
        echo "Renamed user ${EXISTING_USER} to ${HOST_USER}"
    fi

    # wheel グループ所属チェックと追加
    if ! id -nG "${HOST_USER}" | grep -qw wheel; then
        usermod -aG wheel "${HOST_USER}"
        echo "Added ${HOST_USER} to wheel group"
    fi
fi

# パスワードの設定
echo "${HOST_USER}:${HOST_USER}_passwd" | chpasswd
echo "Set password for ${HOST_USER}: ${HOST_USER}_passwd"

# ホームディレクトリの所有権を確認・修正
if [ -d "/home/${HOST_USER}" ]; then
    current_uid=$(stat -c "%u" "/home/${HOST_USER}")
    current_gid=$(stat -c "%g" "/home/${HOST_USER}")
    if [ "$current_uid" -ne "$HOST_UID" ] || [ "$current_gid" -ne "$HOST_GID" ]; then
        chown "${HOST_UID}:${HOST_GID}" "/home/${HOST_USER}"
    fi
fi

# ワークスペースディレクトリの所有権を確認・修正
if [ -d "/workspace" ]; then
    current_uid=$(stat -c "%u" "/workspace")
    current_gid=$(stat -c "%g" "/workspace")
    if [ "$current_uid" -ne "$HOST_UID" ] || [ "$current_gid" -ne "$HOST_GID" ]; then
        chown "${HOST_UID}:${HOST_GID}" "/workspace"
    fi
fi

# USER_HOME が空 (~/.ssh は評価対象から除く) の場合に初期ファイルを配置
if [ -z "$(find /home/${HOST_USER} -mindepth 1 -not -path "/home/${HOST_USER}/.ssh/*" -not -name ".ssh" -print -quit 2>/dev/null)" ]; then
    echo "Initializing home for ${HOST_USER}..."

    cd /tmp
    rm -rf temp_home
    mkdir temp_home
    cd temp_home
    cp -a /etc/skel/. .

    echo export LANG=ja_JP.UTF-8 >> .bashrc

    echo 'export PATH="$HOME/.node_modules/bin:$PATH"' >> .bashrc
    echo "prefix=/home/${HOST_USER}/.node_modules" >> .npmrc
    mkdir -p .node_modules/bin

    cd /tmp
    chown -R "${HOST_UID}:${HOST_GID}" temp_home
    chmod 700 temp_home

    cp -rp /tmp/temp_home/. /home/${HOST_USER}/.
    rm -rf /tmp/temp_home
fi

# ホストの SSH 鍵をコピー（オプション）
if [ -d /tmp/host-ssh ] && [ -n "$(ls -A /tmp/host-ssh 2>/dev/null)" ]; then
    echo "Copying SSH keys from host..."
    mkdir -p /home/${HOST_USER}/.ssh
    cp -r /tmp/host-ssh/* /home/${HOST_USER}/.ssh/
    chown -R "${HOST_UID}:${HOST_GID}" /home/${HOST_USER}/.ssh
    chmod 700 /home/${HOST_USER}/.ssh
    chmod 600 /home/${HOST_USER}/.ssh/* 2>/dev/null || true
fi

echo "Dev Container setup completed successfully!"
echo "User: ${HOST_USER}"
echo "Home: /home/${HOST_USER}"
echo "Workspace: /workspace"
