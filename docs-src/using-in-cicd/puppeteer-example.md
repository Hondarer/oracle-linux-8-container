# Puppeteer の使用

このコンテナには Puppeteer と Chromium がプリインストールされており、コンテナ起動後すぐにヘッドレスブラウザ自動化を利用できます。

## 概要

Puppeteer は Node.js 用のヘッドレス Chrome/Chromium 制御ライブラリです。このコンテナでは以下の最適化が行われています：

- **Chromium プリインストール**: ビルド時に Chromium をダウンロード済み
- **システムワイドキャッシュ**: `/opt/puppeteer-cache` に配置
- **環境変数設定済み**: `PUPPETEER_CACHE_DIR` が自動設定

## 使用方法

### プロジェクトへのインストール

```bash
# ローカルプロジェクトにインストール（Chromium の再ダウンロードなし）
npm install puppeteer
```

プリインストールされた Chromium キャッシュが自動的に使用されるため、追加のダウンロード時間は発生しません。

### 基本的な使用例

```javascript
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.goto('https://example.com');

  // スクリーンショット取得
  await page.screenshot({ path: 'screenshot.png' });

  // PDF 生成
  await page.pdf({ path: 'page.pdf', format: 'A4' });

  await browser.close();
})();
```

### CI/CD での使用例

#### GitHub Actions

```yaml
jobs:
  e2e-test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/hondarer/oracle-linux-8-container:latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
```

#### スクレイピング例

```javascript
const puppeteer = require('puppeteer');

async function scrapeData(url) {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle2' });

    const data = await page.evaluate(() => {
      return {
        title: document.title,
        content: document.body.innerText.substring(0, 1000)
      };
    });

    return data;
  } finally {
    await browser.close();
  }
}
```

## 環境変数

| 変数名 | 値 | 説明 |
|--------|-----|------|
| `PUPPETEER_CACHE_DIR` | `/opt/puppeteer-cache` | Chromium キャッシュディレクトリ |

## 注意事項

### コンテナ環境での起動オプション

コンテナ内で Puppeteer を使用する場合、以下のオプションが必要です：

```javascript
const browser = await puppeteer.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox']
});
```

### メモリ使用量

Chromium は比較的多くのメモリを使用します。CI/CD 環境では十分なメモリを割り当ててください（推奨: 2GB 以上）。

### 並行実行

複数のブラウザインスタンスを同時に起動する場合は、リソース制限に注意してください：

```javascript
// ブラウザインスタンスの再利用を推奨
const browser = await puppeteer.launch();

// 複数ページは同じブラウザで開く
const page1 = await browser.newPage();
const page2 = await browser.newPage();
```

## トラブルシューティング

### Chromium が起動しない

```bash
# 依存ライブラリの確認
ldd /opt/puppeteer-cache/chrome/*/chrome-linux64/chrome | grep "not found"
```

### タイムアウトエラー

ページ読み込みのタイムアウトを調整：

```javascript
await page.goto(url, {
  waitUntil: 'networkidle2',
  timeout: 60000  // 60秒
});
```

## 関連リンク

- [Puppeteer 公式ドキュメント](https://pptr.dev/)
- [Puppeteer GitHub](https://github.com/puppeteer/puppeteer)
