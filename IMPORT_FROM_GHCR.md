# ghcr.io からコンテナイメージをダウンロードし、WSL2 にインポートする手順

このドキュメントでは、GitHub Container Registry (ghcr.io) に公開されている Oracle Linux 8 コンテナイメージを Windows 環境でダウンロードし、WSL2 にインポートする方法を説明します。

## 前提条件

- **OS**: Windows 11 または Windows 10 (WSL2 対応バージョン)
- **WSL2**: インストール済み
- **PowerShell**: 管理者権限で実行可能

## アプローチ概要

このリポジトリでは、2つのアプローチを提供しています:

### アプローチ 1: PowerShell スクリプト (推奨)

自動化された PowerShell スクリプトを使用して、ワンステップでイメージをダウンロード・インポートします。

### アプローチ 2: WSL2 内で直接ダウンロード (シンプル)

WSL2 内で Podman を使用して直接イメージをプルします。

---

## アプローチ 1: PowerShell スクリプトを使用

### ステップ 1: Podman for Windows のインストール

管理者権限で PowerShell を起動し、以下を実行:

```powershell
winget install -e --id RedHat.Podman
```

インストール後、PowerShell を再起動します。

### ステップ 2: スクリプトの実行

```powershell
# リポジトリのルートディレクトリに移動
cd path\to\oracle-linux-8-container

# スクリプトを実行
.\import-from-ghcr.ps1
```

#### オプション指定例

```powershell
# 特定の WSL ディストリビューションを指定
.\import-from-ghcr.ps1 -TargetWslDistro "Ubuntu-22.04"

# カスタムイメージ URL を指定
.\import-from-ghcr.ps1 -ImageUrl "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:v1.0.0"

# 一時ディレクトリを指定
.\import-from-ghcr.ps1 -TempDir "D:\temp\podman-import"
```

### ステップ 3: インポートの確認

WSL2 内で以下を実行して、イメージがインポートされたことを確認:

```bash
wsl podman images
```

出力例:
```
REPOSITORY                                                      TAG         IMAGE ID      CREATED      SIZE
ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev    latest      abc123def456  2 days ago   2.5GB
```

---

## アプローチ 2: WSL2 内で直接ダウンロード

### ステップ 1: WSL2 のインストール

管理者権限で PowerShell を起動し、以下を実行:

```powershell
wsl --install
```

再起動後、WSL2 が利用可能になります。

### ステップ 2: WSL2 内で Podman をインストール

WSL2 ターミナルを起動し、以下を実行:

```bash
# Ubuntu/Debian の場合
sudo apt-get update
sudo apt-get install -y podman

# または、より新しいバージョンをインストールする場合
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y podman
```

### ステップ 3: イメージのプル

```bash
podman pull ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest
```

### ステップ 4: イメージの確認

```bash
podman images
```

---

## 補足情報

### イメージのタグ一覧を確認

GitHub Container Registry で利用可能なタグを確認するには:

1. ブラウザで https://github.com/Hondarer/oracle-linux-8-container/pkgs/container/oracle-linux-8-container%2Foracle-linux-8-dev にアクセス
2. 利用可能なバージョン/タグを確認

### プライベートイメージの認証

イメージがプライベートリポジトリに存在する場合、認証が必要です:

```powershell
# Windows Podman の場合
podman login ghcr.io
# ユーザー名: GitHubユーザー名
# パスワード: Personal Access Token (packages:read 権限必要)
```

```bash
# WSL2 内の Podman の場合
podman login ghcr.io
# ユーザー名: GitHubユーザー名
# パスワード: Personal Access Token (packages:read 権限必要)
```

### イメージの tar.gz 保存と読み込み (手動)

既存の `save-pod.sh` と `load-pod.sh` スクリプトを使用する場合:

#### Windows 側で保存

```powershell
# イメージをプル
podman pull ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest

# tar.gz 形式で保存
podman save ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest | gzip -9 > oracle-linux-8-dev.tar.gz

# WSL2 からアクセス可能な場所にコピー
# 例: C:\Users\YourName\Downloads\oracle-linux-8-dev.tar.gz
```

#### WSL2 側で読み込み

```bash
# tar.gz ファイルを WSL2 ホームディレクトリにコピー
cp /mnt/c/Users/YourName/Downloads/oracle-linux-8-dev.tar.gz ~/

# イメージを読み込み
gunzip -c ~/oracle-linux-8-dev.tar.gz | podman load

# イメージにタグを付ける (必要に応じて)
podman tag <IMAGE_ID> oracle-linux-8:latest
```

### トラブルシューティング

#### Podman Machine が起動しない

```powershell
# Podman Machine を再作成
podman machine stop
podman machine rm
podman machine init
podman machine start
```

#### WSL2 で Podman が見つからない

```bash
# Podman のインストールを確認
which podman

# インストールされていない場合はインストール
sudo apt-get update && sudo apt-get install -y podman
```

#### イメージサイズが大きすぎる

Oracle Linux 8 開発コンテナは複数の開発ツールを含むため、サイズが大きくなります (約 2GB 以上)。十分なディスク容量を確保してください。

---

## 参考リンク

- [Podman 公式ドキュメント](https://podman.io/)
- [WSL2 公式ドキュメント](https://docs.microsoft.com/ja-jp/windows/wsl/)
- [GitHub Container Registry ドキュメント](https://docs.github.com/ja/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
