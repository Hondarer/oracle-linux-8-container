# Oracle Linux 開発用コンテナ

Oracle Linux ベースのポータブルな開発用コンテナシステムです。Podman を使用して、開発ツールや日本語環境が事前設定された開発環境を簡単に構築・利用できます。

Oracle Linux 8 および 10 のマルチバージョンに対応しています。

## 特徴

- **ポータブル設計**: ビルド時にユーザー情報に依存せず、どの環境でも利用可能
- **豊富な開発ツール**: Node.js、Java、.NET、Python、C/C++ 開発環境
- **ドキュメント生成**: Doxygen、PlantUML、Pandoc による文書作成支援
- **日本語対応**: 日本語ロケール、フォント、マニュアルページを完備
- **セキュア**: SSH キー認証、適切な権限管理
- **高速**: rootless Podman による軽量コンテナ

## インストール済みツール

### 言語ランタイム

| ツール | OL8 | OL10 |
|--------|-----|------|
| Node.js | 22 | 22 |
| Java (OpenJDK) | 17 | 21 |
| .NET SDK | 10 | 10 |
| Python | 3.11 | 3.12 |
| C/C++ (GCC) | 8 | 14 |

### ドキュメント生成

- **Doxygen** + doxybook2
- **PlantUML**
- **Pandoc** + pandoc-crossref

### テスト・ビルドツール

- **Make**、**CMake**、**automake**、**libtool**
- **pkg-config**、**cmake**

### ユーティリティ

- **jq**、**tree**、**rsync**
- **expect**、**nkf**
- **git**、**curl**、**wget**

## クイックスタート

### イメージビルド

```bash
# OL8 をビルド (デフォルト)
./build-pod.sh 8

# OL10 をビルド
./build-pod.sh 10
```

### コンテナ起動

```bash
# OL8 インスタンス1 を起動 (デフォルト)
./start-pod.sh 8

# OL10 インスタンス1 を起動
./start-pod.sh 10
```

### SSH 接続

```bash
# OL8 SSH 接続 (ポート 40822)
ssh -p 40822 user@127.0.0.1

# OL10 SSH 接続 (ポート 41022)
ssh -p 41022 user@127.0.0.1

# 初回接続時、SSH キーキャッシュのクリア
ssh-keygen -R "[127.0.0.1]:40822"
```

### コンテナ停止

```bash
# OL8 を停止
./stop-pod.sh 8

# OL10 を停止
./stop-pod.sh 10
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
# OL8 イメージを圧縮ファイルとして保存
./save-pod.sh 8

# OL10 イメージを保存
./save-pod.sh 10

# 保存したイメージを読み込み
./load-pod.sh 8
./load-pod.sh 10
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
├── version-config.sh     # バージョン別共通設定
├── storage/              # 永続化データ
│   ├── 8/1/             # OL8 インスタンス1
│   │   ├── home_${USER}/
│   │   └── workspace/
│   └── 10/1/            # OL10 インスタンス1
│       ├── home_${USER}/
│       └── workspace/
├── image/                # イメージ保存場所
├── CLAUDE.md             # Claude Code 用ガイド
└── README.md             # このファイル
```

## 技術仕様

- **ベースイメージ**: Oracle Linux 8 / 10
- **コンテナエンジン**: Podman (rootless mode)
- **アーキテクチャ**: x86_64
- **ポート**: 22 (SSH、ホスト側は 40822/41022 等)
- **マウント**: ホームディレクトリ、ワークスペース
- **UID/GID マッピング**: Podman keep-id
- **ストレージ**: `./storage/{version}/{instance}/`

## トラブルシューティング

### SSH 接続できない場合

```bash
# コンテナの状態確認
podman ps

# コンテナログの確認 (OL8 の場合)
podman logs oracle-linux-8_1

# SSH キーキャッシュのクリア (OL8 の場合)
ssh-keygen -R "[127.0.0.1]:40822"
```

### 権限エラーが発生する場合

