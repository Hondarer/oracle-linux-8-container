# Oracle Linux 8 開発用コンテナ

Oracle Linux 8 ベースのポータブルな開発用コンテナシステムです。Podman を使用して、様々な開発ツールや日本語環境が事前設定された開発環境を簡単に構築・利用できます。

## 特徴

- **ポータブル設計**: ビルド時にユーザー情報に依存せず、どの環境でも利用可能
- **豊富な開発ツール**: Node.js、Java、.NET、Python、C/C++ 開発環境
- **ドキュメント生成**: Doxygen、PlantUML、Pandoc による文書作成支援
- **日本語対応**: 日本語ロケール、フォント、マニュアルページを完備
- **セキュア**: SSH キー認証、適切な権限管理
- **高速**: rootless Podman による軽量コンテナ

## インストール済みツール

### 言語ランタイム

- **Node.js 22** + npm (ユーザーローカル設定)
- **Java 17** (OpenJDK)
- **.NET 9.0** SDK
- **Python 3.11** + pip
- **C/C++** (GCC、開発ツール群)

### ドキュメント生成

- **Doxygen** + doxybook2
- **PlantUML**
- **Pandoc** + pandoc-crossref

### テスト・ビルドツール

- **GoogleTest** (システムワイド)
- **Make**、**automake**、**libtool**
- **pkg-config**、**cmake**

### ユーティリティ

- **jq**、**tree**、**rsync**
- **expect**、**nkf**
- **git**、**curl**、**wget**

## クイックスタート

### イメージビルド

```bash
./build-pod.sh
```

### コンテナ起動

```bash
./start-pod.sh
```

### SSH 接続

```bash
# SSH 接続 (ポート 40022)
ssh -p 40022 user@127.0.0.1

# 初回接続時、SSH キーキャッシュのクリア
ssh-keygen -R "[127.0.0.1]:40022"
```

### コンテナ停止

```bash
./stop-pod.sh
```

## 基本的な使い方

### SSH キー認証の設定

ホストに `~/.ssh/id_rsa.pub` が存在する場合、自動的に SSH キー認証が設定されます。

```bash
# SSH キーペア生成 (必要に応じて)
ssh-keygen -t rsa -b 4096
```

### 開発環境の確認

```bash
# コンテナ内で各ツールのバージョン確認
node --version
java --version
dotnet --version
python --version
gcc --version
```

### ドキュメント生成例

```bash
# PlantUML 図の生成
plantuml diagram.puml

# Doxygen ドキュメント生成
doxygen Doxyfile

# Pandoc による文書変換
pandoc README.md -o README.pdf
```

## 高度な使い方

### イメージの保存・読み込み

```bash
# イメージを圧縮ファイルとして保存
./save-pod.sh

# 保存したイメージを読み込み
./load-pod.sh
```

### 追加パッケージの事前配置

`src/packages/` にパッケージファイルを配置すると、キャッシュとして動作します。  
対象パッケージファイルは、`src/Dockerfile` を参照してください。

### カスタムフォントの追加

`src/fonts/` にフォントファイルを配置すると、システムフォントとして利用可能になります。

## ディレクトリ構成

```text
.
├── build-pod.sh          # イメージビルドスクリプト
├── start-pod.sh          # コンテナ起動スクリプト
├── stop-pod.sh           # コンテナ停止スクリプト
├── save-pod.sh           # イメージ保存スクリプト
├── load-pod.sh           # イメージ読み込みスクリプト
├── src/                  # ビルドファイル
│   ├── Dockerfile       # メインのビルド定義
│   ├── entrypoint.sh    # コンテナ起動スクリプト
│   ├── keys/            # SSH ホストキー (オプション)
│   ├── fonts/           # 追加フォント (オプション)
│   └── packages/        # 追加パッケージ (オプション)
├── storage/              # 永続化データ
│   └── 1/
│       ├── home_${USER}/ # ユーザーホーム
│       └── workspace/    # 作業ディレクトリ
├── image/                # イメージ保存場所
├── CLAUDE.md             # Claude Code 用ガイド
└── README.md             # このファイル
```

## 技術仕様

- **ベースイメージ**: Oracle Linux 8
- **コンテナエンジン**: Podman (rootless mode)
- **アーキテクチャ**: x86_64
- **ポート**: 22 (SSH)
- **マウント**: ホームディレクトリ、ワークスペース
- **UID/GID マッピング**: Podman keep-id

## トラブルシューティング

### SSH 接続できない場合

```bash
# コンテナの状態確認
podman ps

# コンテナログの確認
podman logs oracle-linux-8_1

# SSH キーキャッシュのクリア
ssh-keygen -R "[127.0.0.1]:40022"
```

### 権限エラーが発生する場合

```bash
# SELinux コンテキストの修正
sudo restorecon -R ./storage/

# ストレージディレクトリの再作成
rm -rf ./storage/1/
mkdir -p ./storage/1/{home_$(whoami),workspace}
```

### ビルドエラーが発生する場合

```bash
# 古いイメージの削除
podman rmi oracle-linux-8

# キャッシュクリア後の再ビルド
podman system prune -f
./build-pod.sh
```

## 関連ドキュメント

- [CLAUDE.md](CLAUDE.md) - Claude Code を使用する際の詳細ガイド
- [Oracle Linux 8 公式ドキュメント](https://docs.oracle.com/en/operating-systems/oracle-linux/8/)
- [Podman 公式ドキュメント](https://podman.io/docs)

## ライセンス

[LICENSE](./LICENSE) を参照してください。
