$files = Get-ChildItem -Path "core" -Filter "*.html"
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $l = $lines[$i]
        if ($l -match 'S2E' -or $l -match 'runetify' -or $l -match 'Runetify') {
            if ($l -match '>[^<]*(s2e|runetify)[^<]*<' -or $l -match '(title|placeholder|aria-label)=["''][^"'']*(s2e|runetify)' -or $l -match 'showToast\(.*(s2e|runetify)' -or $l -match 'innerText\s*=.*(s2e|runetify)' -or $l -match 'innerHTML\s*=.*(s2e|runetify)') {
                Write-Host "$($f.Name) : $($i+1) : $($l.Trim())"
            }
        }
    }
}