```bash
# SELinux コンテキストの修正
sudo restorecon -R ./storage/

# ストレージディレクトリの再作成 (OL8 インスタンス1 の場合)
rm -rf ./storage/8/1/
mkdir -p ./storage/8/1/{home_$(whoami),workspace}
```

### ビルドエラーが発生する場合

```bash
# 古いイメージの削除 (OL8 の場合)
podman rmi oracle-linux-8

# キャッシュクリア後の再ビルド
podman system prune -f
./build-pod.sh 8
```

## Windows 環境で WSL2 にインポート

Windows 標準の PowerShell のみで、GitHub Container Registry から WSL2 用 rootfs をダウンロードし、WSL2 ディストリビューションとしてインポートできます。

### クイックスタート (Windows)

```powershell
# WSL2 のインストール (未インストールの場合)
wsl --install

# スクリプトをダウンロードして実行 (OL8)
irm https://raw.githubusercontent.com/hondarer/oracle-linux-container/main/examples/import-wsl/import-wsl.ps1 | iex

# OL10 の場合
.\import-wsl.ps1 -OLVersion 10

# インポートされたディストリビューションを起動
wsl -d OracleLinux8-Dev
```

詳細は [examples/import-wsl/README.md](examples/import-wsl/README.md) を参照してください。

## 関連ドキュメント

### プロジェクトドキュメント

- [docs-src/](docs-src/) - 追加ドキュメント
  - [GitHub Container Registry への公開ガイド](docs-src/publishing-to-github.md) - イメージの公開方法
  - [CI/CD でのコンテナイメージ利用ガイド](docs-src/using-in-cicd/) - 他のプロジェクトでの利用方法
    - 言語別サンプル: [C/C++](docs-src/using-in-cicd/cpp-example.md)、[Node.js](docs-src/using-in-cicd/nodejs-example.md)、[Java](docs-src/using-in-cicd/java-example.md)、[Python](docs-src/using-in-cicd/python-example.md)、[.NET](docs-src/using-in-cicd/dotnet-example.md)
- [CLAUDE.md](CLAUDE.md) - Claude Code を使用する際の詳細ガイド

### 外部リンク

- [Oracle Linux 8 公式ドキュメント](https://docs.oracle.com/en/operating-systems/oracle-linux/8/)
- [Oracle Linux 10 公式ドキュメント](https://docs.oracle.com/en/operating-systems/oracle-linux/10/)
- [Podman 公式ドキュメント](https://podman.io/docs)

## ライセンス

このプロジェクトは、デュアルライセンス構造を採用しています。

### プロジェクトスクリプトおよびドキュメント

- **ライセンス**: MIT License
- **適用範囲**: ビルドスクリプト (build-pod.sh、start-pod.sh など)、ドキュメント、設定ファイル
- **詳細**: [LICENSE](./LICENSE) を参照してください

### コンテナイメージ

- **ライセンス**: GNU General Public License v2.0 (GPL-2.0)
- **適用範囲**: ビルドされるコンテナイメージとその内容
- **詳細**: [src/LICENSE-IMAGE](./src/LICENSE-IMAGE) を参照してください
- **含まれるコンポーネント**: [src/NOTICE](./src/NOTICE) を参照してください

コンテナイメージは Oracle Linux (GPL-2.0) をベースとしており、多数のオープンソースコンポーネントを含んでいます。イメージを再配布する場合は、GPL-2.0 のライセンス条項に従う必要があります。

### 主要コンポーネントのライセンス

- **Oracle Linux 8/10**: GPL-2.0
- **OpenJDK 17/21**: GPL-2.0 with Classpath Exception
- **Node.js 22**: MIT License
- **.NET 10**: MIT License
- **Python 3.11/3.12**: PSF License
- **Doxygen**: GPL-2.0
- **PlantUML**: GPL-3.0+
- **Pandoc**: GPL-2.0+

詳細なコンポーネントリストとライセンス情報は以下を参照してください：
- [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md) - 包括的なライセンス情報（推奨）
- [src/NOTICE](./src/NOTICE) - コンテナイメージに含まれるサードパーティコンポーネント一覧
