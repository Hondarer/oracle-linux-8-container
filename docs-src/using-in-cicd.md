# CI/CD でのコンテナイメージ利用ガイド

このドキュメントでは、Oracle Linux 8 開発用コンテナイメージを他のリポジトリの CI/CD パイプラインで利用する方法を詳しく説明します。

## 目次

- [概要](#概要)
- [基本的な使い方](#基本的な使い方)
- [GitHub Actions での利用](#github-actions-での利用)
- [ビルド・テストの実践例](#ビルドテストの実践例)
- [高度な設定](#高度な設定)
- [トラブルシューティング](#トラブルシューティング)
- [ベストプラクティス](#ベストプラクティス)

## 概要

このコンテナイメージは、以下の用途に最適化されています：

- **マルチ言語プロジェクト**: Node.js、Java、.NET、Python、C/C++ をサポート
- **ドキュメント生成**: Doxygen、PlantUML、Pandoc を含む
- **日本語環境**: 日本語ロケールとマニュアルページを標準装備
- **ポータブル設計**: 起動時に動的にユーザーを作成し、UID/GID をマッピング

### コンテナイメージの種類

```bash
# 公開イメージ (GitHub Container Registry)
ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
ghcr.io/<user>/<repo>/oracle-linux-8-dev:v1.0.0

# ローカルビルドイメージ
oracle-linux-8-dev:latest
```

## 基本的な使い方

### イメージの取得

```bash
# GitHub Container Registry から取得 (パブリックイメージの場合)
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

# プライベートイメージの場合は事前にログイン
echo $GITHUB_TOKEN | podman login ghcr.io -u <username> --password-stdin
podman pull ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### コンテナの起動

```bash
# 基本的な起動
podman run -it --rm \
  -e HOST_USER=developer \
  -e HOST_UID=1000 \
  -e HOST_GID=1000 \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

# ボリュームマウントを使った起動
podman run -it --rm \
  -e HOST_USER=developer \
  -e HOST_UID=1000 \
  -e HOST_GID=1000 \
  -v ./project:/workspace:Z \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### 環境変数

| 環境変数 | 説明 | デフォルト値 |
|---------|------|------------|
| `HOST_USER` | コンテナ内で作成するユーザー名 | `user` |
| `HOST_UID` | ユーザーの UID | `1000` |
| `HOST_GID` | ユーザーの GID | `1000` |

## GitHub Actions での利用

### 基本的なワークフロー

以下は、このコンテナイメージを使用してビルドとテストを実行する基本的なワークフローです。

```yaml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    # コンテナイメージを指定
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      # プライベートイメージの場合は認証情報を設定
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      # 環境変数を設定
      env:
        HOST_USER: runner
        HOST_UID: 1001
        HOST_GID: 121

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

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
          java --version
          python --version
          dotnet --version

      - name: Build project
        run: |
          # ビルドコマンドを実行
          make all

      - name: Run tests
        run: |
          # テストコマンドを実行
          make test
```

### SSH サービスを利用する場合

SSH サーバーを起動してリモート操作が必要な場合の例です。

```yaml
name: Build with SSH

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    services:
      oracle-dev:
        image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
        credentials:
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
        env:
          HOST_USER: developer
          HOST_UID: 1000
          HOST_GID: 1000
        ports:
          - 2222:22
        volumes:
          - ${{ github.workspace }}:/workspace

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
          # SSH ホストキーの確認をスキップ
          echo "Host *" >> ~/.ssh/config
          echo "  StrictHostKeyChecking no" >> ~/.ssh/config
          echo "  UserKnownHostsFile=/dev/null" >> ~/.ssh/config

      - name: Copy SSH key to container
        run: |
          # コンテナに公開鍵をコピー
          docker cp ~/.ssh/id_rsa.pub oracle-dev:/tmp/
          docker exec oracle-dev bash -c \
            "mkdir -p /home/developer/.ssh && \
             cat /tmp/id_rsa.pub >> /home/developer/.ssh/authorized_keys && \
             chown -R developer:developer /home/developer/.ssh && \
             chmod 700 /home/developer/.ssh && \
             chmod 600 /home/developer/.ssh/authorized_keys"

      - name: Build via SSH
        run: |
          ssh -p 2222 developer@localhost "cd /workspace && make all"

      - name: Test via SSH
        run: |
          ssh -p 2222 developer@localhost "cd /workspace && make test"
```

### ジョブマトリクスを使った複数バージョンテスト

```yaml
name: Multi-version Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        # 複数のイメージバージョンでテスト
        image-version: [latest, v1.0.0, v1.1.0]

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:${{ matrix.image-version }}
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: tester
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run tests
        run: |
          echo "Testing with image version: ${{ matrix.image-version }}"
          make test
```

## ビルド・テストの実践例

### C/C++ プロジェクト

```yaml
name: C++ Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: builder
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          # 追加の依存パッケージがあればインストール
          sudo dnf install -y boost-devel

      - name: Configure with CMake
        run: |
          mkdir -p build
          cd build
          cmake -DCMAKE_BUILD_TYPE=Release \
                -DBUILD_TESTING=ON \
                ..

      - name: Build
        run: |
          cd build
          make -j$(nproc)

      - name: Run unit tests
        run: |
          cd build
          ctest --output-on-failure

      - name: Generate code coverage
        run: |
          cd build
          gcovr --root .. \
                --filter '../src/' \
                --xml-pretty \
                --output coverage.xml

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          files: ./build/coverage.xml

      - name: Generate documentation
        run: |
          doxygen Doxyfile

      - name: Upload documentation
        uses: actions/upload-artifact@v3
        with:
          name: documentation
          path: docs/html/
```

### Node.js プロジェクト

```yaml
name: Node.js Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: nodedev
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          npm ci

      - name: Lint
        run: |
          npm run lint

      - name: Build
        run: |
          npm run build

      - name: Run tests
        run: |
          npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

      - name: Build distribution
        run: |
          npm run dist

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
```

### Java プロジェクト (Maven)

```yaml
name: Java Maven Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: javadev
        HOST_UID: 1000
        HOST_GID: 1000
        JAVA_HOME: /usr/lib/jvm/java-17-openjdk

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Maven
        run: |
          sudo dnf install -y maven

      - name: Build with Maven
        run: |
          mvn clean package -DskipTests

      - name: Run tests
        run: |
          mvn test

      - name: Generate JavaDoc
        run: |
          mvn javadoc:javadoc

      - name: Upload JAR
        uses: actions/upload-artifact@v3
        with:
          name: jar-package
          path: target/*.jar
```

### Python プロジェクト

```yaml
name: Python Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: pythondev
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Create virtual environment
        run: |
          python -m venv venv
          source venv/bin/activate
          pip install --upgrade pip

      - name: Install dependencies
        run: |
          source venv/bin/activate
          pip install -r requirements.txt
          pip install pytest pytest-cov flake8

      - name: Lint with flake8
        run: |
          source venv/bin/activate
          flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics

      - name: Run tests with coverage
        run: |
          source venv/bin/activate
          pytest --cov=src --cov-report=xml --cov-report=html

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
```

### .NET プロジェクト

```yaml
name: .NET Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: dotnetdev
        HOST_UID: 1000
        HOST_GID: 1000
        DOTNET_CLI_TELEMETRY_OPTOUT: 1
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE: 1

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Restore dependencies
        run: |
          dotnet restore

      - name: Build
        run: |
          dotnet build --configuration Release --no-restore

      - name: Run tests
        run: |
          dotnet test --configuration Release --no-build --verbosity normal \
            --collect:"XPlat Code Coverage" \
            --results-directory ./coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/**/coverage.cobertura.xml

      - name: Publish
        run: |
          dotnet publish --configuration Release --no-build \
            --output ./publish

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: published-app
          path: ./publish/
```

### ドキュメント生成専用ジョブ

```yaml
name: Generate Documentation

on:
  push:
    branches: [ main ]

jobs:
  docs:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: docgen
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Generate Doxygen documentation
        run: |
          doxygen Doxyfile

      - name: Convert to Markdown with doxybook2
        run: |
          doxybook2 --input ./docs/xml \
                    --output ./docs/markdown \
                    --config .doxybook/config.json

      - name: Generate PlantUML diagrams
        run: |
          find ./docs -name "*.puml" -exec plantuml {} \;

      - name: Build PDF with Pandoc
        run: |
          cd docs/markdown
          pandoc *.md \
            --filter pandoc-crossref \
            --pdf-engine=xelatex \
            --toc \
            --number-sections \
            -o ../documentation.pdf \
            -V documentclass=ltjsarticle \
            -V lang=ja

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/html
```

## 高度な設定

### UID/GID マッピングの理解

このコンテナは、ホストとコンテナ間でファイル権限を保持するために UID/GID マッピングを使用します。

#### GitHub Actions でのデフォルト UID/GID

```yaml
container:
  env:
    # GitHub Actions のデフォルト値
    HOST_USER: runner
    HOST_UID: 1001
    HOST_GID: 121
```

#### カスタム UID/GID の設定

```yaml
container:
  env:
    # カスタム値を設定
    HOST_USER: myuser
    HOST_UID: 5000
    HOST_GID: 5000
```

### キャッシュの活用

依存関係のインストール時間を短縮するためにキャッシュを活用します。

```yaml
steps:
  - name: Cache Node.js modules
    uses: actions/cache@v3
    with:
      path: |
        ~/.node_modules
        node_modules
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-

  - name: Install dependencies
    run: npm ci
```

### マルチステージビルド

複数のステージに分けて効率的にビルドします。

```yaml
jobs:
  # ステージ1: ビルド
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make all
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-output
          path: build/

  # ステージ2: テスト
  test:
    needs: build
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-output
          path: build/
      - name: Run tests
        run: make test

  # ステージ3: デプロイ
  deploy:
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy application
        run: echo "Deploying..."
```

### 並列ジョブ実行

複数のテストを並列実行して時間を短縮します。

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        test-suite: [unit, integration, e2e]

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4

      - name: Run ${{ matrix.test-suite }} tests
        run: |
          make test-${{ matrix.test-suite }}
```

### セキュリティスキャン

コンテナイメージとコードの脆弱性をスキャンします。

```yaml
jobs:
  security-scan:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

## トラブルシューティング

### コンテナ起動時のエラー

#### 問題: entrypoint.sh でユーザー作成に失敗する

```text
Error: useradd: UID 1000 is not unique
```

**解決方法**: 既存の UID と競合しています。別の UID を指定してください。

```yaml
container:
  env:
    HOST_UID: 1100  # 別の UID を使用
    HOST_GID: 1100
```

#### 問題: SSH サービスが起動しない

```text
Error: sshd: no hostkeys available
```

**解決方法**: SSH ホストキーが正しく配置されていることを確認してください。コンテナイメージには事前に SSH ホストキーが含まれています。

### 権限エラー

#### 問題: ファイルへの書き込み権限がない

```text
Error: Permission denied
```

**解決方法**: UID/GID が正しく設定されているか確認してください。

```yaml
container:
  env:
    # GitHub Actions のランナーと同じ UID/GID を使用
    HOST_USER: runner
    HOST_UID: 1001
    HOST_GID: 121
```

#### 問題: sudo が使えない

```text
Error: user is not in the sudoers file
```

**解決方法**: entrypoint.sh が正常に実行され、ユーザーが wheel グループに追加されていることを確認してください。

```yaml
steps:
  - name: Check user groups
    run: |
      id
      groups
```

### ビルドエラー

#### 問題: メモリ不足

```text
Error: virtual memory exhausted: Cannot allocate memory
```

**解決方法**: 並列ビルドの数を制限するか、より大きなランナーを使用してください。

```yaml
steps:
  - name: Build with limited parallelism
    run: |
      make -j2  # 並列数を制限
```

#### 問題: 依存パッケージがない

```text
Error: command not found
```

**解決方法**: 必要なパッケージをインストールしてください。

```yaml
steps:
  - name: Install additional packages
    run: |
      sudo dnf install -y <package-name>
```

### ネットワークエラー

#### 問題: イメージの pull に失敗する

```text
Error: unauthorized: authentication required
```

**解決方法**: 認証情報が正しく設定されているか確認してください。

```yaml
container:
  credentials:
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

プライベートイメージの場合は、適切な権限を持つトークンを使用してください。

### デバッグ方法

#### コンテナ内の状態を確認

```yaml
steps:
  - name: Debug container state
    run: |
      echo "=== Current user ==="
      whoami
      id

      echo "=== Environment variables ==="
      env | sort

      echo "=== Working directory ==="
      pwd
      ls -la

      echo "=== Mounted volumes ==="
      df -h

      echo "=== Network configuration ==="
      ip addr

      echo "=== Running processes ==="
      ps aux

      echo "=== System resources ==="
      free -h
      cat /proc/cpuinfo | grep "model name" | head -1
```

#### entrypoint.sh のログを確認

```yaml
steps:
  - name: Check entrypoint logs
    run: |
      cat /var/log/entrypoint.log
```

## ベストプラクティス

### 1. イメージバージョンの固定

本番環境では、`latest` タグではなく特定のバージョンを使用してください。

```yaml
# 推奨
container:
  image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:v1.0.0

# 非推奨 (本番環境では)
container:
  image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### 2. キャッシュの活用

ビルド時間を短縮するために、依存関係のキャッシュを活用してください。

```yaml
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: ~/.cache
    key: ${{ runner.os }}-deps-${{ hashFiles('**/lockfile') }}
```

### 3. 最小権限の原則

必要最小限の権限のみを付与してください。

```yaml
permissions:
  contents: read      # リポジトリの読み取り
  packages: read      # パッケージの読み取り
  # 不要な権限は付与しない
```

### 4. シークレットの安全な管理

機密情報は環境変数やファイルに直接記述せず、GitHub Secrets を使用してください。

```yaml
steps:
  - name: Use secrets safely
    env:
      API_KEY: ${{ secrets.API_KEY }}
    run: |
      # シークレットを使用
      echo "Using API key: ${API_KEY:0:5}..."  # 最初の数文字のみ表示
```

### 5. 失敗時の通知

ビルドやテストが失敗した場合に通知を受け取る設定をしてください。

```yaml
jobs:
  notify:
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Send notification
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 6. タイムアウトの設定

長時間実行されるジョブにはタイムアウトを設定してください。

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # 30分でタイムアウト
```

### 7. アーティファクトの保存

ビルド成果物は適切に保存してください。

```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: |
      build/
      dist/
    retention-days: 7  # 7日間保存
```

### 8. 環境の再現性

開発環境と CI/CD 環境で同じコンテナイメージを使用して、環境の差異を最小限に抑えてください。

```bash
# ローカル開発環境
podman run -it --rm \
  -e HOST_USER=$USER \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -v ./:/workspace:Z \
  ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
```

### 9. ドキュメントの自動生成

ドキュメントは自動生成して最新の状態を保ってください。

```yaml
- name: Generate and deploy docs
  run: |
    doxygen Doxyfile
    doxybook2 --input docs/xml --output docs/markdown
```

### 10. 定期的なイメージ更新

セキュリティパッチを適用するために、定期的にコンテナイメージを更新してください。

```yaml
on:
  schedule:
    # 毎週月曜日の午前2時に実行
    - cron: '0 2 * * 1'
```

## 関連ドキュメント

- [GitHub Container Registry への公開ガイド](./publishing-to-github.md) - イメージの公開方法
- [CLAUDE.md](../CLAUDE.md) - プロジェクトの詳細仕様
- [README.md](../README.md) - プロジェクト概要とクイックスタート

## サポート

問題が発生した場合は、以下のリソースを参照してください：

- [GitHub Issues](https://github.com/<user>/<repo>/issues) - バグ報告や機能リクエスト
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions) - GitHub Actions の公式ドキュメント
- [Podman ドキュメント](https://docs.podman.io/) - Podman の公式ドキュメント
