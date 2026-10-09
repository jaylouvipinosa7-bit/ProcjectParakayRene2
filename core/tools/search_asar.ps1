$h = Get-Content "c:\Users\pc\Downloads\ano na\s2e_asar_header.json" -Raw
$matches = [regex]::Matches($h, '"([^"]*pvz[^"]*)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
Write-Output "Matched PVZ files in asar: $($matches.Count)"
$matches | Select-Object -First 40
