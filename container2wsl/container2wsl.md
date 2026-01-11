# ghcr.io からコンテナイメージをダウンロードし、WSL2 にインポートする手順

このドキュメントでは、GitHub Container Registry (ghcr.io) に公開されている Oracle Linux 8 コンテナイメージを **外部ツール不要で** Windows 環境からダウンロードし、WSL2 にインポートする方法を説明します。

## 前提条件

- **OS**: Windows 10 (1803以降) または Windows 11
- **WSL2**: インストール済み
- **インターネット接続**

このスクリプトは Podman や Docker などの外部ツールを一切必要としません。Windows 標準の PowerShell、tar.exe、wsl.exe のみで動作します。

## クイックスタート

### ステップ 1: WSL2 のインストール (未インストールの場合)

管理者権限で PowerShell を起動し、以下を実行:

```powershell
wsl --install
```

インストール後、システムを再起動します。

### ステップ 2: スクリプトの実行

```powershell
# リポジトリのルートディレクトリに移動
cd path\to\oracle-linux-8-container

# スクリプトを実行 (デフォルト設定)
.\import-from-ghcr.ps1
```

スクリプトは以下の処理を自動実行します:

1. 前提条件のチェック (WSL2、tar コマンド)
2. ghcr.io から認証トークンを取得
3. イメージマニフェストをダウンロード
4. すべてのレイヤーをダウンロード
5. rootfs を構築
6. tar.gz にアーカイブ
7. WSL2 にインポート

### ステップ 3: インポートされたディストリビューションを起動

```powershell
# ディストリビューションを起動
wsl -d OracleLinux8-Dev

# またはデフォルトに設定
wsl --set-default OracleLinux8-Dev
wsl
```

## カスタムオプション

### 基本的なオプション

```powershell
# カスタムディストリビューション名を指定
.\import-from-ghcr.ps1 -WslDistroName "MyOracleLinux"

# 特定のタグを指定
.\import-from-ghcr.ps1 -ImageUrl "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:v1.0.0"

# インストール先を指定
.\import-from-ghcr.ps1 -InstallLocation "D:\WSL\OracleLinux8"

# 一時ディレクトリを指定
.\import-from-ghcr.ps1 -TempDir "D:\temp\wsl-import"
```

### すべてのオプションを組み合わせる例

```powershell
.\import-from-ghcr.ps1 `
    -ImageUrl "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest" `
    -WslDistroName "OracleLinux8-Custom" `
    -InstallLocation "D:\WSL\OracleLinux8-Custom" `
    -TempDir "D:\temp\wsl-import-custom"
```

---

## 動作原理

このスクリプトは OCI (Open Container Initiative) Registry API v2 を使用して、コンテナイメージを直接ダウンロードします。

### 処理フロー

```text
1. ghcr.io API v2 に接続
   ↓
2. 匿名認証トークンを取得
   ↓
3. イメージマニフェストを取得
   ↓
4. マニフェストからレイヤー情報を抽出
   ↓
5. 各レイヤーを順番にダウンロード
   ↓
6. レイヤーを順番に展開して rootfs を構築
   ↓
7. rootfs を tar.gz にアーカイブ
   ↓
8. wsl --import で WSL2 にインポート
```

### 使用する Windows 標準ツール

| ツール | 用途 | 最小要件 |
|--------|------|----------|
| **PowerShell** | HTTP リクエスト、スクリプト実行 | Windows 10/11 標準 |
| **tar.exe** | アーカイブの展開・作成 | Windows 10 1803以降 |
| **wsl.exe** | WSL2 管理 | WSL2 有効化済み |

## インポート後の確認

### ディストリビューション一覧の確認

```powershell
wsl --list --verbose
```

出力例:
```text
  NAME              STATE           VERSION
* OracleLinux8-Dev  Running         2
  Ubuntu            Stopped         2
```

### OS 情報の確認

```powershell
wsl -d OracleLinux8-Dev cat /etc/os-release
```

出力例:
```text
NAME="Oracle Linux Server"
VERSION="8.x"
ID="ol"
PRETTY_NAME="Oracle Linux Server 8.x"
...
```

## 補足情報

### イメージのタグ一覧を確認

GitHub Container Registry で利用可能なタグを確認するには:

1. ブラウザで https://github.com/Hondarer/oracle-linux-8-container/pkgs/container/oracle-linux-8-container%2Foracle-linux-8-dev にアクセス
2. 利用可能なバージョン/タグを確認

### プライベートイメージの認証

現在のスクリプトは匿名アクセス (パブリックイメージ) のみをサポートしています。

プライベートイメージの場合、スクリプトの `Get-RegistryToken` 関数を以下のように修正してください:

