# ==============================================================================
# RENEarn - Start Public Cloudflare Tunnel
# Exposes local overlay (port 8080) to the public web with secure HTTPS
# ==============================================================================

$folder = $PSScriptRoot
$cfExePath = Join-Path $folder "bin\cloudflared.exe"

if (-not (Test-Path $cfExePath)) {
    Write-Host "[ERROR] Cloudflared executable not found at: $cfExePath" -ForegroundColor Red
    exit 1
}

$cfExe = (Resolve-Path $cfExePath).Path
$logFile = Join-Path (Resolve-Path $folder).Path "tunnel.log"

function Read-SharedFile($path) {
    try {
        if (-not (Test-Path $path)) { return "" }
        $fs = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr = [System.IO.StreamReader]::new($fs)
        $content = $sr.ReadToEnd()
        $sr.Close()
        $fs.Close()
        return $content
    } catch {
        return ""
    }
}

# 1. Get or create persistent token (24 hex characters matching S2E format)
$tokenFile = Join-Path $folder "overlay_token.txt"
$userToken = ""
if (Test-Path $tokenFile) {
    $userToken = (Get-Content $tokenFile -Raw -ErrorAction SilentlyContinue).Trim()
}
if (-not $userToken -or $userToken.Length -lt 16) {
    $userToken = "6a7037f3324251772e699846"
    [System.IO.File]::WriteAllText($tokenFile, $userToken, [System.Text.Encoding]::UTF8)
}

# 2. Kill old cloudflared processes
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $logFile) {
    Remove-Item $logFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Starting Cloudflare Tunnel as a background service..." -ForegroundColor Cyan

# 3. Launch with --http-host-header localhost to allow Windows HttpListener to accept incoming requests
$cmdLine = "`"$cfExe`" tunnel --url http://localhost:8080 --http-host-header localhost --no-autoupdate --logfile `"$logFile`""
$createResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmdLine }

if ($createResult.ReturnValue -ne 0) {
    Write-Host "[WARNING] WMI process creation returned: $($createResult.ReturnValue), falling back to Start-Process..." -ForegroundColor Yellow
    Start-Process -FilePath $cfExe -ArgumentList "tunnel --url http://localhost:8080 --http-host-header localhost --no-autoupdate --logfile `"$logFile`"" -WindowStyle Hidden
}

# 4. Wait for public URL to appear in tunnel.log
$pubUrl = ""
Write-Host "Connecting to Cloudflare edge network..." -NoNewline -ForegroundColor Yellow

for ($i = 0; $i -lt 40; $i++) {
    Write-Host "." -NoNewline -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600

    $content = Read-SharedFile $logFile
    if ($content) {
        if ($content -match '(https://[a-zA-Z0-9-]+\.trycloudflare\.com)') {
            $pubUrl = $matches[1]
            if ($content -match 'Registered tunnel connection') {
                break
            }
        }
    }
}
Write-Host ""

if (-not $pubUrl) {
    Write-Host "[ERROR] Failed to obtain public tunnel URL from Cloudflare." -ForegroundColor Red
    Write-Host "Check log at: $logFile" -ForegroundColor DarkGray
    exit 1
}

# 5. Build public URLs
$info = @{
    active = $true
    publicUrl = $pubUrl
    userToken = $userToken
    mainOverlayUrl = "$pubUrl/overlay/$userToken"
    jarOverlayUrl = "$pubUrl/overlay/$userToken/jar"
    spinnerOverlayUrl = "$pubUrl/spinner"
    leaderboardOverlayUrl = "$pubUrl/leaderboard"
    goalOverlayUrl = "$pubUrl/goal"
    hudOverlayUrl = "$pubUrl/hud"
    updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$infoJson = $info | ConvertTo-Json -Depth 4
$infoFile = Join-Path $folder "tunnel_info.json"
[System.IO.File]::WriteAllText($infoFile, $infoJson, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  PUBLIC OVERLAY LINKS CREATED AND READY!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " Public URL Base   : $pubUrl" -ForegroundColor Cyan
Write-Host " User Token        : $userToken" -ForegroundColor DarkGray
Write-Host ""
Write-Host " OBS Browser Source Links (Paste these into OBS Studio):" -ForegroundColor White
Write-Host "  -> Main Overlay  : $($info.mainOverlayUrl)" -ForegroundColor Yellow
Write-Host "  -> Gift Jar      : $($info.jarOverlayUrl)" -ForegroundColor Yellow
Write-Host "  -> Spinner Wheel : $($info.spinnerOverlayUrl)" -ForegroundColor Yellow
Write-Host "  -> Leaderboard   : $($info.leaderboardOverlayUrl)" -ForegroundColor Yellow
Write-Host "  -> Goal Overlay  : $($info.goalOverlayUrl)" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Green
