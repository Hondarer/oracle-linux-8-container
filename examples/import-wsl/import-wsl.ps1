# Oracle Linux 開発環境を WSL2 にインポートする PowerShell スクリプト
#
# このスクリプトは、GitHub Container Registry (ghcr.io) から
# OCI Artifact として公開されている WSL2 rootfs をダウンロードし、
# WSL2 ディストリビューションとしてインポートします。
#
# 前提条件:
# - Windows 10 (1803以降) または Windows 11
# - WSL2 がインストール済み
# - インターネット接続
#
# 使用する Windows 標準機能:
# - PowerShell (Invoke-RestMethod, Invoke-WebRequest)
# - wsl.exe (WSL2 管理コマンド)

param(
    [string]$OLVersion = "8",
    [string]$Tag = "latest-wsl",
    [string]$ImageUrl = "",
    [string]$WslDistroName = "",
    [string]$InstallLocation = "",
    [string]$TempDir = "$env:TEMP\wsl-import-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

# デフォルト値の設定
if ([string]::IsNullOrEmpty($WslDistroName)) {
    $WslDistroName = "OracleLinux${OLVersion}-Dev"
}
if ([string]::IsNullOrEmpty($InstallLocation)) {
    $InstallLocation = "$env:LOCALAPPDATA\WSL\$WslDistroName"
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # 進捗表示を無効化して高速化

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
# イメージ URL 解析
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
        $tag = "latest-wsl"
    } else {
        throw "無効なイメージ URL 形式: $Url"
    }

    return @{
        Registry = $registry
        Image = $image
        Tag = $tag
        Full = "$registry/$image`:$tag"
    }
}

# =============================================================================
# OCI Registry API v2 認証
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
        Write-ErrorMsg "認証に失敗しました: $_"
        throw
    }
}

# =============================================================================
# マニフェスト取得
# =============================================================================

function Get-ArtifactManifest {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Tag,
        [string]$Token
    )

    Write-Info "マニフェストを取得中..."

    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept" = "application/vnd.oci.image.manifest.v1+json"
    }

    $manifestUrl = "https://$Registry/v2/$Image/manifests/$Tag"

    try {
        $response = Invoke-RestMethod -Uri $manifestUrl -Method Get -Headers $headers
        Write-Success "マニフェストを取得しました"
        return $response
    } catch {
        Write-ErrorMsg "マニフェストの取得に失敗しました: $_"
        throw
    }
}

# =============================================================================
# Blob ダウンロード
# =============================================================================

function Download-Blob {
    param(
        [string]$Registry,
        [string]$Image,
        [string]$Token,
        [string]$Digest,
        [string]$OutputPath
    )

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    $blobUrl = "https://$Registry/v2/$Image/blobs/$Digest"
    $shortDigest = $Digest.Substring(0, 16)

    Write-Info "WSL rootfs をダウンロード中: $shortDigest..."

    try {
        Invoke-WebRequest -Uri $blobUrl -Method Get -Headers $headers -OutFile $OutputPath
        $size = (Get-Item $OutputPath).Length / 1MB
        Write-Success "ダウンロード完了: $($size.ToString('F2')) MB"
    } catch {
        Write-ErrorMsg "ダウンロード失敗: $_"
        throw
    }
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

    # 既存のディストリビューションを確認
    $existingDistros = wsl --list --quiet 2>$null
    if ($existingDistros -contains $DistroName) {
        Write-Host ""
        Write-ColorOutput "警告: 既存のディストリビューション '$DistroName' が見つかりました" "Yellow"
        Write-Host ""
        Write-ColorOutput "  このディストリビューションを削除すると、以下のデータがすべて失われます:" "Red"
        Write-Host "  - ホームディレクトリ内のすべてのファイル"
        Write-Host "  - インストールされたパッケージと設定"
        Write-Host "  - ユーザーデータとカスタマイズ"
        Write-Host ""
        $response = Read-Host "削除して再インポートしますか? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Info "既存のディストリビューションを削除中..."
            wsl --unregister $DistroName
            Write-Success "削除しました"
        } else {
            throw "インポートがキャンセルされました"
        }
    }

    # インストール先ディレクトリの作成
    if (-not (Test-Path $InstallLocation)) {
        New-Item -ItemType Directory -Path $InstallLocation -Force | Out-Null
    }

    # WSL2 にインポート
    Write-Info "インポート中: $DistroName"
    Write-Info "インストール先: $InstallLocation"

    wsl --import $DistroName $InstallLocation $RootFsTarGz

    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL2 へのインポートが完了しました"
    } else {
        throw "WSL2 へのインポートに失敗しました (終了コード: $LASTEXITCODE)"
    }
}

