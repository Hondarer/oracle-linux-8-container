# コンテナイメージのタグ戦略

このドキュメントでは、Oracle Linux 開発用コンテナイメージのタグ付け戦略とバージョン管理について説明します。

## 概要

このプロジェクトでは、以下の方針でコンテナイメージを管理します。

- **リリース版**: Git タグベースで管理し、`latest` タグを付与
- **開発版**: `main` ブランチベースで管理し、`main` タグを付与
- **バージョニング**: 日付ベースのセマンティックバージョニング (vYYYYMMDD.MINOR.PATCH)

## タグ命名規則

### 形式

```text
vYYYYMMDD.MINOR.PATCH
```

### 各要素の説明

| 要素 | 説明 | 例 |
|------|------|-----|
| `v` | バージョンプレフィックス (固定) | `v` |
| `YYYYMMDD` | リリース日 (年月日) | `20251116` |
| `MINOR` | マイナーバージョン | `0`, `1`, `2` |
| `PATCH` | パッチバージョン | `0`, `1`, `2` |

### タグ例

```text
v20251116.0.0  # 2025年11月16日の初回リリース
v20251116.0.1  # 同日のバグフィックス
v20251116.1.0  # 同日のマイナーアップデート
v20251117.0.0  # 2025年11月17日の初回リリース
```

## 生成されるイメージタグ

### リリース版 (Git タグ)

Git タグ `v20251116.0.0` を作成した場合、以下のイメージタグが自動生成されます。

```text
ghcr.io/<owner>/oracle-linux-8-dev:v20251116.0.0
ghcr.io/<owner>/oracle-linux-8-dev:20251116.0.0
ghcr.io/<owner>/oracle-linux-8-dev:20251116.0
ghcr.io/<owner>/oracle-linux-8-dev:20251116
ghcr.io/<owner>/oracle-linux-8-dev:sha-<短縮SHA>
ghcr.io/<owner>/oracle-linux-8-dev:latest
```

### 開発版 (main ブランチ)

`main` ブランチへの push では、以下のイメージタグが生成されます。

```text
ghcr.io/<owner>/oracle-linux-8-dev:main
ghcr.io/<owner>/oracle-linux-8-dev:sha-<短縮SHA>
```

**注意**: `main` ブランチへの push では `latest` タグは付与されません。

## latest タグの動作

### latest タグが付与される条件

- **Git タグが作成された場合のみ**
- 最新のタグに `latest` が付与される

### latest タグの移動

| シナリオ | latest タグの動作 |
|---------|-----------------|
| タグ `v20251116.0.0` を作成 | `latest` が `v20251116.0.0` を指す |
| タグ `v20251116.0.1` を作成 | `latest` が `v20251116.0.1` に移動 |
| タグ `v20251117.0.0` を作成 | `latest` が `v20251117.0.0` に移動 |
| `main` ブランチに push | `latest` は移動しない (維持される) |

## リリースフロー

### 1. GitHub Release でのリリース

1. GitHub の Releases ページで新しいリリースを作成
2. タグ名を入力 (例: `v20251116.0.0`)
3. リリースノートを記述
4. "Publish release" をクリック

これにより、GitHub Actions が自動的にトリガーされ、コンテナイメージがビルド・公開されます。

### 2. コマンドラインでのリリース

```bash
# タグを作成
git tag v20251116.0.0

# タグを push
git push origin v20251116.0.0
```

GitHub Actions が自動的にトリガーされます。

## バージョニング戦略

### 日付の更新 (YYYYMMDD)

以下の場合、日付部分を更新します。

- 新しい日にリリースを行う場合
- 前回のリリースから大きな変更がある場合

```bash
v20251116.0.0 → v20251117.0.0
```

### マイナーバージョンの更新 (MINOR)

以下の場合、マイナーバージョンを更新します。

- 新機能の追加
- 互換性のある変更
- 同日に複数回のリリースを行う場合

```bash
v20251116.0.0 → v20251116.1.0
```

### パッチバージョンの更新 (PATCH)

以下の場合、パッチバージョンを更新します。

- バグフィックス
- 軽微な修正
- ドキュメントの更新

```bash
v20251116.0.0 → v20251116.0.1
```

## イメージの利用

### latest タグの利用

```bash
podman pull ghcr.io/<owner>/oracle-linux-8-dev:latest
```

最新のリリース版を使用する場合に推奨します。

### 特定バージョンの利用

```bash
podman pull ghcr.io/<owner>/oracle-linux-8-dev:20251116.0.0
```

本番環境や再現性が必要な場合に推奨します。

### 日付ベースの利用

```bash
podman pull ghcr.io/<owner>/oracle-linux-8-dev:20251116
```

特定の日のリリースを使用する場合に便利です。

### 開発版の利用

```bash
podman pull ghcr.io/<owner>/oracle-linux-8-dev:main
```

最新の開発版を使用する場合に利用します。

## ベストプラクティス

### 1. 常に完全な形式でタグを指定

❌ 避けるべき形式:

```text
v20251116      # semver として認識されない
v20251116.0    # 不完全な形式
```

✅ 推奨される形式:

```text
v20251116.0.0  # 完全な semver 形式
```

### 2. 本番環境では特定バージョンを指定

CI/CD パイプラインや本番環境では、`latest` ではなく特定のバージョンを指定することを推奨します。

```yaml
# ✅ 推奨
image: ghcr.io/<owner>/oracle-linux-8-dev:20251116.0.0

# ❌ 非推奨 (本番環境)
image: ghcr.io/<owner>/oracle-linux-8-dev:latest
```

### 3. 開発環境では柔軟に選択

開発環境では、用途に応じてタグを選択します。

```yaml
# 最新のリリース版
image: ghcr.io/<owner>/oracle-linux-8-dev:latest

# 開発版
image: ghcr.io/<owner>/oracle-linux-8-dev:main
```

## トラブルシューティング

### Q: タグを作成したがワークフローがトリガーされない

A: タグ名が `v` で始まっているか確認してください。

```bash
# ✅ トリガーされる
git tag v20251116.0.0

# ❌ トリガーされない
git tag 20251116.0.0
```

### Q: latest タグが更新されない

A: 以下を確認してください。

1. Git タグを作成したか (ブランチ push では latest は更新されない)
2. より新しいタグが既に存在しないか

### Q: semver タグが生成されない

A: タグ形式が完全な `vYYYYMMDD.MINOR.PATCH` 形式になっているか確認してください。

## 関連ドキュメント

- [GitHub Container Registry への公開ガイド](./publishing-to-github.md)
- [CI/CD での利用ガイド](./using-in-cicd/)
- [プロジェクト README](../README.md)
