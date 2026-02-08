# .NET プロジェクトのサンプル

このドキュメントでは、.NET プロジェクトで Oracle Linux 開発用コンテナイメージを使用する GitHub Actions ワークフローの例を示します。

## 完全なワークフロー例

```yaml
name: .NET Build and Test

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
        HOST_USER: dotnetdev
        HOST_UID: 1000
        HOST_GID: 1000
        DOTNET_CLI_TELEMETRY_OPTOUT: 1
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE: 1
        DOTNET_NOLOGO: true

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Display .NET version
        run: dotnet --version

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Run tests
        run: |
          dotnet test --configuration Release --no-build --verbosity normal \
            --collect:"XPlat Code Coverage" \
            --results-directory ./coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/**/coverage.cobertura.xml
          flags: unittests

      - name: Publish
        run: |
          dotnet publish --configuration Release --no-build \
            --output ./publish

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: published-app
          path: ./publish/
```

## ステップごとの説明

### 1. 環境変数の設定

.NET の動作を最適化するための環境変数：

```yaml
env:
  DOTNET_CLI_TELEMETRY_OPTOUT: 1        # テレメトリを無効化
  DOTNET_SKIP_FIRST_TIME_EXPERIENCE: 1  # 初回実行の Welcome メッセージをスキップ
  DOTNET_NOLOGO: true                   # ロゴ表示を無効化
  DOTNET_GENERATE_ASPNET_CERTIFICATE: false  # ASP.NET 証明書生成をスキップ
```

### 2. 依存関係の復元

```yaml
- name: Restore dependencies
  run: dotnet restore
```

NuGet パッケージのキャッシュ：

```yaml
- name: Cache NuGet packages
  uses: actions/cache@v3
  with:
    path: ~/.nuget/packages
    key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj') }}
    restore-keys: |
      ${{ runner.os }}-nuget-
```

### 3. ビルド

```yaml
- name: Build
  run: dotnet build --configuration Release --no-restore
```

ビルド設定：
- `--configuration Release`: リリースビルド
- `--configuration Debug`: デバッグビルド
- `--no-restore`: restore をスキップ（すでに実行済みの場合）

### 4. テストの実行

```yaml
- name: Run tests
  run: dotnet test --configuration Release --no-build --verbosity normal
```

詳細な出力：

```yaml
- name: Run tests with detailed output
  run: |
    dotnet test --configuration Release --no-build \
      --verbosity detailed \
      --logger "console;verbosity=detailed"
```

### 5. コードカバレッジ

```yaml
- name: Run tests with coverage
  run: |
    dotnet test --configuration Release --no-build \
      --collect:"XPlat Code Coverage" \
      --results-directory ./coverage

- name: Generate coverage report
  run: |
    dotnet tool install -g dotnet-reportgenerator-globaltool
    reportgenerator \
      -reports:./coverage/**/coverage.cobertura.xml \
      -targetdir:./coveragereport \
      -reporttypes:Html
```

### 6. アプリケーションの公開

```yaml
- name: Publish
  run: |
    dotnet publish --configuration Release --no-build \
      --output ./publish \
      --self-contained false
```

セルフコンテインド公開（.NET ランタイムを含む）：

```yaml
- name: Publish self-contained
  run: |
    dotnet publish --configuration Release \
      --output ./publish \
      --self-contained true \
      --runtime linux-x64
```

## ASP.NET Core アプリケーション

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Restore
    run: dotnet restore

  - name: Build
    run: dotnet build --configuration Release --no-restore

  - name: Test
    run: dotnet test --no-build --configuration Release

  - name: Publish
    run: |
      dotnet publish src/MyApp/MyApp.csproj \
        --configuration Release \
        --output ./publish

  - name: Test application startup
    run: |
      cd publish
      dotnet MyApp.dll &
      APP_PID=$!
      sleep 10
      curl -f http://localhost:5000/health || exit 1
      kill $APP_PID

  - name: Upload published app
    uses: actions/upload-artifact@v3
    with:
      name: webapp
      path: publish/
