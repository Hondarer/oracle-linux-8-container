#!/bin/bash

# Dockerfile で USER ${USER_NAME} されている
USER_NAME=$(whoami)

# USER_HOME が空 (~/.ssh は評価対象から除く) の場合に初期ファイルを配置
if [ -z "$(find /home/${USER_NAME} -mindepth 1 -not -path "/home/${USER_NAME}/.ssh/*" -not -name ".ssh" -print -quit)" ]; then
    echo "Initializing home for ${USER_NAME}..."

    cd /tmp
    rm -rf temp_home
    mkdir temp_home
    cd temp_home
    cp -a /etc/skel/. .

    echo export LANG=ja_JP.UTF-8 >> .bashrc

    echo 'export PATH="$HOME/.node_modules/bin:$PATH"' >> .bashrc
    echo "prefix=/home/${USER_NAME}/.node_modules" >> .npmrc
    mkdir -p .node_modules/bin

    cd /tmp
    chown -R ${USER_NAME}:${USER_NAME} temp_home
    chmod 700 temp_home

    cp -rp /tmp/temp_home/. /home/${USER_NAME}/.
fi

# authorized_keys ファイルの存在チェック
# ※ベースイメージの /etc/ssh/sshd_config が以下の前提
#
# #PubkeyAuthentication yes
#
# # To disable tunneled clear text passwords, change to no here!
# #PasswordAuthentication yes
# #PermitEmptyPasswords no
# PasswordAuthentication yes
#
if [ -f /home/${USER_NAME}/.ssh/authorized_keys ]; then
    # authorized_keys ファイルが存在する場合
    # SSH キー認証の有効化
    sudo sed -i 's/^#\s*PubkeyAuthentication\s\+yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    # SSH パスワード認証を無効化
    sudo sed -i 's/^\s*PasswordAuthentication\s\+yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# ssh を待ち受け (ここでブロックされる)
echo "Starting sshd..."
sudo /usr/sbin/sshd -D
