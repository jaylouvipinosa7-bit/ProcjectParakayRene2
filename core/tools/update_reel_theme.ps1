$paths = @("pvz_fusion_config.json", "core/pvz_fusion_config.json")
$userConfigs = Get-ChildItem -Path "core/user_configs" -Filter "*.json" -ErrorAction SilentlyContinue
if ($userConfigs) {
    foreach ($uc in $userConfigs) {
        $paths += $uc.FullName
    }
}

$enc = New-Object System.Text.UTF8Encoding($false)
foreach ($p in $paths) {
    if (Test-Path $p) {
        $fullPath = (Resolve-Path $p).Path
        $content = [System.IO.File]::ReadAllText($fullPath)
        $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, '"reelTheme":\s*"neon_cyber"', '"reelTheme": "groudon_magma"')
        if ($newContent -ne $content) {
            [System.IO.File]::WriteAllText($fullPath, $newContent, $enc)
            Write-Host "Updated reelTheme in $p"
        }
    }
}