```

## ソリューションファイル (.sln) を使用する場合

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Restore solution
    run: dotnet restore MySolution.sln

  - name: Build solution
    run: dotnet build MySolution.sln --configuration Release --no-restore

  - name: Run all tests in solution
    run: dotnet test MySolution.sln --configuration Release --no-build
```

## NuGet パッケージの作成と公開

```yaml
jobs:
  build-and-pack:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Restore
        run: dotnet restore

      - name: Build
        run: dotnet build --configuration Release --no-restore

      - name: Pack
        run: dotnet pack --configuration Release --no-build --output ./nupkg

      - name: Push to NuGet
        if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
        run: |
          dotnet nuget push ./nupkg/*.nupkg \
            --api-key ${{ secrets.NUGET_API_KEY }} \
            --source https://api.nuget.org/v3/index.json
```

## Entity Framework Core マイグレーション

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Install EF Core tools
    run: dotnet tool install --global dotnet-ef

  - name: Restore
    run: dotnet restore

  - name: Apply migrations
    run: |
      dotnet ef database update --project src/MyApp/MyApp.csproj
    env:
      ConnectionStrings__DefaultConnection: ${{ secrets.DB_CONNECTION_STRING }}

  - name: Generate migration script
    run: |
      dotnet ef migrations script \
        --project src/MyApp/MyApp.csproj \
        --output migration.sql
```

## Docker イメージのビルド

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Build and publish
    run: |
      dotnet publish --configuration Release \
        --output ./publish \
        --self-contained false

  - name: Build Docker image
    run: |
      podman build -t myapp:latest .

  - name: Push to registry
    run: |
      echo ${{ secrets.GITHUB_TOKEN }} | podman login ghcr.io -u ${{ github.actor }} --password-stdin
      podman tag myapp:latest ghcr.io/${{ github.repository }}/myapp:latest
      podman push ghcr.io/${{ github.repository }}/myapp:latest
```

Dockerfile の例：

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY ./publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

## マルチターゲットフレームワーク

複数の .NET バージョンをターゲットにする場合：

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        framework: ['net6.0', 'net7.0', 'net8.0', 'net9.0']

    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Test for ${{ matrix.framework }}
        run: |
          dotnet test --framework ${{ matrix.framework }}
```

## 静的コード解析

### StyleCop Analyzers

```yaml
- name: Run code analysis
  run: dotnet build --configuration Release /p:TreatWarningsAsErrors=true
```

### SonarQube

```yaml
- name: Begin SonarQube analysis
  run: |
    dotnet tool install --global dotnet-sonarscanner
    dotnet sonarscanner begin \
      /k:"project-key" \
      /d:sonar.host.url="${{ secrets.SONAR_HOST_URL }}" \
      /d:sonar.login="${{ secrets.SONAR_TOKEN }}"

- name: Build
  run: dotnet build --configuration Release

- name: End SonarQube analysis
  run: dotnet sonarscanner end /d:sonar.login="${{ secrets.SONAR_TOKEN }}"
```

## Blazor WebAssembly アプリケーション

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Restore
    run: dotnet restore

  - name: Build
    run: dotnet build --configuration Release --no-restore

  - name: Publish Blazor WebAssembly
    run: |
      dotnet publish src/MyBlazorApp/MyBlazorApp.csproj \
        --configuration Release \
        --output ./publish

  - name: Upload static files
    uses: actions/upload-artifact@v3
    with:
      name: blazor-app
      path: ./publish/wwwroot/
```

## 関連ドキュメント

- [基本的な使い方](./basics.md) - コンテナの基本的な使用方法
- [高度な設定](./advanced-configuration.md) - キャッシュの詳細設定
- [トラブルシューティング](./troubleshooting.md) - よくある問題の解決方法
- [ベストプラクティス](./best-practices.md) - 推奨される設定
