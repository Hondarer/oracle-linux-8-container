FROM oraclelinux:8
EXPOSE 22

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
        colord-libs \
        dconf \
        dejavu-fonts-common \
        dejavu-sans-mono-fonts \
        desktop-file-utils \
        dotnet-sdk-9.0 \
        doxygen-doxywizard.x86_64 \
        doxygen-latex.x86_64 \
        doxygen.x86_64 \
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

# 環境変数を設定
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV SHELL="/bin/bash"

# 追加フォント
ADD fonts /tmp/fonts/
RUN if [ -n "$(ls -A /tmp/fonts 2>/dev/null)" ]; then \
        echo "Installing fonts..."; \
        chown root:root /tmp/fonts/* && \
        chmod 0644 /tmp/fonts/* && \
        cp /tmp/fonts/* /usr/share/fonts/. && \
        fc-cache -fv > /dev/null 2>&1; \
    fi && \
    rm -rf /tmp/fonts

# packages の配置
ADD packages /tmp/packages/

# man-pages-ja
RUN cd /tmp && \
    if [ ! -f packages/man-pages-ja-20231115.tar.gz ]; then \
        curl -o packages/man-pages-ja-20231115.tar.gz https://linuxjm.sourceforge.io/man-pages-ja-20231115.tar.gz; \
    fi && \
    tar xzf packages/man-pages-ja-20231115.tar.gz && \
    cd man-pages-ja-20231115 && \
    sh /tmp/packages/man-pages-ja-auto-installer.sh && \
    rm -rf /tmp/man-pages-ja-20231115

# doxybook2
RUN cd /tmp && \
    if [ ! -f packages/doxybook2.el8.x86_64-1.6.1.tar.gz ]; then \
        curl -L -o packages/doxybook2.el8.x86_64-1.6.1.tar.gz https://github.com/Hondarer/doxybook2.el8.x86_64/archive/refs/tags/v1.6.1.tar.gz; \
    fi && \
    tar xfz packages/doxybook2.el8.x86_64-1.6.1.tar.gz && \
    chown -R root:root doxybook2.el8.x86_64-1.6.1 && \
    cp -rp doxybook2.el8.x86_64-1.6.1/bin/* /usr/local/bin/. && \
    cp -rp doxybook2.el8.x86_64-1.6.1/include/* /usr/local/include/. && \
    cp -rp doxybook2.el8.x86_64-1.6.1/lib/* /usr/local/lib/. && \
    rm -rf /tmp/doxybook2.el8.x86_64-1.6.1

# pandoc
RUN cd /tmp && \
    if [ ! -f packages/pandoc-3.7.0.2-linux-amd64.tar.gz ]; then \
        curl -L -o packages/pandoc-3.7.0.2-linux-amd64.tar.gz https://github.com/jgm/pandoc/releases/download/3.7.0.2/pandoc-3.7.0.2-linux-amd64.tar.gz; \
    fi && \
    tar xfz packages/pandoc-3.7.0.2-linux-amd64.tar.gz && \
    BASE="pandoc-3.7.0.2" && \
    install -d /usr/local/bin /usr/local/share/man/man1 && \
    install -m 0755 "$BASE/bin/pandoc" /usr/local/bin/pandoc && \
    ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-server && \
    ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-lua && \
    install -m 0644 "$BASE/share/man/man1/pandoc.1.gz" /usr/local/share/man/man1/pandoc.1.gz && \
    install -m 0644 "$BASE/share/man/man1/pandoc-server.1.gz" /usr/local/share/man/man1/pandoc-server.1.gz && \
    install -m 0644 "$BASE/share/man/man1/pandoc-lua.1.gz" /usr/local/share/man/man1/pandoc-lua.1.gz && \
    rm -rf "/tmp/$BASE"

# pandoc-crossref
RUN cd /tmp && \
    if [ ! -f packages/pandoc-crossref-Linux-X64.tar.xz ]; then \
        curl -L -o packages/pandoc-crossref-Linux-X64.tar.xz https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.20/pandoc-crossref-Linux-X64.tar.xz; \
    fi && \
    tar xfJ packages/pandoc-crossref-Linux-X64.tar.xz && \
    gzip -9n pandoc-crossref.1 && \
    install -d /usr/local/bin /usr/local/share/man/man1 && \
    install -m 0755 "pandoc-crossref" /usr/local/bin/pandoc-crossref && \
    install -m 0644 "pandoc-crossref.1.gz" /usr/local/share/man/man1/pandoc-crossref.1.gz && \
    rm -rf /tmp/pandoc-crossref /tmp/pandoc-crossref pandoc-crossref.1.gz

# googletest
RUN cd /tmp && \
    if [ ! -f packages/googletest-1.17.0.el8.x86_64.tar.gz ]; then \
        curl -L -o packages/googletest-1.17.0.el8.x86_64.tar.gz https://github.com/Hondarer/googletest.el8.x86_64/releases/download/v1.17.0/googletest-1.17.0.el8.x86_64.tar.gz; \
    fi && \
    cd / && tar xfz /tmp/packages/googletest-1.17.0.el8.x86_64.tar.gz

# plantuml
RUN cd /tmp && \
    if [ ! -f packages/plantuml-1.2025.4.jar ]; then \
        curl -L -o packages/plantuml-1.2025.4.jar https://github.com/plantuml/plantuml/releases/download/v1.2025.4/plantuml-1.2025.4.jar; \
    fi && \
    chown root:root packages/plantuml-1.2025.4.jar && \
    cp packages/plantuml-1.2025.4.jar /usr/local/bin/ && \
    cd /usr/local/bin && ln -s plantuml-1.2025.4.jar plantuml.jar && \
    echo -e "#!/bin/bash" > /usr/local/bin/plantuml && \
    echo -e "export LANG=ja_JP.UTF-8" >> /usr/local/bin/plantuml && \
    echo -e "/usr/bin/java -Djava.io.tmpdir=/var/tmp -Djava.awt.headless=true -jar /usr/local/bin/plantuml.jar -charset UTF-8 \"\$@\"" >> /usr/local/bin/plantuml && \
    chmod 0755 /usr/local/bin/plantuml

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
