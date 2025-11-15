# 高度な設定

このドキュメントでは、Oracle Linux 8 開発用コンテナイメージを CI/CD パイプラインで使用する際の高度な設定について説明します。

## ナビゲーション

- [CI/CD でのコンテナイメージ利用ガイド](../using-in-cicd.md) - メインガイド
- [トラブルシューティング](./troubleshooting.md) - よくある問題と解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される運用方法

---

## 目次

- [UID/GID マッピングの理解](#uidgid-マッピングの理解)
- [キャッシュの活用](#キャッシュの活用)
- [マルチステージビルド](#マルチステージビルド)
- [並列ジョブ実行](#並列ジョブ実行)
- [セキュリティスキャン](#セキュリティスキャン)

## UID/GID マッピングの理解

このコンテナは、ホストとコンテナ間でファイル権限を保持するために UID/GID マッピングを使用します。

### GitHub Actions でのデフォルト UID/GID

```yaml
container:
  env:
    # GitHub Actions のデフォルト値
    HOST_USER: runner
    HOST_UID: 1001
    HOST_GID: 121
```

### カスタム UID/GID の設定

```yaml
container:
  env:
    # カスタム値を設定
    HOST_USER: myuser
    HOST_UID: 5000
    HOST_GID: 5000
```

## キャッシュの活用

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

## マルチステージビルド

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

## 並列ジョブ実行

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

## セキュリティスキャン

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

---

## 関連ドキュメント

- [CI/CD でのコンテナイメージ利用ガイド](../using-in-cicd.md) - メインガイド
- [トラブルシューティング](./troubleshooting.md) - よくある問題と解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される運用方法
- [GitHub Container Registry への公開ガイド](../publishing-to-github.md) - イメージの公開方法
