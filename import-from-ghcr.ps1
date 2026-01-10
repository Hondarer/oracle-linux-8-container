# Oracle Linux 8 コンテナイメージを ghcr.io からダウンロードし、WSL2 にインポートする PowerShell スクリプト
#
# 前提条件:
# - Windows 11 または Windows 10 (WSL2 対応バージョン)
# - WSL2 がインストール済み
# - Podman for Windows がインストール済み (winget install -e --id RedHat.Podman)

param(
    [string]$ImageUrl = "ghcr.io/hondarer/oracle-linux-8-container/oracle-linux-8-dev:latest",
    [string]$TargetWslDistro = "",  # 空の場合は既定の WSL ディストリビューション
    [string]$TempDir = "$env:TEMP\podman-import"
)

$ErrorActionPreference = "Stop"

# カラー出力関数
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

# Podman のインストール確認
Write-Step "Podman のインストール確認"
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "Podman がインストールされていません"
    Write-Host "次のコマンドでインストールしてください:"
    Write-Host "  winget install -e --id RedHat.Podman"
    exit 1
}
Write-Success "Podman が見つかりました: $(podman --version)"

# Podman Machine の状態確認
Write-Step "Podman Machine の状態確認"
$machineStatus = podman machine list --format json | ConvertFrom-Json
if ($machineStatus.Count -eq 0) {
    Write-ColorOutput "Podman Machine が存在しません。初期化します..." "Yellow"
    podman machine init
    podman machine start
    Write-Success "Podman Machine を初期化しました"
} else {
    $running = $machineStatus | Where-Object { $_.Running -eq $true }
    if ($null -eq $running) {
        Write-ColorOutput "Podman Machine が停止しています。起動します..." "Yellow"
        podman machine start
        Write-Success "Podman Machine を起動しました"
    } else {
        Write-Success "Podman Machine は起動中です"
    }
}

# 一時ディレクトリの作成
Write-Step "一時ディレクトリの準備"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}
Write-Success "一時ディレクトリ: $TempDir"

# イメージのプル
Write-Step "コンテナイメージをプル中: $ImageUrl"
try {
    podman pull $ImageUrl
    Write-Success "イメージのプルが完了しました"
} catch {
    Write-ErrorMsg "イメージのプルに失敗しました: $_"
    exit 1
}

# イメージを tar.gz 形式で保存
$imageName = $ImageUrl -replace '.*/', '' -replace ':', '-'
$tarGzPath = Join-Path $TempDir "$imageName.tar.gz"
Write-Step "イメージを tar.gz 形式で保存中: $tarGzPath"
try {
    podman save $ImageUrl | gzip > $tarGzPath
    Write-Success "イメージの保存が完了しました"
    $fileSize = (Get-Item $tarGzPath).Length / 1MB
    Write-Host "  ファイルサイズ: $($fileSize.ToString('F2')) MB"
} catch {
    Write-ErrorMsg "イメージの保存に失敗しました: $_"
    exit 1
}

# WSL2 にインポート
Write-Step "WSL2 へのインポート"
$wslPath = $tarGzPath -replace '\\', '/'
$wslPath = "/mnt/" + $wslPath.Substring(0, 1).ToLower() + $wslPath.Substring(2)

if ($TargetWslDistro -eq "") {
    Write-ColorOutput "既定の WSL ディストリビューションにインポートします" "Yellow"
    $importCmd = "gunzip -c `"$wslPath`" | podman load"
} else {
    Write-ColorOutput "WSL ディストリビューション '$TargetWslDistro' にインポートします" "Yellow"
    $importCmd = "gunzip -c `"$wslPath`" | podman load"
}

try {
    if ($TargetWslDistro -eq "") {
        wsl bash -c $importCmd
    } else {
        wsl -d $TargetWslDistro bash -c $importCmd
    }
    Write-Success "WSL2 へのインポートが完了しました"
} catch {
    Write-ErrorMsg "WSL2 へのインポートに失敗しました: $_"
    Write-Host "手動でインポートする場合は、以下のコマンドを WSL2 内で実行してください:"
    Write-Host "  gunzip -c `"$wslPath`" | podman load"
    exit 1
}

# イメージの確認
Write-Step "インポートされたイメージの確認"
if ($TargetWslDistro -eq "") {
    wsl podman images | Select-String "oracle-linux-8"
} else {
    wsl -d $TargetWslDistro podman images | Select-String "oracle-linux-8"
}
Write-Success "完了しました"

# クリーンアップの提案
Write-Host "`n一時ファイルを削除する場合は、以下のコマンドを実行してください:"
Write-Host "  Remove-Item -Recurse -Force `"$TempDir`""
