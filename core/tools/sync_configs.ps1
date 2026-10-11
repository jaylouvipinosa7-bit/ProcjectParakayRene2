$src = Join-Path $PSScriptRoot "..\pvz_fusion_config.json"
$userDir = Join-Path $PSScriptRoot "..\user_configs"

if ((Test-Path $src) -and (Test-Path $userDir)) {
    Get-ChildItem -Path $userDir -Filter "*_config.json" | ForEach-Object {
        Copy-Item -Path $src -Destination $_.FullName -Force
        Write-Output "Synchronized: $($_.Name)"
    }
}
