$plantJson = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\LawnStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$matches = $plantJson.plants | Where-Object { $_.name -like "*Gatling*" -or $_.name -like "*Sniper*" -or $_.name -like "*Ultimate*" }
Write-Host "Matched plants in LawnStringsTranslate: $($matches.Count)"
$matches | ForEach-Object {
    Write-Host "  $($_.seedType) : $($_.name)"
}
