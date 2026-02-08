# Oracle Linux コンテナ マルチバージョン対応計画

## Context

現在のリポジトリ `oracle-linux-8-container` は Oracle Linux 8 専用に構築されている。これを Oracle Linux 8 と 10 の両方に対応させ、将来のバージョン追加も容易にする。同時に、マルチインスタンス対応の既存設計（`./storage/1/`）を活かし、`./storage/{version}/{instance}` の階層構造に拡張する。

## リポジトリ名変更案

以下とします。

`oracle-linux-container`（バージョン番号を除去、シンプルで中立）

※GitHub 上での rename は別途手動で実施。コード内の参照は本計画で対応。

## 設計方針

| 項目 | 決定 |
|------|------|
| Dockerfile | 単一ファイル + `ARG OL_VERSION` で分岐 |
| シェルスクリプト | 第1引数でバージョン指定、共通設定を `version-config.sh` に集約 |
| ストレージ | `./storage/{version}/{instance}` 例: `./storage/8/1`, `./storage/10/1` |
| ポート | `408{VER}{INST}` 方式: OL8=#40822, OL10=#41022 (インスタンス1の場合) |
| ツールバージョン | 各ディストリビューションの標準に合わせる |
| コンテナ名 | `oracle-linux-{ver}_{instance}` 例: `oracle-linux-8_1` |

## ポート番号体系

```
OL8  インスタンス1: 40822  インスタンス2: 40823  インスタンス3: 40824 ...
OL10 インスタンス1: 41022  インスタンス2: 41023  インスタンス3: 41024 ...
```

計算式: `40000 + (OL_VERSION * 100) + (21 + INSTANCE_NUM)`

## 実装ステップ

### Step 1: `version-config.sh` の新規作成

**ファイル**: `/version-config.sh` (新規)

全スクリプトから `source` される共通設定ファイル。バージョンとインスタンス番号に基づいて変数を設定する。

```
引数: $1 = OL_VERSION (デフォルト: 8), $2 = INSTANCE_NUM (デフォルト: 1)

設定される変数:
- OL_VERSION
- INSTANCE_NUM
- CONTAINER_NAME  (例: oracle-linux-8)
- CONTAINER_INSTANCE (例: oracle-linux-8_1)
- SSH_HOST_PORT   (計算式に基づく)
- STORAGE_DIR     (例: ./storage/8/1)
- BASE_IMAGE      (例: oraclelinux:8)
```

既に `CONTAINER_NAME` 等が設定済みの場合（`build-pod.sh` から `stop-pod.sh` を source する場合）はスキップする。

### Step 2: `src/Dockerfile` の改修

**ファイル**: `/src/Dockerfile`

主な変更点:

1. **先頭に `ARG` 追加**:
   ```dockerfile
   ARG OL_VERSION=8
   FROM oraclelinux:${OL_VERSION}
   ARG OL_VERSION
   ```

2. **LABEL のパラメータ化**:
   - `oraclelinux:8` → `oraclelinux:${OL_VERSION}`

3. **パッケージインストールの条件分岐** (1つの `RUN` ブロック内):
   - OL8: `oracle-epel-release-el8`, `ol8_codeready_builder`, `ol8_developer_EPEL`, `dnf module -y enable nodejs:22`
   - OL10: `oracle-epel-release-el10`, `ol10_codeready_builder`, `ol10_developer_EPEL` (module不要)

4. **バージョン依存パッケージの条件分岐**:
   - Java: OL8=`java-17-openjdk*` / OL10=`java-21-openjdk*`
   - Python: OL8=`python3.11-pip` / OL10=`python3-pip` (3.12が標準)
   - `llvm-compat-libs`: OL8のみ（OL10では不要または名前変更の可能性）
   - `libmodman`, `libsoup`, `rest`: OL10での存在を要確認

