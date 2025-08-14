FROM oraclelinux:8
EXPOSE 22

# ビルド引数の定義
ARG USER_NAME=user
ARG UID=1000
ARG GID=1000

# パッケージの更新とインストール
RUN dnf update -y && \
    yum-config-manager --enable ol8_codeready_builder && \
    dnf install oracle-epel-release-el8 && \
    yum-config-manager --enable ol8_developer_EPEL && \
    dnf group install -y 'Development Tools' && \
    dnf install -y \
        sudo \
        glibc-langpack-ja \
        nkf \
        jq \
        lsof \
        libcurl-devel \
        sysstat \
        binutils-devel \
        libX11-devel \
        libXt-devel && \
    dnf module -y enable nodejs:22 && \
    dnf install -y \
        nodejs \
        npm \
        adwaita-cursor-theme \
        adwaita-icon-theme \
        at-spi2-atk \
        at-spi2-core \
        cairo-gobject \
        colord-libs \
        dejavu-fonts-common \
        desktop-file-utils \
        glib-networking \
        gsettings-desktop-schemas \
        gtk3 \
        hwdata \
        json-glib \
        libXtst \
        libdrm \
        libepoxy \
        liberation-fonts \
        liberation-fonts-common \
        liberation-mono-fonts \
        liberation-sans-fonts \
        liberation-serif-fonts \
        libgusb \
        libmodman \
        libpciaccess \
        libproxy \
        libsoup \
        libwayland-client \
        libwayland-cursor \
        libwayland-egl \
        libwayland-server \
        libxkbcommon \
        libxshmfence \
        llvm-compat-libs \
        mesa-libgbm \
        mesa-vulkan-drivers \
        rest \
        vulkan-loader \
        xdg-utils \
        xkeyboard-config \
        abattis-cantarell-fonts \
        dconf \
        dejavu-sans-mono-fonts \
        libGL \
        vlgothic-fonts \
        java-17-openjdk \
        java-17-openjdk-devel \
        doxygen.x86_64 \
        doxygen-doxywizard.x86_64 \
        doxygen-latex.x86_64 \
        bc \
        tree \
        rsync \
        libstdc++-static \
        glibc-static \
        dotnet-sdk-9.0 && \
    alternatives --set python /usr/bin/python3.11 && \
    alternatives --set java $(alternatives --display java 2>/dev/null | grep -E "java-17-openjdk.*bin/java" | head -1 | awk '{print $1}') && \
    dnf install -y \
        python3.11-pip && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.11 2 && \
    pip install \
        hjson \
        gcovr && \
    dnf clean all

# FIXME: 未対応
#        googletest
#        plantuml
#        メイリオ
#        doxybook2
#        pandoc
#        pandoc-crossref
#        man

# container-release の配置
ADD /container-release /etc

# user のホーム初期化スクリプトを追加
ADD entrypoint.sh /usr/local/bin
RUN chown root:root /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# Oracle Linux 用の環境変数を設定
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV SHELL="/bin/bash"

# ロケール設定
ENV LANG=ja_JP.UTF-8

# SSH ホストキーの生成
# 再接続時は ssh-keygen -R "[127.0.0.1]:40022" などを行い過去のホストキーをクリアすること
# TODO: SSH ホストキーは、src の下で保持できるようにしたほうがいい
RUN ssh-keygen -A

# デフォルトユーザー作成
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/wheel && \
    groupadd -g ${GID} ${USER_NAME} && \
    useradd -u ${UID} -g ${GID} -G wheel -d /home/${USER_NAME} -m -s /bin/bash ${USER_NAME} && \
    echo ${USER_NAME}:${USER_NAME}_passwd | chpasswd

# ユーザーの切り替え
USER ${USER_NAME}

# 作業用ディレクトリの作成
WORKDIR /workspace

# コンテナ起動時に実行するスクリプト
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