# =============================================================================
# WSL ディストリビューションのテスト
# =============================================================================

function Test-WslDistro {
    param([string]$DistroName)

    Write-Step "ディストリビューションをテスト中"

    Write-Info "OS 情報を取得中..."
    wsl -d $DistroName cat /etc/os-release | Select-String "PRETTY_NAME"

    Write-Info "Node.js バージョンを確認中..."
    wsl -d $DistroName node --version

    Write-Info "Java バージョンを確認中..."
    wsl -d $DistroName java --version | Select-Object -First 1

    Write-Success "ディストリビューションが正常に動作しています"
}

# =============================================================================
# メイン処理
# =============================================================================

function Main {
    Write-Host ""
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput "  WSL2 インポートツール" "Cyan"
    Write-ColorOutput "  Oracle Linux $OLVersion 開発環境" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""

    # ImageUrl が指定されていない場合、Tag パラメータを使用して構築
    if ([string]::IsNullOrEmpty($ImageUrl)) {
        $script:ImageUrl = "ghcr.io/hondarer/oracle-linux-container/oracle-linux-${OLVersion}-dev:$Tag"
    }

    # パラメータ表示
    Write-Host "設定:"
    Write-Host "  イメージ URL     : $ImageUrl"
    Write-Host "  WSL ディストリ名 : $WslDistroName"
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

        # 一時ディレクトリの作成
        Write-Step "作業環境を準備中"
        if (-not (Test-Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        Write-Success "一時ディレクトリを作成しました: $TempDir"

        # イメージ URL の解析
        Write-Step "イメージ情報を解析中"
        $imageInfo = Parse-ImageUrl -Url $ImageUrl
        Write-Host "  レジストリ: $($imageInfo.Registry)"
        Write-Host "  イメージ  : $($imageInfo.Image)"
        Write-Host "  タグ      : $($imageInfo.Tag)"

        # 認証トークンの取得
        Write-Step "レジストリに接続中"
        $token = Get-RegistryToken -Registry $imageInfo.Registry -Image $imageInfo.Image

        # マニフェストの取得
        Write-Step "OCI Artifact マニフェストを取得中"
        $manifest = Get-ArtifactManifest `
            -Registry $imageInfo.Registry `
            -Image $imageInfo.Image `
            -Tag $imageInfo.Tag `
            -Token $token

        # レイヤー (WSL rootfs) の取得
        if ($manifest.layers -and $manifest.layers.Count -gt 0) {
            $layer = $manifest.layers[0]
            Write-Info "Rootfs サイズ: $([math]::Round($layer.size / 1MB, 2)) MB"
            Write-Info "Media Type: $($layer.mediaType)"

            # Rootfs のダウンロード
            Write-Step "WSL rootfs をダウンロード中"
            $rootfsTarGz = Join-Path $TempDir "wsl-rootfs.tar.gz"
            Download-Blob `
                -Registry $imageInfo.Registry `
                -Image $imageInfo.Image `
                -Token $token `
                -Digest $layer.digest `
                -OutputPath $rootfsTarGz

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
            Write-Host "初回起動時はユーザーが作成されます。"
            Write-Host "環境変数で制御する場合:"
            Write-ColorOutput "  wsl -d $WslDistroName -e bash -c 'HOST_USER=myuser HOST_UID=1000 HOST_GID=1000 /entrypoint.sh'" "Gray"
            Write-Host ""

        } else {
            throw "マニフェストにレイヤーが含まれていません"
        }

    } catch {
        Write-Host ""
        Write-ErrorMsg "エラーが発生しました: $_"
        Write-Host ""
        Write-Host "トラブルシューティング:"
        Write-Host "  - インターネット接続を確認してください"
        Write-Host "  - イメージ URL が正しいか確認してください"
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
