FROM oraclelinux:8

# ポート 22 を公開する宣言
EXPOSE 22

# 環境変数を設定
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV SHELL="/bin/bash"

# UID:1000 以上のユーザーとグループの削除 (nobody は除外)
RUN echo "Listing users with UID >= 1000:"; \
    awk -F: '$3 >= 1000 {print $1 ":" $3}' /etc/passwd && \
    echo "Removing users with UID >= 1000 and their home directories (excluding nobody):"; \
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read user; do \
        echo "Removing user: $user"; \
        userdel -r "$user" 2>/dev/null || true; \
    done && \
    echo "Listing groups with GID >= 1000:"; \
    awk -F: '$3 >= 1000 {print $1 ":" $3}' /etc/group && \
    echo "Removing groups with GID >= 1000 (excluding nobody):"; \
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/group | while read group; do \
        echo "Removing group: $group"; \
        groupdel "$group" 2>/dev/null || true; \
    done

# パッケージの更新とインストール
RUN dnf update -y && \
    dnf install -y \
        oracle-epel-release-el8 \
        dnf-plugins-core && \
    dnf config-manager --enable \
        ol8_codeready_builder \
        ol8_developer_EPEL && \
    dnf group install -y 'Development Tools' && \
    dnf module -y enable nodejs:22 && \
    dnf install -y \
        abattis-cantarell-fonts \
        adwaita-cursor-theme \
        adwaita-icon-theme \
        at-spi2-atk \
        at-spi2-core \
        bc \
        binutils-devel \
        cairo-gobject \
        cmake \
        colord-libs \
        dconf \
        dejavu-fonts-common \
        dejavu-sans-mono-fonts \
        desktop-file-utils \
        dotnet-sdk-9.0 \
        expect \
        glib-networking \
        glibc-langpack-ja \
        glibc-static \
        gsettings-desktop-schemas \
        gtk3 \
        hwdata \
        java-17-openjdk \
        java-17-openjdk-devel \
        jq \
        json-glib \
        libGL \
        libX11-devel \
        libXt-devel \
        libXtst \
        libcurl-devel \
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
        libstdc++-static \
        libwayland-client \
        libwayland-cursor \
        libwayland-egl \
        libwayland-server \
        libxkbcommon \
        libxshmfence \
        llvm-compat-libs \
        lsof \
        man-db \
        man-pages \
        mesa-libgbm \
        mesa-vulkan-drivers \
        nkf \
        nodejs \
        npm \
        perl-Env \
        python3.11-pip \
        rest \
        rsync \
        sudo \
        sysstat \
        tree \
        vlgothic-fonts \
        vulkan-loader \
        xdg-utils \
        xkeyboard-config && \
    alternatives --set java $(alternatives --display java 2>/dev/null | grep -E "java-17-openjdk.*bin/java" | head -1 | awk '{print $1}') && \
    alternatives --set python /usr/bin/python3.11 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.11 2 && \
    pip install \
        hjson \
        gcovr && \
    dnf clean all && \
    rm -f /var/log/dnf* /var/log/hawkey.log && \
    rm -rf /var/cache/dnf

# ロケールを設定
ENV LANG=ja_JP.UTF-8

