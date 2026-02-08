# Python プロジェクトのサンプル

このドキュメントでは、Python プロジェクトで Oracle Linux 開発用コンテナイメージを使用する GitHub Actions ワークフローの例を示します。

## 完全なワークフロー例

```yaml
name: Python Build and Test

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
        HOST_USER: pythondev
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Display Python version
        run: |
          python --version
          pip --version

      - name: Cache pip packages
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Create virtual environment
        run: |
          python -m venv venv
          source venv/bin/activate
          pip install --upgrade pip

      - name: Install dependencies
        run: |
          source venv/bin/activate
          pip install -r requirements.txt
          pip install pytest pytest-cov flake8 black mypy

      - name: Format check with black
        run: |
          source venv/bin/activate
          black --check src/ tests/

      - name: Lint with flake8
        run: |
          source venv/bin/activate
          flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 src/ tests/ --count --max-complexity=10 --max-line-length=127 --statistics

      - name: Type check with mypy
        run: |
          source venv/bin/activate
          mypy src/

      - name: Run tests with coverage
        run: |
          source venv/bin/activate
          pytest --cov=src --cov-report=xml --cov-report=html --cov-report=term

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml
          flags: unittests

      - name: Upload coverage HTML report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: htmlcov/
```

## ステップごとの説明

### 1. 仮想環境の作成

Python の依存関係を分離するために仮想環境を使用します。

```yaml
- name: Create virtual environment
  run: |
    python -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
```

### 2. 依存関係のインストール

```yaml
- name: Install dependencies
  run: |
    source venv/bin/activate
    pip install -r requirements.txt
```

開発用の依存関係を含む場合：

```yaml
- name: Install dependencies
  run: |
    source venv/bin/activate
    pip install -r requirements.txt
    pip install -r requirements-dev.txt
```

### 3. コードフォーマットチェック (Black)

```yaml
- name: Format check with black
  run: |
    source venv/bin/activate
    black --check src/ tests/
```

自動修正する場合：

```yaml
- name: Format code with black
  run: |
    source venv/bin/activate
    black src/ tests/
```

### 4. リンター (flake8)

```yaml
- name: Lint with flake8
  run: |
    source venv/bin/activate
    # エラーを表示して停止
    flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
    # 警告を表示（停止しない）
    flake8 src/ tests/ --count --max-complexity=10 --max-line-length=127 --statistics
```

`.flake8` 設定ファイルの例：

```ini
[flake8]
max-line-length = 127
extend-ignore = E203, W503
exclude =
    .git,
    __pycache__,
    venv,
    .venv,
    build,
    dist
```

### 5. 型チェック (mypy)

```yaml
- name: Type check with mypy
  run: |
    source venv/bin/activate
    mypy src/ --strict
```

`mypy.ini` 設定ファイルの例：

```ini
[mypy]
python_version = 3.11
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True
```

### 6. テストの実行 (pytest)

```yaml
- name: Run tests
  run: |
    source venv/bin/activate
    pytest -v
```

カバレッジ付きで実行：

```yaml
- name: Run tests with coverage
  run: |
    source venv/bin/activate
    pytest --cov=src --cov-report=xml --cov-report=html --cov-report=term
```

`pytest.ini` 設定ファイルの例：

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --strict-markers
    --tb=short
```

## 複数の Python バージョンでテスト

このコンテナには Python 3.11 がインストール済みですが、複数バージョンでテストする場合：

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11', '3.12']

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        run: pytest
```

## Poetry を使用する場合

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Install Poetry
    run: |
      curl -sSL https://install.python-poetry.org | python -
      echo "$HOME/.local/bin" >> $GITHUB_PATH

  - name: Cache Poetry packages
    uses: actions/cache@v3
    with:
      path: ~/.cache/pypoetry
      key: ${{ runner.os }}-poetry-${{ hashFiles('**/poetry.lock') }}

  - name: Install dependencies
    run: poetry install

  - name: Run tests
    run: poetry run pytest --cov=src

  - name: Build package
    run: poetry build
```

## Django プロジェクト

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Create virtual environment
    run: python -m venv venv

  - name: Install dependencies
    run: |
      source venv/bin/activate
      pip install -r requirements.txt

  - name: Run migrations
    run: |
      source venv/bin/activate
      python manage.py migrate

  - name: Run tests
    run: |
      source venv/bin/activate
      python manage.py test

  - name: Collect static files
    run: |
      source venv/bin/activate
      python manage.py collectstatic --noinput
```

## Flask アプリケーション

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Setup environment
    run: |
      python -m venv venv
      source venv/bin/activate
      pip install -r requirements.txt

  - name: Run tests
    run: |
      source venv/bin/activate
      export FLASK_APP=app.py
      export FLASK_ENV=testing
      pytest

  - name: Run application
    run: |
      source venv/bin/activate
      flask run &
      sleep 5
      curl -f http://localhost:5000/health || exit 1
```

## セキュリティチェック

### Safety で脆弱性チェック

```yaml
- name: Check for security vulnerabilities
  run: |
    source venv/bin/activate
    pip install safety
    safety check
```

### Bandit で静的解析

```yaml
- name: Run Bandit security linter
  run: |
    source venv/bin/activate
    pip install bandit
    bandit -r src/
```

## パッケージのビルドと公開

### PyPI への公開

```yaml
jobs:
  publish:
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Install build tools
        run: |
          python -m venv venv
          source venv/bin/activate
          pip install build twine

      - name: Build package
        run: |
          source venv/bin/activate
          python -m build

      - name: Publish to PyPI
        run: |
          source venv/bin/activate
          twine upload dist/*
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
```

## Jupyter Notebook のテスト

```yaml
- name: Install nbconvert
  run: |
    source venv/bin/activate
    pip install nbconvert jupyter

- name: Execute notebooks
  run: |
    source venv/bin/activate
    jupyter nbconvert --to notebook --execute notebooks/*.ipynb
```

## 関連ドキュメント

- [基本的な使い方](./basics.md) - コンテナの基本的な使用方法
- [高度な設定](./advanced-configuration.md) - キャッシュの詳細設定
- [トラブルシューティング](./troubleshooting.md) - よくある問題の解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される設定
