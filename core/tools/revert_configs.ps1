$paths = @(
    "c:\Users\pc\Downloads\ano na\core\pvz_fusion_config.json",
    "c:\Users\pc\Downloads\ano na\core\pvz_fusion_template.json",
    "c:\Users\pc\Downloads\ano na\core\cards.json",
    "c:\Users\pc\Downloads\ano na\core\cards-data.js"
)
$userConfigs = Get-ChildItem -Path "c:\Users\pc\Downloads\ano na\core\user_configs" -Filter "*.json" | Where-Object { $_.Name -ne "users_registry.json" } | Select-Object -ExpandProperty FullName
$allFiles = $paths + $userConfigs

foreach ($file in $allFiles) {
    if (Test-Path $file) {
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        $content = $content.Replace('"spawn_impking"', '"spawn_ultimateimpking"')
        $content = $content.Replace('"Spawn Imperor (235)"', '"Spawn UltimateImpKing"')
        $content = $content.Replace('spawn_impking.webp', 'spawn_ultimateimpking.webp')
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
    }
}
Write-Host "Reverted all configurations back to spawn_ultimateimpking (234)!"
