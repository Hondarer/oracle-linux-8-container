# Dev Container サンプル設定

このディレクトリには、公開されている Oracle Linux 8 コンテナイメージを使用して、あなたのプロジェクトで Dev Container を設定するためのサンプルが含まれています。

## クイックスタート

### 1. プロジェクトへのコピー

このディレクトリの内容をあなたのプロジェクトルートにコピーします：

```bash
# あなたのプロジェクトディレクトリで
cp -r /path/to/oracle-linux-8-container/examples/devcontainer .devcontainer
```

### 2. VS Code で開く

1. VS Code と [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) をインストール
2. Docker Desktop または Podman をインストール
3. プロジェクトを VS Code で開く
4. `Ctrl+Shift+P` (Mac: `Cmd+Shift+P`) → "Dev Containers: Reopen in Container"
5. イメージのダウンロードと起動を待つ

## 含まれる開発ツール

- **言語ランタイム**: Node.js 22, Java 17, .NET 9.0, Python 3.11
- **ビルドツール**: GCC, CMake, Make, automake
- **ドキュメント**: Doxygen, PlantUML, Pandoc
- **テスト**: GoogleTest, Jest, JUnit, pytest, xUnit
- **日本語環境**: 日本語ロケールとフォント

## ファイル構成

- `devcontainer.json` - Dev Container の設定ファイル
  - 公開イメージ (`ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest`) を使用
  - ホストのユーザー名とUID/GIDを自動マッピング
  - 推奨VS Code拡張機能の自動インストール
  - ホームディレクトリの永続化

## カスタマイズ

`devcontainer.json` を編集して、以下をカスタマイズできます：

- VS Code 拡張機能の追加・削除
- 環境変数の設定
- ポート転送の設定
- 追加パッケージのインストール

詳細なドキュメントは [docs-src/using-in-vscode/](../../docs-src/using-in-vscode/) を参照してください。
