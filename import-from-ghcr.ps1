# Oracle Linux 8 コンテナイメージを ghcr.io からダウンロードし、WSL2 にインポートする PowerShell スクリプト
#
# このスクリプトは外部ツール（Podman等）を使用せず、素のPowerShellのみで動作します
#
# 前提条件:
# - Windows 10 (1803以降) または Windows 11
# - WSL2 がインストール済み
# - インターネット接続
#
# 使用するWindows標準機能:
# - PowerShell (Invoke-RestMethod, Invoke-WebRequest)
# - tar.exe (Windows 10 1803以降に標準搭載)
# - wsl.exe (WSL2 管理コマンド)

param(
    [string]$ImageUrl = "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
    [string]$WslDistroName = "OracleLinux8-Dev",
    [string]$InstallLocation = "$env:LOCALAPPDATA\WSL\$WslDistroName",
    [string]$TempDir = "$env:TEMP\wsl-import-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Invoke-WebRequestの進捗表示を無効化して高速化

# =============================================================================
# カラー出力関数
# =============================================================================

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "`n==> $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[OK] $Message" "Green"
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

# =============================================================================
# イメージURL解析
# =============================================================================

function Parse-ImageUrl {
    param([string]$Url)

    # ghcr.io/owner/repo/image:tag 形式を解析
    if ($Url -match '^(?:([^/]+)/)?(.+?):(.+)$') {
        $registry = if ($matches[1]) { $matches[1] } else { "ghcr.io" }
        $image = $matches[2]
        $tag = $matches[3]
    } elseif ($Url -match '^(?:([^/]+)/)?(.+)$') {
        $registry = if ($matches[1]) { $matches[1] } else { "ghcr.io" }
        $image = $matches[2]
        $tag = "latest"
    } else {
        throw "無効なイメージURL形式: $Url"
    }

    return @{
        Registry = $registry
        Image = $image
        Tag = $tag
        Full = "$registry/$image`:$tag"
    }
}

# =============================================================================
# OCI Registry API v2 認証とマニフェスト取得
# =============================================================================

function Get-RegistryToken {
    param(
        [string]$Registry,
        [string]$Image
    )

    Write-Info "認証トークンを取得中..."

    try {
        $tokenUrl = "https://$Registry/token?service=$Registry&scope=repository:$Image`:pull"
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Get -ContentType "application/json"

        if ($response.token) {
            Write-Success "認証トークンを取得しました"
            return $response.token
        } else {
            throw "トークンの取得に失敗しました"
        }
    } catch {
        Write-ErrorMsg "認証エラー: $_"
        throw
    }
}

function Get-ImageManifest {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Tag,
        [string]$Token
    )

    Write-Info "イメージマニフェストを取得中..."

    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.index.v1+json"
    }

    $manifestUrl = "https://$Registry/v2/$Image/manifests/$Tag"

    try {
        $response = Invoke-WebRequest -Uri $manifestUrl -Method Get -Headers $headers
        $manifest = $response.Content | ConvertFrom-Json
        $contentType = $response.Headers.'Content-Type'[0]

        Write-Success "マニフェストを取得しました (タイプ: $contentType)"

        return @{
            Manifest = $manifest
            ContentType = $contentType
        }
    } catch {
        Write-ErrorMsg "マニフェスト取得エラー: $_"
        throw
    }
}

function Get-PlatformManifest {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Token,
        [object]$ManifestList
    )

    Write-Info "linux/amd64 プラットフォームのマニフェストを検索中..."

    # linux/amd64 を探す
    $platformManifest = $ManifestList.manifests | Where-Object {
        $_.platform.architecture -eq "amd64" -and $_.platform.os -eq "linux"
    } | Select-Object -First 1

    if (-not $platformManifest) {
        throw "linux/amd64 プラットフォームのマニフェストが見つかりません"
    }

    Write-Info "linux/amd64 マニフェストを発見: $($platformManifest.digest)"

    # 実際のイメージマニフェストを取得
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json"
    }

    $digestUrl = "https://$Registry/v2/$Image/manifests/$($platformManifest.digest)"
    $response = Invoke-WebRequest -Uri $digestUrl -Method Get -Headers $headers
    $manifest = $response.Content | ConvertFrom-Json

    Write-Success "プラットフォーム固有のマニフェストを取得しました"

    return $manifest
}

function Download-Blob {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Token,
        [string]$Digest,
        [string]$OutputPath,
        [int]$Index,
        [int]$Total
    )

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $blobUrl = "https://$Registry/v2/$Image/blobs/$Digest"
    $shortDigest = $Digest.Substring(0, 16)

    Write-Info "[$Index/$Total] レイヤーをダウンロード中: $shortDigest..."

    try {
        Invoke-WebRequest -Uri $blobUrl -Method Get -Headers $headers -OutFile $OutputPath
        $size = (Get-Item $OutputPath).Length / 1MB
        Write-Success "[$Index/$Total] ダウンロード完了: $shortDigest ($($size.ToString('F2')) MB)"
    } catch {
        Write-ErrorMsg "[$Index/$Total] ダウンロード失敗: $shortDigest - $_"
        throw
    }
}