5. **alternatives 設定の条件分岐**:
   - Java の alternatives: バージョン番号に応じたパターンマッチ
   - Python の alternatives: OL8=`python3.11`, OL10=標準python3

6. **doxybook2 の条件分岐**:
   - OL8: `doxybook2.el8.x86_64`
   - OL10: `doxybook2.el10.x86_64` (要事前ビルド。未準備の場合はスキップ)

7. **googletestの条件分岐**:
   - EL8/EL10 で共有ライブラリの互換性が異なる可能性。要検証。

### Step 3: シェルスクリプトの改修

全スクリプトで `CONTAINER_NAME=oracle-linux-8` の行を削除し、代わりに `version-config.sh` を source する。

#### `build-pod.sh`
- `source ./version-config.sh "${1:-8}" "${2:-1}"`
- `podman build --build-arg OL_VERSION=${OL_VERSION} -t ${CONTAINER_NAME} ./src/`
- `stop-pod.sh` の source はそのまま維持（変数が既に設定されているのでスキップされる）

#### `start-pod.sh`
- `source ./version-config.sh "${1:-8}" "${2:-1}"`
- ストレージパスを `${STORAGE_DIR}/home_${USER}` と `${STORAGE_DIR}/workspace` に変更
- ポートを `-p ${SSH_HOST_PORT}:22` に変更
- コンテナ名を `${CONTAINER_INSTANCE}` に変更

#### `stop-pod.sh`
- 先頭で `CONTAINER_INSTANCE` が未設定なら `version-config.sh` を source
- `podman stop/rm ${CONTAINER_INSTANCE}`

#### `save-pod.sh`
- `source ./version-config.sh "${1:-8}"`
- イメージ名を `${CONTAINER_NAME}` に

#### `load-pod.sh`
- `source ./version-config.sh "${1:-8}"`
- ファイル名を `image/${CONTAINER_NAME}.tar.gz` に

### Step 4: GitHub Actions ワークフロー改修

**ファイル**: `/.github/workflows/build-and-publish.yml`

- `strategy.matrix.ol_version: ["8", "10"]` を追加
- IMAGE_NAME を `oracle-linux-${{ matrix.ol_version }}-dev` に変更
- ビルドコマンドに `--build-arg OL_VERSION=${{ matrix.ol_version }}` を追加
- WSL rootfs のアノテーションをバージョンに応じて変更
- テスト項目はバージョンに依存しないコマンド（`java --version`, `python --version`）のため変更不要

### Step 5: devcontainer 設定の改修

**ファイル**: `/examples/devcontainer/devcontainer.json`

- OL8 と OL10 用の2つのバリアントを作成:
  - `/examples/devcontainer/ol8/devcontainer.json`
  - `/examples/devcontainer/ol10/devcontainer.json`
- 現在のファイルは OL8 用として `/examples/devcontainer/ol8/` に移動
- イメージ URL をバージョンに合わせて変更
- `/examples/devcontainer/README.md` でバージョン選択を案内

### Step 6: WSL インポートスクリプトの改修

**ファイル**: `/examples/import-wsl/import-wsl.ps1`

- `$OLVersion` パラメータを追加 (デフォルト: "8")
- `$WslDistroName` のデフォルトを `"OracleLinux${OLVersion}-Dev"` に変更
- `$ImageUrl` のデフォルトを `"ghcr.io/hondarer/oracle-linux-container/oracle-linux-${OLVersion}-dev:${Tag}"` に変更
- ヘッダー表示をバージョンに応じて変更

### Step 7: ドキュメント更新

以下のファイルのバージョン固有参照を更新:

- `/README.md`: タイトル変更、マルチバージョン対応の説明追加、コマンド例更新
- `/CLAUDE.md`: ベースイメージの記述更新、コマンド例更新
- `/docs-src/*.md`: イメージ名・バージョン参照の更新
- `/examples/devcontainer/README.md`: バージョン選択の案内追加
- `/examples/import-wsl/README.md`: バージョンパラメータの案内追加
- `/src/NOTICE`, `/THIRD_PARTY_LICENSES.md`: "Oracle Linux 8" → "Oracle Linux 8/10"

