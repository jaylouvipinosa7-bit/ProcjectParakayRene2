$bytes = [System.IO.File]::ReadAllBytes('C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\S2EPvZFusionMod.dll.original.bak')
$str = [System.Text.Encoding]::Unicode.GetString($bytes)
$endpoints = [regex]::Matches($str, '(/spawn[a-zA-Z0-9_]*|/[a-zA-Z0-9_]{3,30}|spawn_[a-zA-Z0-9_]{3,30})') | ForEach-Object { $_.Value } | Select-Object -Unique | Sort-Object
$endpoints | Out-File -Encoding utf8 "s2e_mod_endpoints.txt"
Write-Output "Total S2E mod endpoints in original.bak: $($endpoints.Count)"
$endpoints | Select-Object -First 40
