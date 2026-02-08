# Java プロジェクトのサンプル

このドキュメントでは、Java プロジェクト（Maven）で Oracle Linux 開発用コンテナイメージを使用する GitHub Actions ワークフローの例を示します。

## 完全なワークフロー例 (Maven)

```yaml
name: Java Maven Build

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
        HOST_USER: javadev
        HOST_UID: 1000
        HOST_GID: 1000
        JAVA_HOME: /usr/lib/jvm/java-17-openjdk
        MAVEN_OPTS: -Xmx1024m

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Display Java and Maven versions
        run: |
          java --version
          mvn --version

      - name: Install Maven
        run: sudo dnf install -y maven

      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2/repository
          key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
          restore-keys: |
            ${{ runner.os }}-maven-

      - name: Build with Maven
        run: mvn clean package -DskipTests

      - name: Run tests
        run: mvn test

      - name: Generate JavaDoc
        run: mvn javadoc:javadoc

      - name: Upload JAR
        uses: actions/upload-artifact@v3
        with:
          name: jar-package
          path: target/*.jar

      - name: Upload JavaDoc
        uses: actions/upload-artifact@v3
        with:
          name: javadoc
          path: target/site/apidocs/
```

## ステップごとの説明

### 1. Maven のインストール

```yaml
- name: Install Maven
  run: sudo dnf install -y maven
```

### 2. キャッシュの設定

Maven の依存関係をキャッシュして高速化します。

```yaml
- name: Cache Maven packages
  uses: actions/cache@v3
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
    restore-keys: |
      ${{ runner.os }}-maven-
```

### 3. ビルド

```yaml
- name: Build with Maven
  run: mvn clean package -DskipTests
```

よく使う Maven フェーズ：
- `clean`: ビルド成果物をクリーンアップ
- `compile`: ソースコードをコンパイル
- `test`: テストを実行
- `package`: JAR/WAR を作成
- `install`: ローカルリポジトリにインストール

### 4. テストの実行

```yaml
- name: Run tests
  run: mvn test
```

特定のテストクラスのみ実行：

```yaml
- name: Run specific tests
  run: mvn test -Dtest=MyTestClass
```

### 5. コードカバレッジ (JaCoCo)

```yaml
- name: Run tests with coverage
  run: mvn test jacoco:report

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./target/site/jacoco/jacoco.xml
```

`pom.xml` の設定例：

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.jacoco</groupId>
      <artifactId>jacoco-maven-plugin</artifactId>
      <version>0.8.10</version>
      <executions>
        <execution>
          <goals>
            <goal>prepare-agent</goal>
          </goals>
        </execution>
        <execution>
          <id>report</id>
          <phase>test</phase>
          <goals>
            <goal>report</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

## Gradle を使用する場合

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<user>/<repo>/oracle-linux-8-dev:latest

    steps:
      - uses: actions/checkout@v4

      - name: Install Gradle
        run: |
          sudo dnf install -y wget unzip
          wget https://services.gradle.org/distributions/gradle-8.5-bin.zip
          sudo unzip -d /opt/gradle gradle-8.5-bin.zip
          echo 'export PATH=$PATH:/opt/gradle/gradle-8.5/bin' | sudo tee /etc/profile.d/gradle.sh

      - name: Cache Gradle packages
        uses: actions/cache@v3
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}

      - name: Build with Gradle
        run: ./gradlew build

      - name: Run tests
        run: ./gradlew test

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-libs
          path: build/libs/*.jar
```

## Spring Boot アプリケーション

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Install Maven
    run: sudo dnf install -y maven

  - name: Build Spring Boot application
    run: mvn clean package -DskipTests

  - name: Run tests
    run: mvn test

  - name: Build Docker image
    run: |
      podman build -t myapp:latest .

  - name: Run application for smoke test
    run: |
      # アプリケーションをバックグラウンドで起動
      java -jar target/*.jar &
      APP_PID=$!

      # アプリケーションの起動を待つ
      sleep 30

      # ヘルスチェック
      curl -f http://localhost:8080/actuator/health || exit 1

      # アプリケーションを停止
      kill $APP_PID
```

## マルチモジュールプロジェクト

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Install Maven
    run: sudo dnf install -y maven

  - name: Build all modules
    run: mvn clean install

  - name: Run tests for specific module
    run: mvn test -pl module-name

  - name: Package all modules
    run: mvn package -DskipTests

  - name: Upload artifacts
    uses: actions/upload-artifact@v3
    with:
      name: all-modules
      path: |
        module1/target/*.jar
        module2/target/*.jar
```

## 静的解析 (SpotBugs, Checkstyle)

```yaml
- name: Run static analysis
  run: |
    mvn spotbugs:check
    mvn checkstyle:check
```

`pom.xml` の設定例：

```xml
<build>
  <plugins>
    <plugin>
      <groupId>com.github.spotbugs</groupId>
      <artifactId>spotbugs-maven-plugin</artifactId>
      <version>4.7.3.6</version>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.3.0</version>
    </plugin>
  </plugins>
</build>
```

## デプロイ

### Maven Central へのデプロイ

```yaml
- name: Deploy to Maven Central
  if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/')
  run: |
    mvn deploy -DskipTests
  env:
    MAVEN_USERNAME: ${{ secrets.MAVEN_USERNAME }}
    MAVEN_PASSWORD: ${{ secrets.MAVEN_PASSWORD }}
```

### GitHub Packages へのデプロイ

```yaml
- name: Deploy to GitHub Packages
  run: |
    mvn deploy -DaltDeploymentRepository=github::https://maven.pkg.github.com/${{ github.repository }}
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 関連ドキュメント

- [基本的な使い方](./basics.md) - コンテナの基本的な使用方法
- [高度な設定](./advanced-configuration.md) - キャッシュの詳細設定
- [トラブルシューティング](./troubleshooting.md) - よくある問題の解決方法
