$bytes = [System.IO.File]::ReadAllBytes('C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll')
$str = [System.Text.Encoding]::Unicode.GetString($bytes)
$endpoints = [regex]::Matches($str, '(/spawn[a-zA-Z0-9_]*|/[a-zA-Z0-9_]{3,30}|spawn_[a-zA-Z0-9_]{3,30})') | ForEach-Object { $_.Value } | Select-Object -Unique | Sort-Object
$endpoints | Out-File "mod_endpoints.txt"
$endpoints | Select-Object -First 50
