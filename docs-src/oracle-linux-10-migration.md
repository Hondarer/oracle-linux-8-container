# Oracle Linux 10 移行検討

このドキュメントは、Oracle Linux 8 から Oracle Linux 10 への移行に関する検討結果をまとめたものです。

## 総合難易度評価

**Medium（中程度）**

主な理由：
- モジュールシステムの廃止による Node.js インストール方法の変更
- .NET 10.0 SDK の可用性確認と潜在的なリポジトリ追加
- doxybook2 バイナリの互換性確認

## 現在の構成と変更点

### Dockerfile で使用している Oracle Linux 8 固有の設定

| 項目 | 現在の設定 (OL8) | OL10 での変更 |
|------|------------------|---------------|
| ベースイメージ | `oraclelinux:8` | `oraclelinux:10` |
| EPEL パッケージ | `oracle-epel-release-el8` | `oracle-epel-release-el10` |
| リポジトリ | `ol8_codeready_builder`, `ol8_developer_EPEL` | `ol10_codeready_builder`, `ol10_developer_EPEL` |
| Node.js | `dnf module -y enable nodejs:22` | モジュールシステム廃止、AppStream または NodeSource |
| Python | `python3.11-pip` | `python3-pip`（デフォルト 3.12） |
| .NET | `dotnet-sdk-10.0` | 可用性確認が必要 |
| Java | `java-17-openjdk` | 互換性あり |
| doxybook2 | `doxybook2.el8.x86_64-1.6.1.tar.gz` | OL10 向けリビルドまたは互換性確認が必要 |

### スクリプトでの変更点

| ファイル | 変更内容 |
|----------|----------|
| `build-pod.sh` | `CONTAINER_NAME=oracle-linux-8` → `oracle-linux-10` |
| `start-pod.sh` | `CONTAINER_NAME=oracle-linux-8` → `oracle-linux-10` |
| `stop-pod.sh` | `CONTAINER_NAME=oracle-linux-8` → `oracle-linux-10` |
| `save-pod.sh` | `CONTAINER_NAME=oracle-linux-8` → `oracle-linux-10` |
| `load-pod.sh` | `CONTAINER_NAME=oracle-linux-8` → `oracle-linux-10` |
| `devcontainer.json` | `oracle-linux-8-dev:latest` → `oracle-linux-10-dev:latest` |
| `.github/workflows/build-and-publish.yml` | イメージ名とアノテーションの更新 |

## 難易度別の項目分類

### Low（低）- 単純な置換・変更で対応可能

| 項目 | 内容 |
|------|------|
| ベースイメージ | `oraclelinux:8` → `oraclelinux:10` |
| リポジトリ名 | `ol8_*` → `ol10_*`、`el8` → `el10` |
| EPEL パッケージ | `oracle-epel-release-el8` → `oracle-epel-release-el10` |
| Java | OpenJDK 17 は互換性あり |
| Python | デフォルト版（3.12）使用で簡素化可能 |
| スクリプト類 | `CONTAINER_NAME` の文字列置換のみ |
| entrypoint.sh | 変更不要（POSIX 互換） |

### Medium（中）- 調査・対応が必要

| 項目 | 問題点 | 対応策 |
|------|--------|--------|
| **Node.js 22** | OL10 ではモジュールシステムが廃止 | NodeSource リポジトリ追加が必要な可能性 |
| **.NET 10.0** | OL10 標準リポジトリでの可用性未確認 | Microsoft リポジトリ追加の可能性 |
| **doxybook2** | `el8` 向けバイナリ | OL10 向けリビルドまたは互換性テストが必要 |
| **llvm-compat-libs** | OL10 での可用性未確認 | 個別確認が必要 |

## 互換性の詳細

### パッケージ管理とリポジトリ

| 項目 | OL8 | OL10 | 変更内容 |
|------|-----|------|----------|
| EPEL パッケージ | `oracle-epel-release-el8` | `oracle-epel-release-el10` | パッケージ名変更 |
| CodeReady Builder | `ol8_codeready_builder` | `ol10_codeready_builder` | リポジトリ名変更 |
| EPEL リポジトリ | `ol8_developer_EPEL` | `ol10_developer_EPEL` | リポジトリ名変更 |
| モジュールシステム | `dnf module enable` 必要 | **廃止** | 大きな変更 |

### 開発言語とランタイム

| 言語 | OL8 (現在) | OL10 | 問題点・対応策 |
|------|------------|------|----------------|
| **Node.js** | 22 (モジュール有効化) | AppStream 版 | モジュールシステム廃止。最新版には NodeSource リポジトリが必要な可能性 |
| **Python** | 3.11 | 3.12 (デフォルト) | デフォルト版が異なる。`python3-pip` に変更可能 |
| **Java** | 17 | 17/21 利用可能 | 互換性あり |
| **.NET** | 10.0 | 8.0/9.0 (公式リポジトリ) | .NET 10.0 は Microsoft リポジトリからの追加が必要な可能性 |

