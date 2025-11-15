# ドキュメント

このディレクトリには、Oracle Linux 8 開発用コンテナに関する追加ドキュメントが含まれています。

## 目次

### コンテナイメージの公開

- [GitHub Container Registry への公開ガイド](./publishing-to-github.md)
  - GitHub Container Registry (ghcr.io) へのイメージ公開方法
  - GitHub Actions による自動ビルド・公開
  - イメージの利用方法
  - トラブルシューティング

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
