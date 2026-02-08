# 基本的な使い方

このドキュメントでは、Oracle Linux 開発用コンテナイメージの基本的な使い方と GitHub Actions での基礎的なワークフローについて説明します。

## 目次

- [イメージの取得](#イメージの取得)
- [コンテナの起動](#コンテナの起動)
- [環境変数](#環境変数)
- [GitHub Actions での基本的なワークフロー](#github-actions-での基本的なワークフロー)
- [次のステップ](#次のステップ)

## イメージの取得

### パブリックイメージの取得

```bash
# GitHub Container Registry から取得
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

# Docker を使用する場合
docker pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### プライベートイメージの取得

プライベートイメージの場合は、事前に認証が必要です。

```bash
# GitHub Personal Access Token を使用してログイン
echo $GITHUB_TOKEN | podman login ghcr.io -u <username> --password-stdin

# イメージを取得
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### 特定バージョンの取得

```bash
# バージョンタグを指定して取得
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:v1.0.0

# SHA タグを指定して取得（再現性を確保）
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:sha-abc1234
```

## コンテナの起動

### 基本的な起動

```bash
# 最もシンプルな起動方法
podman run -it --rm \
  -e HOST_USER=developer \
  -e HOST_UID=1000 \
  -e HOST_GID=1000 \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### ボリュームマウントを使った起動

プロジェクトディレクトリをコンテナにマウントして起動します。

```bash
# カレントディレクトリを /workspace にマウント
podman run -it --rm \
  -e HOST_USER=developer \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -v ./:/workspace:Z \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

**注意**: `:Z` オプションは SELinux のコンテキストを適切に設定します（SELinux が有効な環境で必要）。

### バックグラウンドで起動

```bash
# SSH サービスを提供するコンテナとして起動
podman run -d \
  --name dev-container \
  -e HOST_USER=developer \
  -e HOST_UID=1000 \
  -e HOST_GID=1000 \
  -p 2222:22 \
  -v ./:/workspace:Z \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

# SSH で接続
ssh -p 2222 developer@localhost
```

## 環境変数

コンテナ起動時に以下の環境変数を設定できます：

### HOST_USER

コンテナ内で作成するユーザー名を指定します。

```bash
-e HOST_USER=myuser
```

- **デフォルト値**: `user`
- **用途**: コンテナ内のユーザー名を設定

### HOST_UID

作成するユーザーの UID を指定します。

```bash
-e HOST_UID=1000
```

- **デフォルト値**: `1000`
- **用途**: ホストとコンテナ間でファイル権限を保持
- **推奨**: ホストユーザーの UID と同じ値 (`$(id -u)`)

### HOST_GID

作成するユーザーの GID を指定します。

```bash
-e HOST_GID=1000
```

- **デフォルト値**: `1000`
- **用途**: ホストとコンテナ間でファイル権限を保持
- **推奨**: ホストユーザーの GID と同じ値 (`$(id -g)`)

### 環境変数の設定例

```bash
# ホストのユーザー情報と同じに設定
podman run -it --rm \
  -e HOST_USER=$USER \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -v ./:/workspace:Z \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

## GitHub Actions での基本的なワークフロー

### 最小限のワークフロー

以下は、このコンテナイメージを使用する最もシンプルなワークフローです。

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    # コンテナイメージを指定
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build project
        run: make all

      - name: Run tests
        run: make test
```

### プライベートイメージを使用する場合

プライベートイメージの場合は、認証情報を設定します。

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      # 認証情報を設定
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4
      - run: make all
      - run: make test
```

### 環境変数を設定する場合

GitHub Actions ランナーの UID/GID に合わせてユーザーを作成します。

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      # 環境変数を設定
      env:
        HOST_USER: runner
        HOST_UID: 1001
        HOST_GID: 121

    steps:
      - uses: actions/checkout@v4
      - run: make all
      - run: make test
```

**注意**: GitHub Actions の ubuntu-latest ランナーでは、デフォルトで UID=1001、GID=121 です。

### ツールバージョンの確認

コンテナに含まれるツールのバージョンを確認するステップを追加できます。

```yaml
steps:
  - name: Display environment info
    run: |
      echo "=== System Information ==="
      cat /etc/os-release
      echo ""
      echo "=== User Information ==="
      whoami
      id
      echo ""
      echo "=== Tool Versions ==="
      node --version
      npm --version
      java --version
      python --version
      dotnet --version
      gcc --version
      make --version

  - uses: actions/checkout@v4

  - name: Build project
    run: make all

  - name: Run tests
    run: make test
```

### 成果物のアップロード

ビルド成果物を保存する例です。

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Build project
    run: make all

  - name: Run tests
    run: make test

  - name: Upload build artifacts
    uses: actions/upload-artifact@v3
    with:
      name: build-output
      path: |
        build/
        dist/
      retention-days: 7
```

### 複数のジョブを定義

ビルドとテストを別々のジョブに分けることもできます。

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make all
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-output
          path: build/

  test:
    needs: build
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-output
          path: build/
      - name: Test
        run: make test
```

## ローカルでのテスト

GitHub Actions にプッシュする前に、ローカルで同じ環境をテストできます。

```bash
# プロジェクトディレクトリで実行
podman run -it --rm \
  -e HOST_USER=$USER \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -v ./:/workspace:Z \
  -w /workspace \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest \
  bash -c "make all && make test"
```

これにより、GitHub Actions と同じ環境でビルドとテストを実行できます。

## イメージの確認

### イメージの詳細情報を表示

```bash
# イメージの詳細情報を表示
podman inspect ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

# ラベル情報のみ表示
podman inspect ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest \
  --format '{{json .Config.Labels}}' | jq
```

### イメージのレイヤーを表示

```bash
# イメージの履歴を表示
podman history ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

## 次のステップ

基本的な使い方を理解したら、以下のドキュメントを参照して具体的なユースケースを確認してください：

### 言語・フレームワーク別サンプル

- [C/C++ プロジェクト](./cpp-example.md) - CMake、GoogleTest、Doxygen
- [Node.js プロジェクト](./nodejs-example.md) - npm、Jest、ESLint
- [Java プロジェクト](./java-example.md) - Maven、JUnit、JavaDoc
- [Python プロジェクト](./python-example.md) - pytest、flake8、カバレッジ
- [.NET プロジェクト](./dotnet-example.md) - dotnet CLI、xUnit
- [ドキュメント生成](./documentation-example.md) - Doxygen、PlantUML、Pandoc

### より高度な使い方

- [高度な設定](./advanced-configuration.md) - キャッシュ、マトリクステスト、セキュリティスキャン
- [トラブルシューティング](./troubleshooting.md) - よくある問題と解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される設定とパターン

## 参考リンク

- [GitHub Actions ドキュメント](https://docs.github.com/en/actions) - GitHub Actions の公式ドキュメント
- [Podman ドキュメント](https://docs.podman.io/) - Podman の公式ドキュメント
- [Docker ドキュメント](https://docs.docker.com/) - Docker の公式ドキュメント