### サードパーティパッケージ

| パッケージ | 問題点 | 対応策 |
|------------|--------|--------|
| `doxybook2.el8.x86_64-1.6.1.tar.gz` | OL8 向けビルド | OL10 向けリビルドまたは互換性確認 |
| `pandoc-3.7.0.2-linux-amd64.tar.gz` | 汎用バイナリ | 互換性あり（要確認） |
| `googletest-lib-1.17.0.tar.gz` | 汎用ライブラリ | 互換性あり（要確認） |
| `plantuml-1.2025.4.jar` | Java アプリ | Java 17 互換性あり |

## 移行手順

### Phase 1: 準備作業（調査）

1. Oracle Linux 10 の Docker イメージで Node.js 22 の可用性を確認
2. .NET SDK 10.0 の OL10 リポジトリでの可用性を確認
3. doxybook2 バイナリの OL10 互換性をテスト
4. `llvm-compat-libs` 等のパッケージ可用性を確認

### Phase 2: Dockerfile の更新

1. `FROM oraclelinux:8` → `FROM oraclelinux:10`
2. メタデータラベルの更新
3. EPEL/リポジトリ設定の更新:
   ```dockerfile
   dnf install -y oracle-epel-release-el10 dnf-plugins-core
   dnf config-manager --enable ol10_codeready_builder ol10_developer_EPEL
   ```
4. Node.js インストールの変更:
   - `dnf module -y enable nodejs:22` を削除
   - NodeSource リポジトリ追加（必要な場合）
5. Python 設定の簡素化:
   - `python3.11-pip` → `python3-pip`
   - alternatives 設定を更新または削除
6. .NET SDK の対応:
   - Microsoft リポジトリ追加（必要な場合）
7. パッケージ名の互換性確認と修正
8. doxybook2 パッケージの対応（リビルドまたは代替手段）

### Phase 3: スクリプトとドキュメントの更新

1. シェルスクリプト内の `CONTAINER_NAME` を `oracle-linux-10` に変更
2. `devcontainer.json` のイメージ名を更新
3. GitHub Actions ワークフローの更新
4. `CLAUDE.md` と `README.md` の更新

### Phase 4: テストと検証

1. ローカルビルドテスト
2. 各開発ツールのバージョン確認
3. SSH 接続テスト
4. Dev Container での動作確認
5. CI/CD パイプラインでのビルドテスト

## 主な変更対象ファイル

実装に最も重要なファイル:

| ファイル | 変更内容 |
|----------|----------|
| `src/Dockerfile` | 最重要。ベースイメージ、パッケージ、リポジトリ設定のすべて |
| `build-pod.sh` | コンテナ名 (`CONTAINER_NAME`) の変更 |
| `.github/workflows/build-and-publish.yml` | CI/CD でのイメージ名とアノテーションの更新 |
| `examples/devcontainer/devcontainer.json` | Dev Container 用のイメージ参照の更新 |
| `start-pod.sh` | コンテナ名の変更とストレージパスの確認 |

## リスク要因

| リスク | 影響度 | 対策 |
|--------|--------|------|
| Node.js 22 がデフォルトリポジトリにない | 中 | NodeSource リポジトリ追加で対応 |
| .NET 10.0 が利用不可 | 中 | Microsoft 公式リポジトリ追加 |
| doxybook2 バイナリ非互換 | 低〜中 | ソースからリビルド or 代替ツール |
| パッケージ名変更 | 低 | 個別に確認・修正 |

## 参考情報

- [Oracle Linux 10 Package Repositories](https://yum.oracle.com/oracle-linux-10.html)
- [Oracle Linux 10 Release Notes](https://docs.oracle.com/en/operating-systems/oracle-linux/10/relnotes10.0/)
- [Node.js Packages for Oracle Linux](https://yum.oracle.com/oracle-linux-nodejs.html)
- [Oracle Linux 10 Application Streams](https://docs.oracle.com/en/operating-systems/oracle-linux/product-lifecycle/ol10_application_streams.html)
- [.NET 10 Download](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)

## 結論

- **工数見積り**: Dockerfile の調査・修正が中心。検証含めて中規模の作業
- **最大の障壁**: Node.js と .NET のインストール方法変更
- **低リスク部分**: 大半のスクリプトは単純な名称変更で済む

実装に進む場合は、まず Phase 1 の調査（OL10 での各パッケージ可用性確認）から始めることを推奨します。
