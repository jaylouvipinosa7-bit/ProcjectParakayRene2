$zombieJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\ZombieStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$plantJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\LawnStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "Total Zombies with official English names: $($zombieJson.zombies.Count)"
Write-Host "Total Plants with official English names: $($plantJson.plants.Count)"

# Check 71 and 240
$z71 = $zombieJson.zombies | Where-Object { $_.theZombieType -eq 71 }
$z240 = $zombieJson.zombies | Where-Object { $_.theZombieType -eq 240 }

Write-Host "`nZombie 71: $($z71.name)"
Write-Host "Zombie 240: $($z240.name)"
