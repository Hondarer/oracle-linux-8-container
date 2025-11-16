# Third-Party Component Licenses

このドキュメントは、Oracle Linux 8 Development Container で使用されているサードパーティコンポーネントとそのライセンス情報を記載しています。

## ベースイメージとOS

### Oracle Linux 8
- **バージョン**: 8
- **ライセンス**: GPLv2 and other open source licenses
- **URL**: https://www.oracle.com/linux/
- **説明**: コンテナイメージのベースOS

## プログラミング言語とランタイム

### Node.js
- **バージョン**: 22
- **ライセンス**: MIT License
- **URL**: https://nodejs.org/
- **説明**: JavaScript/TypeScript ランタイム環境

### OpenJDK (Java)
- **バージョン**: 17
- **ライセンス**: GPLv2 with Classpath Exception
- **URL**: https://openjdk.org/
- **説明**: Java 開発キットとランタイム

### .NET SDK
- **バージョン**: 9.0
- **ライセンス**: MIT License
- **URL**: https://dotnet.microsoft.com/
- **説明**: .NET 開発環境

### Python
- **バージョン**: 3.11
- **ライセンス**: PSF License (Python Software Foundation License)
- **URL**: https://www.python.org/
- **説明**: Python プログラミング言語

## Python パッケージ

### hjson
- **ライセンス**: MIT License
- **URL**: https://github.com/hjson/hjson-py
- **説明**: Human JSON パーサー

### gcovr
- **ライセンス**: BSD 3-Clause License
- **URL**: https://github.com/gcovr/gcovr
- **説明**: コードカバレッジレポートツール

## ドキュメント生成ツール

### Doxygen
- **バージョン**: 1.14.0
- **ライセンス**: GPLv2
- **URL**: https://www.doxygen.nl/
- **説明**: ソースコードドキュメント生成ツール

### doxybook2
- **バージョン**: 1.6.1 (Custom build for el8)
- **ライセンス**: MIT License
- **URL**: https://github.com/matusnovak/doxybook2
- **Custom build**: https://github.com/Hondarer/doxybook2.el8.x86_64
- **説明**: Doxygen XML を Markdown に変換するツール

### PlantUML
- **バージョン**: 1.2025.4
- **ライセンス**: GPLv3 or later
- **URL**: https://plantuml.com/
- **説明**: UML 図作成ツール

### Pandoc
- **バージョン**: 3.7.0.2
- **ライセンス**: GPLv2 or later
- **URL**: https://pandoc.org/
- **説明**: ドキュメント変換ツール

### pandoc-crossref
- **バージョン**: 0.3.20
- **ライセンス**: GPLv2
- **URL**: https://github.com/lierdakil/pandoc-crossref
- **説明**: Pandoc の相互参照フィルター

## テストフレームワーク

### GoogleTest
- **バージョン**: 1.17.0 (Prebuilt libraries)
- **ライセンス**: BSD 3-Clause License
- **URL**: https://github.com/google/googletest
- **Prebuilt**: https://github.com/Hondarer/googletest-lib
- **説明**: C++ 単体テストフレームワーク

## フォント

### VLGothic
- **ライセンス**: BSD License (mplus) + custom license
- **URL**: https://github.com/project-vc/vlgothic
- **説明**: 日本語 Gothic フォント

### Liberation Fonts
- **ライセンス**: SIL Open Font License 1.1
- **URL**: https://github.com/liberationfonts/liberation-fonts
- **説明**: メトリック互換フォント

### Cantarell
- **ライセンス**: SIL Open Font License 1.1
- **URL**: https://gitlab.gnome.org/GNOME/cantarell-fonts
- **説明**: GNOME デフォルトフォント

### DejaVu Fonts
- **ライセンス**: Free license (Bitstream Vera License + Public Domain)
- **URL**: https://dejavu-fonts.github.io/
- **説明**: Unicode カバレッジの高いフォント

