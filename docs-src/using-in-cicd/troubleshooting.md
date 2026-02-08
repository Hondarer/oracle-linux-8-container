# トラブルシューティング

このドキュメントでは、Oracle Linux 開発用コンテナイメージを CI/CD パイプラインで使用する際によくある問題と解決方法を説明します。

## ナビゲーション

- [CI/CD でのコンテナイメージ利用ガイド](../using-in-cicd.md) - メインガイド
- [高度な設定](./advanced-configuration.md) - 高度な設定オプション
- [ベストプラクティス](./best-practices.md) - 推奨される運用方法

---

## 目次

- [コンテナ起動時のエラー](#コンテナ起動時のエラー)
- [権限エラー](#権限エラー)
- [ビルドエラー](#ビルドエラー)
- [ネットワークエラー](#ネットワークエラー)
- [デバッグ方法](#デバッグ方法)

## コンテナ起動時のエラー

### 問題: entrypoint.sh でユーザー作成に失敗する

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

### 問題: SSH サービスが起動しない

```text
Error: sshd: no hostkeys available
```

**解決方法**: SSH ホストキーが正しく配置されていることを確認してください。コンテナイメージには事前に SSH ホストキーが含まれています。

## 権限エラー

### 問題: ファイルへの書き込み権限がない

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

### 問題: sudo が使えない

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

## ビルドエラー

### 問題: メモリ不足

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

### 問題: 依存パッケージがない

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

## ネットワークエラー

### 問題: イメージの pull に失敗する

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

## デバッグ方法

### コンテナ内の状態を確認

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

### entrypoint.sh のログを確認

```yaml
steps:
  - name: Check entrypoint logs
    run: |
      cat /var/log/entrypoint.log
```

---

## 関連ドキュメント

- [CI/CD でのコンテナイメージ利用ガイド](../using-in-cicd.md) - メインガイド
- [高度な設定](./advanced-configuration.md) - 高度な設定オプション
- [ベストプラクティス](./best-practices.md) - 推奨される運用方法
- [GitHub Container Registry への公開ガイド](../publishing-to-github.md) - イメージの公開方法

## サポート

問題が発生した場合は、以下のリソースを参照してください：

- [GitHub Issues](https://github.com/<user>/<repo>/issues) - バグ報告や機能リクエスト
- [GitHub Actions ドキュメント](https://docs.github.com/en/actions) - GitHub Actions の公式ドキュメント
- [Podman ドキュメント](https://docs.podman.io/) - Podman の公式ドキュメント