# =============================================================================
# rootfs 構築
# =============================================================================

function Build-RootFs {
    param(
        [string]$TempDir,
        [array]$Layers
    )

    Write-Step "rootfs を構築中"

    $rootfsDir = Join-Path $TempDir "rootfs"
    New-Item -ItemType Directory -Path $rootfsDir -Force | Out-Null

    Write-Info "レイヤーを順番に展開します..."

    $layerIndex = 1
    foreach ($layer in $Layers) {
        $layerFile = Join-Path $TempDir "layers" "$($layer.digest -replace ':', '-').tar.gz"
        $shortDigest = $layer.digest.Substring(0, 16)

        Write-Info "[$layerIndex/$($Layers.Count)] レイヤーを展開中: $shortDigest..."

        # tar.gz を展開 (Windows 10 1803以降に標準搭載のtar.exeを使用)
        $currentLocation = Get-Location
        Set-Location $rootfsDir

        try {
            & tar -xzf $layerFile 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "tar コマンドの実行に失敗しました (終了コード: $LASTEXITCODE)"
            }
            Write-Success "[$layerIndex/$($Layers.Count)] 展開完了: $shortDigest"
        } catch {
            Write-ErrorMsg "レイヤーの展開に失敗しました: $_"
            throw
        } finally {
            Set-Location $currentLocation
        }

        $layerIndex++
    }

    Write-Success "rootfs の構築が完了しました"
    return $rootfsDir
}

function Create-RootFsArchive {
    param(
        [string]$RootFsDir,
        [string]$OutputPath
    )

    Write-Step "rootfs をアーカイブ中"
    Write-Info "出力先: $OutputPath"

    $currentLocation = Get-Location
    Set-Location $RootFsDir

    try {
        # rootfs の内容を tar.gz にアーカイブ
        & tar -czf $OutputPath * 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "tar コマンドの実行に失敗しました (終了コード: $LASTEXITCODE)"
        }

        $size = (Get-Item $OutputPath).Length / 1MB
        Write-Success "アーカイブ完了: $($size.ToString('F2')) MB"
    } catch {
        Write-ErrorMsg "アーカイブの作成に失敗しました: $_"
        throw
    } finally {
        Set-Location $currentLocation
    }

    return $OutputPath
}

# =============================================================================
# WSL2 インポート
# =============================================================================

function Import-ToWSL2 {
    param(
        [string]$DistroName,
        [string]$InstallLocation,
        [string]$RootFsTarGz
    )

    Write-Step "WSL2 にインポート中"

    # 既存のディストリビューションをチェック
    $existingDistros = wsl --list --quiet
    if ($existingDistros -contains $DistroName) {
        Write-ColorOutput "警告: ディストリビューション '$DistroName' は既に存在します" "Yellow"
        $response = Read-Host "既存のディストリビューションを削除して続行しますか? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Info "既存のディストリビューションを削除中..."
            wsl --unregister $DistroName
            Write-Success "削除完了"
        } else {
            throw "インポートをキャンセルしました"
        }
    }

    # インストール先ディレクトリを作成
    if (-not (Test-Path $InstallLocation)) {
        New-Item -ItemType Directory -Path $InstallLocation -Force | Out-Null
    }

    Write-Info "WSL2 にインポート中: $DistroName"
    Write-Info "インストール先: $InstallLocation"

    try {
        wsl --import $DistroName $InstallLocation $RootFsTarGz
        if ($LASTEXITCODE -ne 0) {
            throw "wsl --import コマンドが失敗しました (終了コード: $LASTEXITCODE)"
        }
        Write-Success "WSL2 へのインポートが完了しました"
    } catch {
        Write-ErrorMsg "WSL2 へのインポートに失敗しました: $_"
        throw
    }
}

function Test-WslDistro {
    param([string]$DistroName)

    Write-Step "インポートされたディストリビューションを確認"

    Write-Info "WSL2 ディストリビューション一覧:"
    wsl --list --verbose

    Write-Info "ディストリビューションのテスト実行中..."
    wsl -d $DistroName cat /etc/os-release | Select-String "PRETTY_NAME"

    Write-Success "ディストリビューションは正常に動作しています"
}

# =============================================================================
# メイン処理
# =============================================================================

