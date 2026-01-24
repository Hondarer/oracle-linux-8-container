# ドキュメント

このディレクトリには、Oracle Linux 8 開発用コンテナに関する追加ドキュメントが含まれています。

## 目次

### 将来計画

- [Oracle Linux 10 移行検討](./oracle-linux-10-migration.md)
  - 移行の難易度評価（Medium）
  - 互換性の問題点と対応策
  - 移行手順（4フェーズ）
  - リスク要因と対策

### コンテナイメージの管理

- [コンテナイメージのタグ戦略](./tagging-strategy.md)
  - タグ命名規則 (vYYYYMMDD.MINOR.PATCH)
  - latest タグの動作
  - バージョニング戦略
  - リリースフロー

### コンテナイメージの公開

- [GitHub Container Registry への公開ガイド](./publishing-to-github.md)
  - GitHub Container Registry (ghcr.io) へのイメージ公開方法
  - GitHub Actions による自動ビルド・公開
  - イメージの利用方法
  - トラブルシューティング

### VS Code Dev Container として利用

- [VS Code Dev Container として使用する](./using-in-vscode/) - 概要とセットアップ手順
  - クイックスタート
  - 詳細な設定とカスタマイズ
  - Docker と Podman の両方をサポート
  - トラブルシューティング

### CI/CD での利用

- [CI/CD でのコンテナイメージ利用ガイド](./using-in-cicd/) - 概要と目次
  - [基本的な使い方](./using-in-cicd/basics.md) - イメージの取得、コンテナの起動、基本的なワークフロー
  - 言語・フレームワーク別サンプル
    - [C/C++ プロジェクト](./using-in-cicd/cpp-example.md) - CMake、GoogleTest、Doxygen
    - [Node.js プロジェクト](./using-in-cicd/nodejs-example.md) - npm、Jest、ESLint
    - [Java プロジェクト](./using-in-cicd/java-example.md) - Maven、JUnit、JavaDoc
    - [Python プロジェクト](./using-in-cicd/python-example.md) - pytest、flake8、カバレッジ
    - [.NET プロジェクト](./using-in-cicd/dotnet-example.md) - dotnet CLI、xUnit
    - [ドキュメント生成](./using-in-cicd/documentation-example.md) - Doxygen、PlantUML、Pandoc
  - [高度な設定](./using-in-cicd/advanced-configuration.md) - キャッシュ、マトリクステスト、セキュリティスキャン
  - [トラブルシューティング](./using-in-cicd/troubleshooting.md) - よくある問題と解決方法
  - [ベストプラクティス](./using-in-cicd/best-practices.md) - 推奨される設定とパターン

## GitHub Actions ワークフロー

実際に使用できる GitHub Actions ワークフローファイルは、プロジェクトルートの `.github/workflows/` ディレクトリに配置されています。

- [`.github/workflows/build-and-publish.yml`](../.github/workflows/build-and-publish.yml)
  - コンテナイメージのビルドと公開を自動化

## 関連ドキュメント

- [README.md (プロジェクトルート)](../README.md) - プロジェクトの概要とクイックスタート
- [CLAUDE.md](../CLAUDE.md) - Claude Code を使用する際の詳細ガイド
- [LICENSE](../LICENSE) - プロジェクトスクリプトのライセンス (MIT)
- [src/LICENSE-IMAGE](../src/LICENSE-IMAGE) - コンテナイメージのライセンス (GPL-2.0)
- [src/NOTICE](../src/NOTICE) - 含まれるコンポーネントのライセンス情報
