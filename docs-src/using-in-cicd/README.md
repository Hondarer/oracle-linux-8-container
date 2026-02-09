# CI/CD でのコンテナイメージ利用ガイド

このディレクトリには、Oracle Linux 開発用コンテナイメージを他のリポジトリの CI/CD パイプラインで利用する方法に関するドキュメントが含まれています。

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

## ドキュメント一覧

### はじめに

- **[基本的な使い方](./basics.md)**
  - イメージの取得方法
  - コンテナの起動方法
  - 環境変数の説明
  - GitHub Actions での基本的なワークフロー

### 言語・フレームワーク別サンプル

実際のプロジェクトで使用できる GitHub Actions ワークフローの実践例です。

- **[C/C++ プロジェクト](./cpp-example.md)**
  - CMake によるビルド設定
  - gcovr によるコードカバレッジ測定
  - Doxygen によるドキュメント生成

- **[Node.js プロジェクト](./nodejs-example.md)**
  - npm による依存関係管理
  - ESLint によるコード品質チェック
  - Jest/Mocha を使ったテスト実行
  - カバレッジレポートの生成

- **[Java プロジェクト](./java-example.md)**
  - Maven によるビルドとテスト
  - JUnit を使ったユニットテスト
  - JavaDoc ドキュメント生成
  - JAR パッケージの作成

- **[Python プロジェクト](./python-example.md)**
  - venv による仮想環境管理
  - pytest を使ったテスト実行
  - flake8 による静的解析
  - カバレッジ測定とレポート生成

- **[.NET プロジェクト](./dotnet-example.md)**
  - dotnet CLI によるビルド
  - xUnit/NUnit を使ったテスト
  - カバレッジ測定
  - アプリケーションの公開

- **[ドキュメント生成](./documentation-example.md)**
  - Doxygen によるコードドキュメント生成
  - doxybook2 による Markdown 変換
  - PlantUML 図の生成
  - Pandoc による PDF 生成
  - GitHub Pages へのデプロイ

### 高度な設定

- **[高度な設定](./advanced-configuration.md)**
  - UID/GID マッピングの詳細
  - キャッシュの活用方法
  - マルチステージビルド
  - 並列ジョブ実行
  - セキュリティスキャン (Trivy)
  - SSH サービスの利用
  - ジョブマトリクスによる複数バージョンテスト

### トラブルシューティング

- **[トラブルシューティング](./troubleshooting.md)**
  - コンテナ起動時のエラー対処
  - 権限エラーの解決方法
  - ビルドエラーの対処
  - ネットワークエラーの対処
  - デバッグ方法

### ベストプラクティス

- **[ベストプラクティス](./best-practices.md)**
  - イメージバージョンの固定
  - キャッシュの活用
  - 最小権限の原則
  - シークレットの安全な管理
  - 失敗時の通知設定
  - タイムアウトの設定
  - アーティファクトの保存
  - 環境の再現性
  - ドキュメントの自動生成
  - 定期的なイメージ更新

## クイックスタート

### 基本的なワークフロー例

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

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: runner
        HOST_UID: 1001
        HOST_GID: 121

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build project
        run: make all

      - name: Run tests
        run: make test
```

詳細は [基本的な使い方](./basics.md) を参照してください。

## 環境変数

コンテナ起動時に以下の環境変数を設定できます：

| 環境変数 | 説明 | デフォルト値 |
|---------|------|------------|
| `HOST_USER` | コンテナ内で作成するユーザー名 | `user` |
| `HOST_UID` | ユーザーの UID | `1000` |
| `HOST_GID` | ユーザーの GID | `1000` |

## よくある使用パターン

### パターン 1: シンプルなビルド・テスト

プロジェクトをチェックアウトして、ビルドとテストを実行する基本的なパターン。

→ [基本的な使い方](./basics.md) を参照

### パターン 2: 複数言語のプロジェクト

C++、Node.js、Python など複数の言語が混在するプロジェクト。

→ 各言語のサンプルドキュメントを組み合わせて使用

### パターン 3: ドキュメント自動生成

コードから自動的にドキュメントを生成し、GitHub Pages にデプロイ。

→ [ドキュメント生成](./documentation-example.md) を参照

### パターン 4: マトリクステスト

複数のバージョンやパラメータでテストを実行。

→ [高度な設定](./advanced-configuration.md#ジョブマトリクスによる複数バージョンテスト) を参照

## サポート

問題が発生した場合は、以下のリソースを参照してください：

- [トラブルシューティング](./troubleshooting.md) - よくある問題と解決方法
- [GitHub Issues](https://github.com/<user>/<repo>/issues) - バグ報告や機能リクエスト
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions) - GitHub Actions の公式ドキュメント

## 関連ドキュメント

- [GitHub Container Registry への公開ガイド](../publishing-to-github.md) - イメージの公開方法
- [CLAUDE.md](../../CLAUDE.md) - プロジェクトの詳細仕様
- [README.md](../../README.md) - プロジェクト概要とクイックスタート