function Main {
    Write-Host ""
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput "  OCI イメージ → WSL2 インポートツール" "Cyan"
    Write-ColorOutput "  (外部ツール不要・素のPowerShellのみ)" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""

    # パラメータ表示
    Write-Host "設定:"
    Write-Host "  イメージURL      : $ImageUrl"
    Write-Host "  WSLディストリ名  : $WslDistroName"
    Write-Host "  インストール先   : $InstallLocation"
    Write-Host "  一時ディレクトリ : $TempDir"
    Write-Host ""

    try {
        # 前提条件チェック
        Write-Step "前提条件をチェック中"

        # WSL2 の確認
        $wslVersion = wsl --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "WSL2 がインストールされていません。'wsl --install' を実行してください。"
        }
        Write-Success "WSL2 が利用可能です"

        # tar コマンドの確認
        $tarVersion = tar --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "tar コマンドが見つかりません。Windows 10 (1803以降) または Windows 11 が必要です。"
        }
        Write-Success "tar コマンドが利用可能です"

        # 一時ディレクトリの作成
        Write-Step "作業環境を準備中"
        if (-not (Test-Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        $layersDir = Join-Path $TempDir "layers"
        if (-not (Test-Path $layersDir)) {
            New-Item -ItemType Directory -Path $layersDir | Out-Null
        }
        Write-Success "一時ディレクトリを作成しました: $TempDir"

        # イメージURLの解析
        Write-Step "イメージ情報を解析中"
        $imageInfo = Parse-ImageUrl -Url $ImageUrl
        Write-Host "  レジストリ: $($imageInfo.Registry)"
        Write-Host "  イメージ  : $($imageInfo.Image)"
        Write-Host "  タグ      : $($imageInfo.Tag)"

        # 認証トークンの取得
        Write-Step "レジストリに接続中"
        $token = Get-RegistryToken -Registry $imageInfo.Registry -Image $imageInfo.Image

        # マニフェストの取得
        Write-Step "イメージマニフェストを取得中"
        $manifestData = Get-ImageManifest `
            -Registry $imageInfo.Registry `
            -Image $imageInfo.Image `
            -Tag $imageInfo.Tag `
            -Token $token

        $manifest = $manifestData.Manifest
        $contentType = $manifestData.ContentType

        # マニフェストリストの場合は、linux/amd64 のマニフェストを取得
        if ($contentType -match "manifest.list" -or $contentType -match "image.index") {
            $manifest = Get-PlatformManifest `
                -Registry $imageInfo.Registry `
                -Image $imageInfo.Image `
                -Token $token `
                -ManifestList $manifest
        }

        # レイヤー情報の取得
        $layers = $manifest.layers
        Write-Host "  レイヤー数: $($layers.Count)"

        # 各レイヤーのダウンロード
        Write-Step "レイヤーをダウンロード中 ($($layers.Count) 個)"
        $layerIndex = 1
        foreach ($layer in $layers) {
            $layerFile = Join-Path $layersDir "$($layer.digest -replace ':', '-').tar.gz"
            Download-Blob `
                -Registry $imageInfo.Registry `
                -Image $imageInfo.Image `
                -Token $token `
                -Digest $layer.digest `
                -OutputPath $layerFile `
                -Index $layerIndex `
                -Total $layers.Count
            $layerIndex++
        }

        # rootfs の構築
        $rootfsDir = Build-RootFs -TempDir $TempDir -Layers $layers

        # rootfs のアーカイブ作成
        $rootfsTarGz = Join-Path $TempDir "rootfs.tar.gz"
        Create-RootFsArchive -RootFsDir $rootfsDir -OutputPath $rootfsTarGz

        # WSL2 へのインポート
        Import-ToWSL2 `
            -DistroName $WslDistroName `
            -InstallLocation $InstallLocation `
            -RootFsTarGz $rootfsTarGz

        # テスト実行
        Test-WslDistro -DistroName $WslDistroName

        # 完了メッセージ
        Write-Host ""
        Write-ColorOutput "========================================" "Green"
        Write-ColorOutput "  インポートが完了しました！" "Green"
        Write-ColorOutput "========================================" "Green"
        Write-Host ""
        Write-Host "次のコマンドでディストリビューションを起動できます:"
        Write-ColorOutput "  wsl -d $WslDistroName" "Yellow"
        Write-Host ""
        Write-Host "デフォルトのディストリビューションに設定する場合:"
        Write-ColorOutput "  wsl --set-default $WslDistroName" "Yellow"
        Write-Host ""

    } catch {
        Write-Host ""
        Write-ErrorMsg "エラーが発生しました: $_"
        Write-Host ""
        Write-Host "トラブルシューティング:"
        Write-Host "  - インターネット接続を確認してください"
        Write-Host "  - イメージURLが正しいか確認してください"
        Write-Host "  - WSL2 が正しくインストールされているか確認してください"
        Write-Host ""
        exit 1
    } finally {
        # クリーンアップの提案
        if (Test-Path $TempDir) {
            Write-Host ""
            Write-Host "一時ファイルをクリーンアップする場合:"
            Write-ColorOutput "  Remove-Item -Recurse -Force '$TempDir'" "Gray"
            Write-Host ""
        }
    }
}

# スクリプト実行
Main
