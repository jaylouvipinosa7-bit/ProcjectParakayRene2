$zombieJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\ZombieStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$plantJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\LawnStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$enums = Get-Content "pvz_game_enums.json" -Raw -Encoding UTF8 | ConvertFrom-Json

$zNameMap = @{}
foreach ($z in $zombieJson.zombies) {
    $zNameMap[[int]$z.theZombieType] = $z.name
}

$pNameMap = @{}
foreach ($p in $plantJson.plants) {
    $pNameMap[[int]$p.seedType] = $p.name
}

Write-Host "Zombies mapped by ID: $($zNameMap.Count)"
Write-Host "Plants mapped by ID: $($pNameMap.Count)"

Write-Host "Sample mapped Zombies:"
@(0, 1, 2, 71, 240, 204, 251) | ForEach-Object {
    Write-Host "  ID $_ : $($zNameMap[$_])"
}

Write-Host "Sample mapped Plants:"
@(0, 1, 2, 307, 308, 309, 310) | ForEach-Object {
    Write-Host "  ID $_ : $($pNameMap[$_])"
}