### Step 8: ストレージ移行ガイダンス

既存ユーザー向けに `start-pod.sh` で移行メッセージを表示:

```bash
if [ "${OL_VERSION}" = "8" ] && [ -d "./storage/1" ] && [ ! -d "./storage/8" ]; then
    echo "Note: Storage structure has changed."
    echo "Please move: mv ./storage/1 ./storage/8/1"
fi
```

README にも移行手順を記載。

## OL8 と OL10 のパッケージ差分まとめ

| パッケージ | OL8 | OL10 | 対応 |
|-----------|-----|------|------|
| EPEL | `oracle-epel-release-el8` | `oracle-epel-release-el10` | 条件分岐 |
| リポジトリ | `ol8_codeready_builder`, `ol8_developer_EPEL` | `ol10_codeready_builder`, `ol10_developer_EPEL` | 条件分岐 |
| Node.js | `dnf module enable nodejs:22` + install | `dnf install nodejs` (AppStream) | 条件分岐 |
| Java | `java-17-openjdk*` | `java-21-openjdk*` | 条件分岐 |
| Python pip | `python3.11-pip` | `python3-pip` | 条件分岐 |
| llvm-compat-libs | あり | 要確認（`llvm-libs`?） | 条件分岐 |
| libmodman | あり | 要確認 | 条件分岐 |
| libsoup | あり | `libsoup3`? | 要確認 |
| rest | あり | 要確認 | 条件分岐 |
| doxybook2 | `el8` ビルド | `el10` ビルドが必要 | 要事前準備 |
| .NET SDK | `dotnet-sdk-10.0` | `dotnet-sdk-10.0`（同じ見込み） | 共通 |

## 実施順序

1. `version-config.sh` 作成
2. `src/Dockerfile` 改修
3. シェルスクリプト5本改修 (`build-pod.sh`, `start-pod.sh`, `stop-pod.sh`, `save-pod.sh`, `load-pod.sh`)
4. **OL8 でビルドテスト**（回帰なし確認）
5. **OL10 でビルドテスト**（パッケージ互換性確認・調整）
6. GitHub Actions ワークフロー改修
7. devcontainer 設定改修
8. WSL インポートスクリプト改修
9. ドキュメント更新

## 検証方法

1. `./build-pod.sh 8` → OL8 イメージビルド成功確認
2. `./build-pod.sh 10` → OL10 イメージビルド成功確認
3. `./start-pod.sh 8` → OL8 コンテナ起動、SSH 接続確認 (ポート 40822)
4. `./start-pod.sh 10` → OL10 コンテナ起動、SSH 接続確認 (ポート 41022)
5. 両コンテナの同時起動確認
6. `./save-pod.sh 8` / `./save-pod.sh 10` → イメージ保存確認
7. `./load-pod.sh 8` / `./load-pod.sh 10` → イメージ読み込み確認
8. ストレージが `./storage/8/1/` と `./storage/10/1/` に分離されていること確認

## 前提・リスク

- **doxybook2 の OL10 ビルド**: 事前に `doxybook2.el10.x86_64` の作成が必要。未準備の場合は OL10 ビルドで doxybook2 をスキップする条件分岐を入れる
- **googletest の OL10 互換性**: プリコンパイル済みライブラリが OL10 で動くか要検証
- **OL10 パッケージ名変更**: 一部パッケージ（`libsoup`, `rest`, `libmodman`, `llvm-compat-libs`）が OL10 で名前変更・廃止されている可能性あり。ビルド時に確認し、条件分岐で対応
- **既存環境への影響**: ストレージパス変更 (`./storage/1/` → `./storage/8/1/`) およびポート変更 (`40022` → `40822`) は breaking change。移行ガイダンスを提供