### UDEV Gothic HSRF
- **バージョン**: 2.1.0
- **ライセンス**: SIL Open Font License 1.1
- **URL**: https://github.com/Hondarer/udev-gothic-rf
- **Original**: https://github.com/yuru7/udev-gothic
- **説明**: BIZ UDゴシックと JetBrains Mono を合成した開発者向けフォント

## ドキュメント

### man-pages (英語)
- **ライセンス**: GPLv2+ and various free licenses
- **URL**: https://www.kernel.org/doc/man-pages/
- **説明**: Linux マニュアルページ

### man-pages-ja (日本語マニュアルページ)
- **バージョン**: 20251115
- **ライセンス**: BSD License, GPLv2, and other free licenses
- **URL**: https://github.com/linux-jm/manual
- **説明**: Linux マニュアルページの日本語翻訳

## 開発ツールとユーティリティ

### GNU Development Tools
- **パッケージ**: gcc, make, automake, autoconf, libtool, binutils
- **ライセンス**: GPLv3 or later
- **URL**: https://www.gnu.org/
- **説明**: GNU コンパイラコレクションとビルドツール

### CMake
- **ライセンス**: BSD 3-Clause License
- **URL**: https://cmake.org/
- **説明**: クロスプラットフォームビルドシステム

### jq
- **ライセンス**: MIT License
- **URL**: https://jqlang.github.io/jq/
- **説明**: JSON 処理ツール

### tree
- **ライセンス**: GPLv2
- **URL**: http://mama.indstate.edu/users/ice/tree/
- **説明**: ディレクトリツリー表示ツール

### rsync
- **ライセンス**: GPLv3
- **URL**: https://rsync.samba.org/
- **説明**: ファイル同期ツール

### expect
- **ライセンス**: Public Domain
- **URL**: https://core.tcl-lang.org/expect/
- **説明**: 対話的プログラム自動化ツール

### lsof
- **ライセンス**: Custom license (permissive)
- **URL**: https://github.com/lsof-org/lsof
- **説明**: オープンファイル一覧表示ツール

### unzip
- **ライセンス**: Info-ZIP License (BSD-like)
- **URL**: http://www.info-zip.org/
- **説明**: ZIP アーカイブ展開ツール

## グラフィックスとデスクトップライブラリ

これらのライブラリは、PlantUML や Doxygen などのグラフィカルツールの依存関係として含まれています。

### GTK3
- **ライセンス**: LGPLv2+
- **URL**: https://www.gtk.org/
- **説明**: GIMP ツールキット

### Mesa (Vulkan drivers)
- **ライセンス**: MIT License and others
- **URL**: https://www.mesa3d.org/
- **説明**: オープンソース 3D グラフィックスライブラリ

### X11 Libraries
- **ライセンス**: MIT License
- **URL**: https://www.x.org/
- **説明**: X Window System ライブラリ

### Wayland
- **ライセンス**: MIT License
- **URL**: https://wayland.freedesktop.org/
- **説明**: 次世代ディスプレイサーバープロトコル

## ライセンスに関する注意事項

1. **このプロジェクト自体のライセンス**: MIT License (LICENSE ファイルを参照)
2. **コンテナイメージのライセンス**: このコンテナイメージには、GPLv2、GPLv3、MIT、BSD などの複数のライセンスを持つソフトウェアが含まれています
3. **GPL ライセンスの影響**: GPL ライセンスのソフトウェア（Oracle Linux、Doxygen、PlantUML など）は、そのソースコードの入手可能性と再配布時の条件に従う必要があります
4. **Oracle Linux の使用**: Oracle Linux の使用には、Oracle の配布条件が適用される場合があります

## ライセンス全文の入手方法

各コンポーネントのライセンス全文は、以下の方法で入手できます：

- **コンテナ内**: `/usr/share/licenses/` ディレクトリ
- **オンライン**: 各プロジェクトの URL を参照
- **パッケージマネージャー**: `rpm -qi <package-name>` でライセンス情報を確認

## 更新履歴

- 2025-11-15: 初版作成（実装に合わせてコンポーネントとライセンスを文書化）