# 追加フォント
RUN --mount=type=bind,source=fonts,target=/tmp/fonts,readonly \
    if [ -n "$(ls -A /tmp/fonts 2>/dev/null)" ]; then \
        echo "Installing fonts..."; \
        cp /tmp/fonts/* /usr/share/fonts/ && \
        chown root:root /usr/share/fonts/* && \
        chmod 0644 /usr/share/fonts/* && \
        fc-cache -fv > /dev/null 2>&1; \
    fi

# 追加パッケージのインストール
RUN --mount=type=bind,source=packages,target=/tmp/packages,readonly \
    cd /tmp && \
    # man-pages-ja
    if [ ! -f packages/man-pages-ja-20231115.tar.gz ]; then \
        curl -o /tmp/man-pages-ja-20231115.tar.gz https://linuxjm.sourceforge.io/man-pages-ja-20231115.tar.gz; \
    else \
        cp packages/man-pages-ja-20231115.tar.gz /tmp/; \
    fi && \
    tar xzf man-pages-ja-20231115.tar.gz && \
    cd man-pages-ja-20231115 && \
    if [ -f /tmp/packages/man-pages-ja-auto-installer.sh ]; then \
        sh /tmp/packages/man-pages-ja-auto-installer.sh; \
    fi && \
    cd /tmp && rm -rf man-pages-ja-20231115 && \
    # doxybook2
    if [ ! -f packages/doxybook2.el8.x86_64-1.6.1.tar.gz ]; then \
        curl -L -o /tmp/doxybook2.el8.x86_64-1.6.1.tar.gz https://github.com/Hondarer/doxybook2.el8.x86_64/archive/refs/tags/v1.6.1.tar.gz; \
    else \
        cp packages/doxybook2.el8.x86_64-1.6.1.tar.gz /tmp/; \
    fi && \
    tar xfz doxybook2.el8.x86_64-1.6.1.tar.gz && \
    chown -R root:root doxybook2.el8.x86_64-1.6.1 && \
    cp -rp doxybook2.el8.x86_64-1.6.1/bin/* /usr/local/bin/ && \
    cp -rp doxybook2.el8.x86_64-1.6.1/include/* /usr/local/include/ && \
    cp -rp doxybook2.el8.x86_64-1.6.1/lib/* /usr/local/lib/ && \
    rm -rf doxybook2.el8.x86_64-1.6.1 && \
    # pandoc
    if [ ! -f packages/pandoc-3.7.0.2-linux-amd64.tar.gz ]; then \
        curl -L -o /tmp/pandoc-3.7.0.2-linux-amd64.tar.gz https://github.com/jgm/pandoc/releases/download/3.7.0.2/pandoc-3.7.0.2-linux-amd64.tar.gz; \
    else \
        cp packages/pandoc-3.7.0.2-linux-amd64.tar.gz /tmp/; \
    fi && \
    tar xfz pandoc-3.7.0.2-linux-amd64.tar.gz && \
    BASE="pandoc-3.7.0.2" && \
    install -d /usr/local/bin /usr/local/share/man/man1 && \
    install -m 0755 "$BASE/bin/pandoc" /usr/local/bin/pandoc && \
    ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-server && \
    ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-lua && \
    install -m 0644 "$BASE/share/man/man1/pandoc.1.gz" /usr/local/share/man/man1/pandoc.1.gz && \
    install -m 0644 "$BASE/share/man/man1/pandoc-server.1.gz" /usr/local/share/man/man1/pandoc-server.1.gz && \
    install -m 0644 "$BASE/share/man/man1/pandoc-lua.1.gz" /usr/local/share/man/man1/pandoc-lua.1.gz && \
    rm -rf "$BASE" && \
    # pandoc-crossref
    if [ ! -f packages/pandoc-crossref-Linux-X64.tar.xz ]; then \
        curl -L -o /tmp/pandoc-crossref-Linux-X64.tar.xz https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.20/pandoc-crossref-Linux-X64.tar.xz; \
    else \
        cp packages/pandoc-crossref-Linux-X64.tar.xz /tmp/; \
    fi && \
    tar xfJ pandoc-crossref-Linux-X64.tar.xz && \
    gzip -9n pandoc-crossref.1 && \
    install -d /usr/local/bin /usr/local/share/man/man1 && \
    install -m 0755 "pandoc-crossref" /usr/local/bin/pandoc-crossref && \
    install -m 0644 "pandoc-crossref.1.gz" /usr/local/share/man/man1/pandoc-crossref.1.gz && \
    rm -f pandoc-crossref pandoc-crossref.1.gz && \
    # googletest
    if [ ! -f packages/googletest-lib-1.17.0.tar.gz ]; then \
        curl -L -o /tmp/googletest-lib-1.17.0.tar.gz https://github.com/Hondarer/googletest-lib/archive/refs/tags/v1.17.0.tar.gz; \
    else \
        cp packages/googletest-lib-1.17.0.tar.gz /tmp/; \
    fi && \
    cd /tmp && tar xfz /tmp/googletest-lib-1.17.0.tar.gz && \
    chmod -R 0755 googletest-lib-1.17.0 && find googletest-lib-1.17.0 -type f -exec chmod 644 {} + && \
    cd googletest-lib-1.17.0/include && cp -rp * /usr/local/include/. && \
    cd ../lib/linux/x86_64/gcc/release && cp -rp * /usr/local/lib64/. && \
    # plantuml
    cd /tmp && \
    if [ ! -f packages/plantuml-1.2025.4.jar ]; then \
        curl -L -o /tmp/plantuml-1.2025.4.jar https://github.com/plantuml/plantuml/releases/download/v1.2025.4/plantuml-1.2025.4.jar; \
    else \
        cp packages/plantuml-1.2025.4.jar /tmp/; \
    fi && \
    chown root:root plantuml-1.2025.4.jar && \
    chmod 0755 plantuml-1.2025.4.jar && \
    cp plantuml-1.2025.4.jar /usr/local/bin/ && \
    cd /usr/local/bin && ln -s plantuml-1.2025.4.jar plantuml.jar && \
    echo -e "#!/bin/bash" > /usr/local/bin/plantuml && \
    echo -e "export LANG=ja_JP.UTF-8" >> /usr/local/bin/plantuml && \
    echo -e "/usr/bin/java -Djava.io.tmpdir=/var/tmp -Djava.awt.headless=true -jar /usr/local/bin/plantuml.jar -charset UTF-8 \"\$@\"" >> /usr/local/bin/plantuml && \
    chmod 0755 /usr/local/bin/plantuml && \
    echo -e "#!/bin/bash" > /etc/profile.d/plantuml.sh && \
    echo -e "export PLANTUML_HOME=/usr/local/bin" >> /etc/profile.d/plantuml.sh && \
    chmod 0644 /etc/profile.d/plantuml.sh && \
    # doxygen
    cd /tmp && \
    if [ ! -f packages/doxygen-1.14.0.src.tar.gz ]; then \
        curl -L -o /tmp/doxygen-1.14.0.src.tar.gz https://doxygen.nl/files/doxygen-1.14.0.src.tar.gz; \
    else \
        cp packages/doxygen-1.14.0.src.tar.gz /tmp/; \
    fi && \
    tar xfz doxygen-1.14.0.src.tar.gz && \
    cd doxygen-1.14.0 && \
    mkdir build && \
    cd build && \
    cmake -G "Unix Makefiles" \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D build_wizard=OFF \
        -W no-dev .. && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf doxygen-1.14.0 && \
    # clean up
    rm -f /tmp/*.tar.* /tmp/*.jar

# mandb
RUN echo "Processing manual pages with mandb..."; \
    mandb > /dev/null 2>&1

# SSH ホストキーの配置または生成
# keys にssh_host_*_key* が存在する場合は、ファイルを /etc/ssh にコピーし適切なオーナー、パーミッションを設定
# 存在しない場合は、SSH ホストキーの生成
# SSH ホストキー生成後の再接続時は `ssh-keygen -R "[127.0.0.1]:40022"` などを行い過去のホストキーをクリアすること
ADD keys /tmp/keys/
RUN if [ -n "$(ls -A /tmp/keys/ssh_host_*_key* 2>/dev/null)" ]; then \
        echo "Using existing SSH host keys"; \
        cp /tmp/keys/ssh_host_*_key* /etc/ssh/ && \
        chown root:root /etc/ssh/ssh_host_*_key* && \
        chmod 0600 /etc/ssh/ssh_host_*_key && \
        chmod 0644 /etc/ssh/ssh_host_*_key.pub; \
    else \
        echo "Generating new SSH host keys"; \
        ssh-keygen -A; \
    fi

# clean /tmp
RUN rm -rf /tmp/*

# wheel グループの sudo 設定
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/wheel

# container-release の配置
ADD container-release /etc

# 作業用ディレクトリの作成
WORKDIR /workspace

# エントリーポイント用スクリプトの配置
ADD entrypoint.sh /usr/local/bin
RUN chown root:root /usr/local/bin/entrypoint.sh && \
    chmod 0755 /usr/local/bin/entrypoint.sh

# エントリーポイントの設定
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/entrypoint.sh 2>&1 | tee /var/log/entrypoint.log"]
