$h = Get-Content 'c:\Users\pc\Downloads\ano na\s2e_asar_header.json' -Raw
$matches = [regex]::Matches($h, '"([^"]+\.(?:json|png|webp|svg|jpg|js))"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch 'node_modules' } | Select-Object -Unique
Write-Output "Total files: $($matches.Count)"
$matches | Select-Object -First 50
