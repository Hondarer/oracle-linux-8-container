# C/C++ プロジェクトのサンプル

このドキュメントでは、C/C++ プロジェクトで Oracle Linux 8 開発用コンテナイメージを使用する GitHub Actions ワークフローの例を示します。

## 完全なワークフロー例

```yaml
name: C++ Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest
      credentials:
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
      env:
        HOST_USER: builder
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Display tool versions
        run: |
          echo "=== Compiler versions ==="
          gcc --version
          g++ --version
          cmake --version
          make --version

      - name: Install additional dependencies
        run: |
          # 必要に応じて追加パッケージをインストール
          sudo dnf install -y boost-devel

      - name: Configure with CMake
        run: |
          mkdir -p build
          cd build
          cmake -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_CXX_FLAGS="-Wall -Wextra" \
                -DBUILD_TESTING=ON \
                ..

      - name: Build
        run: |
          cd build
          make -j$(nproc)

      - name: Run unit tests
        run: |
          cd build
          ctest --output-on-failure --verbose

      - name: Generate code coverage
        run: |
          cd build
          # gcovr でカバレッジレポートを生成
          gcovr --root .. \
                --filter '../src/' \
                --exclude '../src/test/' \
                --xml-pretty \
                --output coverage.xml \
                --html-details coverage.html

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./build/coverage.xml
          flags: unittests
          name: codecov-umbrella

      - name: Upload coverage HTML report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: build/coverage*.html

      - name: Generate Doxygen documentation
        run: |
          # Doxygen でドキュメントを生成
          doxygen Doxyfile

      - name: Upload documentation
        uses: actions/upload-artifact@v3
        with:
          name: documentation
          path: docs/html/

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-output
          path: |
            build/bin/
            build/lib/
```

## ステップごとの説明

### 1. 依存関係のインストール

プロジェクトで追加のライブラリが必要な場合は、インストールします。

```yaml
- name: Install additional dependencies
  run: |
    sudo dnf install -y \
      boost-devel \
      sqlite-devel \
      libcurl-devel
```

### 2. CMake による設定

CMake でビルドシステムを設定します。

```yaml
- name: Configure with CMake
  run: |
    mkdir -p build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_FLAGS="-Wall -Wextra -Werror" \
          -DBUILD_TESTING=ON \
          -DCMAKE_INSTALL_PREFIX=/usr/local \
          ..
```

#### よく使う CMake オプション

- `-DCMAKE_BUILD_TYPE=Release`: リリースビルド（最適化あり）
- `-DCMAKE_BUILD_TYPE=Debug`: デバッグビルド（デバッグ情報あり）
- `-DBUILD_TESTING=ON`: テストをビルド
- `-DCMAKE_CXX_FLAGS`: コンパイラフラグを追加

### 3. ビルド

並列ビルドで高速化します。

```yaml
- name: Build
  run: |
    cd build
    make -j$(nproc)
```

### 4. テストの実行

CTest でテストを実行します。

```yaml
- name: Run tests
  run: |
    cd build
    ctest --output-on-failure --verbose
```

#### CTest のオプション

- `--output-on-failure`: 失敗したテストの出力を表示
- `--verbose`: 詳細な出力
- `-j$(nproc)`: 並列実行
- `-R <pattern>`: パターンに一致するテストのみ実行

### 5. コードカバレッジの測定

gcovr を使用してカバレッジを測定します。

```yaml
- name: Configure with coverage
  run: |
    mkdir -p build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Debug \
          -DCMAKE_CXX_FLAGS="--coverage" \
          -DCMAKE_EXE_LINKER_FLAGS="--coverage" \
          ..

- name: Generate coverage report
  run: |
    cd build
    gcovr --root .. \
          --filter '../src/' \
          --exclude '../src/test/' \
          --xml coverage.xml \
          --html-details coverage.html
```

### 6. Doxygen ドキュメント生成

```yaml
- name: Generate Doxygen documentation
  run: doxygen Doxyfile
```

## Makefile を使用する場合

CMake ではなく Makefile を直接使用する場合の例です。

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: make all -j$(nproc)

      - name: Run tests
        run: make test

      - name: Install
        run: sudo make install

      - name: Create distribution
        run: make dist
```

## GoogleTest を使用する場合

このコンテナには GoogleTest がプリインストールされています。

### CMakeLists.txt の設定例

```cmake
cmake_minimum_required(VERSION 3.14)
project(MyProject)

# GoogleTest を検索
find_package(GTest REQUIRED)

# テストを追加
enable_testing()

add_executable(my_test test/my_test.cpp)
target_link_libraries(my_test GTest::gtest GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(my_test)
```

### ワークフローでのテスト実行

```yaml
- name: Run GoogleTest
  run: |
    cd build
    ctest --output-on-failure
```

## 静的解析の追加

コード品質を向上させるために静的解析を追加できます。

```yaml
- name: Run cppcheck
  run: |
    sudo dnf install -y cppcheck
    cppcheck --enable=all --error-exitcode=1 src/

- name: Run clang-tidy
  run: |
    sudo dnf install -y clang-tools-extra
    clang-tidy src/*.cpp -- -Iinclude/
```

## メモリリークチェック

Valgrind でメモリリークをチェックします。

```yaml
- name: Install Valgrind
  run: sudo dnf install -y valgrind

- name: Run Valgrind
  run: |
    cd build
    valgrind --leak-check=full \
             --show-leak-kinds=all \
             --track-origins=yes \
             --verbose \
             --error-exitcode=1 \
             ./bin/my_program
```

## マルチコンパイラテスト

複数のコンパイラでテストする場合は、マトリクスを使用します。

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        compiler: [gcc, clang]
        build_type: [Debug, Release]

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Clang
        if: matrix.compiler == 'clang'
        run: sudo dnf install -y clang

      - name: Configure
        run: |
          if [ "${{ matrix.compiler }}" == "clang" ]; then
            export CC=clang
            export CXX=clang++
          fi
          mkdir -p build
          cd build
          cmake -DCMAKE_BUILD_TYPE=${{ matrix.build_type }} ..

      - name: Build
        run: cd build && make -j$(nproc)

      - name: Test
        run: cd build && ctest --output-on-failure
```

## 関連ドキュメント

- [基本的な使い方](./basics.md) - コンテナの基本的な使用方法
- [高度な設定](./advanced-configuration.md) - キャッシュやマトリクステスト
- [ドキュメント生成](./documentation-example.md) - Doxygen の詳細設定
- [トラブルシューティング](./troubleshooting.md) - よくある問題の解決方法