```powershell
function Get-RegistryToken {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Username,  # 追加
        [string]$Token      # GitHub Personal Access Token (packages:read 権限)
    )

    $credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Token}"))
    $headers = @{
        "Authorization" = "Basic $credentials"
    }

    $tokenUrl = "https://$Registry/token?service=$Registry&scope=repository:$Image`:pull"
    $response = Invoke-RestMethod -Uri $tokenUrl -Method Get -Headers $headers
    return $response.token
}
```

### ディストリビューションの削除

インポートしたディストリビューションを削除する場合:

```powershell
# ディストリビューションを削除
wsl --unregister OracleLinux8-Dev

# インストール先ディレクトリも削除する場合
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\WSL\OracleLinux8-Dev"
```

## トラブルシューティング

### WSL2 がインストールされていない

エラー:

```text
WSL2 がインストールされていません。'wsl --install' を実行してください。
```

対処法:

```powershell
# 管理者権限で PowerShell を起動し、以下を実行
wsl --install

# システムを再起動
```

### tar コマンドが見つからない

エラー:

```text
tar コマンドが見つかりません。Windows 10 (1803以降) または Windows 11 が必要です。
```

対処法:

- Windows 10 の場合: バージョン 1803 以降にアップデートしてください
- Windows 11 の場合: tar は標準搭載されているため、環境変数 PATH を確認してください

### 認証エラー

エラー:

```text
認証エラー: 401 Unauthorized
```

対処法:

- パブリックイメージの場合: イメージ URL が正しいか確認してください
- プライベートイメージの場合: 上記の「プライベートイメージの認証」セクションを参照してください

### レイヤーのダウンロード失敗

エラー:

```text
[X/Y] ダウンロード失敗: sha256:...
```

対処法:

- インターネット接続を確認してください
- ファイアウォールやプロキシ設定を確認してください
- スクリプトを再実行してください

### ディスク容量不足

エラー:

```text
tar コマンドの実行に失敗しました
```

対処法:

- Oracle Linux 8 開発コンテナは約 2-3GB のディスク容量が必要です
- 一時ディレクトリ (`$env:TEMP`) と WSL インストール先に十分な空き容量があるか確認してください
- `-TempDir` オプションで別のドライブを指定できます:
  ```powershell
  .\import-from-ghcr.ps1 -TempDir "D:\temp\wsl-import"
  ```

### ディストリビューション名が既に存在する

警告:

```text
警告: ディストリビューション 'OracleLinux8-Dev' は既に存在します
既存のディストリビューションを削除して続行しますか? (y/N)
```

対処法:

- `y` を入力して既存のディストリビューションを削除するか
- `-WslDistroName` オプションで別の名前を指定してください:
  ```powershell
  .\import-from-ghcr.ps1 -WslDistroName "OracleLinux8-Dev2"
  ```

## 技術的な詳細

### OCI Registry API v2 について

このスクリプトは、Open Container Initiative (OCI) が定義する Registry API v2 仕様を実装しています。

**主要なエンドポイント:**

| エンドポイント | 説明 |
|---------------|------|
| `/token` | 認証トークンを取得 |
| `/v2/{name}/manifests/{reference}` | イメージマニフェストを取得 |
| `/v2/{name}/blobs/{digest}` | レイヤー (blob) をダウンロード |

**マニフェスト形式の対応:**

- Docker Image Manifest V2
- OCI Image Manifest V1
- Docker Manifest List V2 (マルチプラットフォーム)
- OCI Image Index V1 (マルチプラットフォーム)

マルチプラットフォームイメージの場合、スクリプトは自動的に `linux/amd64` プラットフォームを選択します。

### rootfs 構築の仕組み

コンテナイメージは複数のレイヤー (tar.gz ファイル) で構成されています。各レイヤーは差分情報を含み、これらを順番に展開することで完全な rootfs が構築されます。

```text
Layer 1 (Base): /bin, /usr, /etc, ...
Layer 2 (Update): /usr/lib/updated-file.so
Layer 3 (Application): /app/myapp
...
↓ 順番に展開
rootfs: 完全なファイルシステム
```

### WSL2 インポート形式

`wsl --import` コマンドは、Linux ファイルシステムのルートディレクトリ (`/`) を tar または tar.gz 形式でアーカイブしたファイルを受け付けます。

このスクリプトは、OCI イメージレイヤーから構築した rootfs を tar.gz 形式でアーカイブして WSL2 にインポートします。

## 参考リンク

- [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec)
- [OCI Image Format Specification](https://github.com/opencontainers/image-spec)
- [WSL2 公式ドキュメント](https://docs.microsoft.com/ja-jp/windows/wsl/)
- [GitHub Container Registry ドキュメント](https://docs.github.com/ja/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
