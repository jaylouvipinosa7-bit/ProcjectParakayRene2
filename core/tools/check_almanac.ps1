$zombieJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\ZombieStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$plantJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\LawnStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "Total Zombies in English Almanac: $($zombieJson.Count)"
Write-Host "Total Plants in English Almanac: $($plantJson.Count)"

Write-Host "`nSample Zombies:"
$zombieJson[0..5] | ForEach-Object { Write-Host "  Type $($_.theZombieType): $($_.name)" }

Write-Host "`nSample Plants:"
$plantJson[0..5] | ForEach-Object { Write-Host "  SeedType $($_.seedType): $($_.name)" }
