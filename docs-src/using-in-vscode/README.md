# VS Code Dev Container として使用する

このドキュメントでは、公開されている Oracle Linux 8 開発用コンテナイメージを、あなたのプロジェクトで VS Code の Dev Container として使用する方法を説明します。

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [クイックスタート](#クイックスタート)
4. [詳細な設定](#詳細な設定)
5. [カスタマイズ](#カスタマイズ)
6. [トラブルシューティング](#トラブルシューティング)
7. [Podman を使用する場合](#podman-を使用する場合)

## 概要

公開されているコンテナイメージ `ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev` を VS Code の Dev Container として使用することで、以下の利点が得られます：

- **一貫した開発環境**: 開発ツールとライブラリが事前設定済み
- **簡単なセットアップ**: 設定ファイルをコピーするだけ
- **統合された開発体験**: VS Code の全機能がコンテナ内で利用可能
- **環境の分離**: ホストシステムに影響を与えずに開発可能
- **すぐに使える**: イメージのビルド不要、ダウンロードして即開始

## 前提条件

### 必須

1. **Visual Studio Code**
   - [公式サイト](https://code.visualstudio.com/)からダウンロード・インストール

2. **Dev Containers 拡張機能**
   - VS Code で `ms-vscode-remote.remote-containers` をインストール
   - または、[こちら](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)からインストール

3. **コンテナエンジン**（以下のいずれか）
   - **Docker Desktop** (推奨)
     - Windows/Mac: [Docker Desktop](https://www.docker.com/products/docker-desktop/)
     - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
   - **Podman**
     - [Podman のセットアップ手順](#podman-を使用する場合)を参照

### 推奨

- Git クライアント
- 十分なディスクスペース（イメージサイズ: 約 5GB）
- 最低 8GB のメモリ（推奨: 16GB 以上）

## クイックスタート

### 1. サンプル設定のコピー

[examples/devcontainer/](../../examples/devcontainer/) から設定ファイルをあなたのプロジェクトにコピー：

```bash
# あなたのプロジェクトディレクトリで
cd /path/to/your/project

# サンプル設定をコピー
cp -r /path/to/oracle-linux-8-container/examples/devcontainer .devcontainer
```

または、手動で `.devcontainer/devcontainer.json` を作成：

```json
{
  "name": "Oracle Linux 8 Development Container",
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
  "postCreateCommand": "bash -c 'export HOST_USER=${localEnv:USER:vscode} HOST_UID=${localEnv:UID:1000} HOST_GID=${localEnv:GID:1000} && sudo /usr/local/bin/devcontainer-entrypoint.sh'",
  "remoteUser": "${localEnv:USER:vscode}",
  "containerUser": "root",
  "containerEnv": {
    "LANG": "ja_JP.UTF-8"
  },
  "mounts": [
    "source=${localWorkspaceFolderBasename}-home,target=/home/${localEnv:USER:vscode},type=volume",
    "source=${localEnv:HOME}/.ssh,target=/tmp/host-ssh,type=bind,readonly,consistency=cached"
  ],
  "workspaceFolder": "/workspace",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
  "forwardPorts": []
}
```

### 2. VS Code で開く

```bash
code /path/to/your/project
```

### 3. Dev Container で再度開く

VS Code が起動したら：

1. コマンドパレットを開く（`Ctrl+Shift+P` / `Cmd+Shift+P`）
2. `Dev Containers: Reopen in Container` を選択
3. 初回はイメージのダウンロードに数分かかります（進行状況が表示されます）
4. ダウンロード完了後、コンテナ内で VS Code が起動します

### 4. 開発を開始

ターミナルを開いて、開発ツールが利用可能なことを確認：

```bash
# バージョン確認
node --version    # Node.js 22
java -version     # OpenJDK 17
dotnet --version  # .NET 9.0
python --version  # Python 3.11

# ドキュメント生成ツール
doxygen --version
plantuml -version
pandoc --version

# ビルドツール
cmake --version
gcc --version
```

## 詳細な設定

### 主要な設定項目

#### イメージの指定

公開されたイメージを使用：

```json
{
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest"
}
```

特定のバージョンを使用する場合：

```json
{
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:v20250116"
}
```

#### ユーザー設定

コンテナ内のユーザーは、ホストのユーザー名とUID/GIDに基づいて自動的に作成されます：

- `postCreateCommand` でユーザーセットアップスクリプトを実行
- `remoteUser` でコンテナ内で使用するユーザーを指定
- `containerUser` を `root` に設定（ユーザー作成のため）

#### マウント設定

- **ワークスペース**: プロジェクトのルートディレクトリが `/workspace` にマウント
- **ホームディレクトリ**: Docker volume として永続化（コンテナ削除後も保持）
- **SSH 認証情報**: ホストの `~/.ssh` が `/tmp/host-ssh` に読み取り専用でマウント

#### VS Code 拡張機能

サンプル設定には以下の拡張機能が含まれています：

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "dbaeumer.vscode-eslint",
        "vscjava.vscode-java-pack",
        "ms-dotnettools.csdevkit",
        "ms-python.python",
        "cschlosser.doxdocgen",
        "jebbs.plantuml"
      ]
    }
  }
}
```

プロジェクトに応じて追加・削除してください。

### 環境変数

以下の環境変数がコンテナ内で設定されます：

- `LANG`: `ja_JP.UTF-8` (日本語ロケール)

追加の環境変数は `containerEnv` で設定：

```json
{
  "containerEnv": {
    "NODE_ENV": "development",
    "DEBUG": "true"
  }
}
```

## カスタマイズ

### プロジェクト別の設定例

#### Node.js プロジェクト

```json
{
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
  "postCreateCommand": "bash -c 'export HOST_USER=${localEnv:USER:vscode} HOST_UID=${localEnv:UID:1000} HOST_GID=${localEnv:GID:1000} && sudo /usr/local/bin/devcontainer-entrypoint.sh && npm install'",
  "forwardPorts": [3000],
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

#### Python プロジェクト

```json
{
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
  "postCreateCommand": "bash -c 'export HOST_USER=${localEnv:USER:vscode} HOST_UID=${localEnv:UID:1000} HOST_GID=${localEnv:GID:1000} && sudo /usr/local/bin/devcontainer-entrypoint.sh && pip install -r requirements.txt'",
  "forwardPorts": [8000],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  }
}
```

#### C/C++ プロジェクト

```json
{
  "image": "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
  "postCreateCommand": "bash -c 'export HOST_USER=${localEnv:USER:vscode} HOST_UID=${localEnv:UID:1000} HOST_GID=${localEnv:GID:1000} && sudo /usr/local/bin/devcontainer-entrypoint.sh && mkdir -p build && cd build && cmake ..'",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "cschlosser.doxdocgen"
      ]
    }
  }
}
```

### ポート転送

開発サーバーのポートを自動的に転送：

```json
{
  "forwardPorts": [3000, 8080, 5432]
}
```

## トラブルシューティング

### イメージのダウンロードが失敗する

**症状**: イメージのダウンロード中にエラーが発生

**解決方法**:
1. インターネット接続を確認
2. Docker Desktop / Podman が起動していることを確認
3. 手動でイメージをダウンロード：
   ```bash
   docker pull ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest
   # または
   podman pull ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest
   ```

### ファイルの権限エラー

**症状**: コンテナ内でファイルの作成・編集ができない

**原因**: UID/GID のマッピングが正しく設定されていない

**解決方法**:
1. コンテナを再起動
2. `devcontainer.json` の `postCreateCommand` が正しく設定されているか確認
3. Linux の場合、以下のコマンドで UID/GID を確認：
   ```bash
   id -u  # UID
   id -g  # GID
   ```
4. 必要に応じて `devcontainer.json` の `HOST_UID` と `HOST_GID` を調整

### SSH 認証情報が利用できない

**症状**: Git の push/pull で認証エラーが発生

**解決方法**:
1. ホストの `~/.ssh` ディレクトリが存在し、鍵が配置されていることを確認
2. コンテナ内で SSH エージェントを設定：
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_rsa
   ```
3. または、Git 認証に HTTPS + トークンを使用

### パフォーマンスが遅い

**症状**: ファイル操作やビルドが遅い

**解決方法**:
1. **Windows/Mac の場合**: Docker Desktop のリソース割り当てを増やす
   - Settings > Resources > Advanced
   - CPU とメモリを増やす
2. **ファイルマウント最適化**:
   - `devcontainer.json` で `consistency` オプションを調整
   - `cached` または `delegated` を使用

## Podman を使用する場合

Docker の代わりに Podman を使用する場合の手順：

### 1. Podman のインストール

```bash
# Fedora/RHEL/CentOS
sudo dnf install -y podman

# Ubuntu/Debian
sudo apt-get install -y podman

# macOS
brew install podman
```

### 2. Podman の設定

#### Linux の場合

```bash
# Podman ソケットを有効化（Docker 互換モード）
systemctl --user enable --now podman.socket

# 環境変数を設定
export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock
```

VS Code の設定（`settings.json`）に追加：

```json
{
  "dev.containers.dockerPath": "podman",
  "dev.containers.dockerSocketPath": "/run/user/${localEnv:UID}/podman/podman.sock"
}
```

#### macOS/Windows の場合

```bash
# Podman マシンの初期化
podman machine init
podman machine start

# Docker 互換モードの設定
podman machine set --rootful
```

VS Code の設定（`settings.json`）に追加：

```json
{
  "dev.containers.dockerPath": "podman"
}
```

### 3. devcontainer.json の調整

Podman 使用時は `runArgs` を調整する場合があります：

```json
{
  "runArgs": [
    "--userns=keep-id",
    "--security-opt", "label=disable"
  ]
}
```

## 関連ドキュメント

- [VS Code Dev Containers 公式ドキュメント](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container 仕様](https://containers.dev/)
- [Docker 公式ドキュメント](https://docs.docker.com/)
- [Podman 公式ドキュメント](https://podman.io/docs)
- [サンプル設定](../../examples/devcontainer/)
- [プロジェクトルートの README](../../README.md)
- [CLAUDE.md](../../CLAUDE.md) - Claude Code を使用する際の詳細ガイド
