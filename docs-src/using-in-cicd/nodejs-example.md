# Node.js プロジェクトのサンプル

このドキュメントでは、Node.js プロジェクトで Oracle Linux 8 開発用コンテナイメージを使用する GitHub Actions ワークフローの例を示します。

## 完全なワークフロー例

```yaml
name: Node.js Build and Test

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
        HOST_USER: nodedev
        HOST_UID: 1000
        HOST_GID: 1000

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Display Node.js and npm versions
        run: |
          node --version
          npm --version

      - name: Cache Node.js modules
        uses: actions/cache@v3
        with:
          path: |
            ~/.node_modules
            node_modules
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - name: Install dependencies
        run: npm ci

      - name: Lint code
        run: npm run lint

      - name: Build
        run: npm run build

      - name: Run tests with coverage
        run: npm test -- --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

      - name: Build distribution package
        run: npm run dist

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/
```

## ステップごとの説明

### 1. キャッシュの設定

依存関係のインストール時間を短縮するためにキャッシュを活用します。

```yaml
- name: Cache Node.js modules
  uses: actions/cache@v3
  with:
    path: |
      ~/.node_modules
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

**注意**: このコンテナでは npm のプレフィックスが `~/.node_modules` に設定されています。

### 2. 依存関係のインストール

`npm ci` を使用してクリーンインストールします。

```yaml
- name: Install dependencies
  run: npm ci
```

`npm install` との違い：
- `npm ci` は package-lock.json に厳密に従う
- より高速で再現性が高い
- CI/CD 環境に推奨

### 3. コード品質チェック

ESLint でコードをチェックします。

```yaml
- name: Lint code
  run: npm run lint
```

`package.json` の設定例：

```json
{
  "scripts": {
    "lint": "eslint src/ tests/ --ext .js,.jsx,.ts,.tsx"
  },
  "devDependencies": {
    "eslint": "^8.0.0"
  }
}
```

### 4. TypeScript のビルド

TypeScript プロジェクトの場合のビルド設定です。

```yaml
- name: Build TypeScript
  run: npm run build
```

`package.json` の設定例：

```json
{
  "scripts": {
    "build": "tsc",
    "build:watch": "tsc --watch"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

### 5. テストの実行

Jest を使用したテストの例です。

```yaml
- name: Run tests with coverage
  run: npm test -- --coverage --ci
```

`package.json` の設定例：

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

`jest.config.js` の設定例：

```javascript
module.exports = {
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.test.{js,jsx,ts,tsx}',
    '!src/**/*.spec.{js,jsx,ts,tsx}'
  ],
  testMatch: [
    '**/__tests__/**/*.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)'
  ]
};
```

## Mocha/Chai を使用する場合

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci

  - name: Run tests
    run: npm test

  - name: Generate coverage report
    run: npm run coverage
```

`package.json` の設定例：

```json
{
  "scripts": {
    "test": "mocha 'test/**/*.test.js'",
    "coverage": "nyc npm test"
  },
  "devDependencies": {
    "mocha": "^10.0.0",
    "chai": "^4.3.0",
    "nyc": "^15.1.0"
  }
}
```

## 複数の Node.js バージョンでテスト

複数のバージョンでテストする場合（このコンテナには Node.js 22 がインストール済み）：

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18, 20, 22]

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - run: npm ci
      - run: npm test
```

**注意**: このコンテナイメージを使用する場合は Node.js 22 が固定されるため、複数バージョンのテストには `setup-node` アクションを使用するか、別のコンテナイメージを使用してください。

## パッケージの公開

npm パッケージを公開する例です。

```yaml
jobs:
  publish:
    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build

      - name: Publish to npm
        run: |
          echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
          npm publish
        env:
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## フロントエンドプロジェクト (React/Vue/Angular)

### React プロジェクト

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci

  - name: Build React app
    run: npm run build
    env:
      CI: true
      REACT_APP_API_URL: https://api.example.com

  - name: Run tests
    run: npm test -- --watchAll=false

  - name: Upload build
    uses: actions/upload-artifact@v3
    with:
      name: react-build
      path: build/
```

### Vue.js プロジェクト

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci

  - name: Build Vue app
    run: npm run build

  - name: Run unit tests
    run: npm run test:unit

  - name: Upload dist
    uses: actions/upload-artifact@v3
    with:
      name: vue-dist
      path: dist/
```

## E2E テスト (Playwright/Cypress)

### Playwright の例

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci

  - name: Install Playwright browsers
    run: npx playwright install --with-deps

  - name: Run Playwright tests
    run: npm run test:e2e

  - name: Upload test results
    if: always()
    uses: actions/upload-artifact@v3
    with:
      name: playwright-report
      path: playwright-report/
```

### Cypress の例

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci

  - name: Run Cypress tests
    run: npm run cypress:run

  - name: Upload screenshots
    if: failure()
    uses: actions/upload-artifact@v3
    with:
      name: cypress-screenshots
      path: cypress/screenshots/

  - name: Upload videos
    if: always()
    uses: actions/upload-artifact@v3
    with:
      name: cypress-videos
      path: cypress/videos/
```

## セキュリティ監査

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Run security audit
    run: npm audit --audit-level=moderate

  - name: Check for outdated packages
    run: npm outdated || true
```

## Docker イメージのビルド

Node.js アプリケーションを Docker イメージとしてビルドする場合：

```yaml
steps:
  - uses: actions/checkout@v4
  - run: npm ci
  - run: npm run build

  - name: Build Docker image
    run: |
      podman build -t myapp:latest .

  - name: Push to registry
    run: |
      echo ${{ secrets.GITHUB_TOKEN }} | podman login ghcr.io -u ${{ github.actor }} --password-stdin
      podman tag myapp:latest ghcr.io/${{ github.repository }}/myapp:latest
      podman push ghcr.io/${{ github.repository }}/myapp:latest
```

## 関連ドキュメント

- [基本的な使い方](./basics.md) - コンテナの基本的な使用方法
- [高度な設定](./advanced-configuration.md) - キャッシュの詳細設定
- [トラブルシューティング](./troubleshooting.md) - よくある問題の解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される設定
