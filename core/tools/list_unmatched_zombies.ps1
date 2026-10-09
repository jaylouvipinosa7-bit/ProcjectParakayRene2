$iconFolder = "images\game-icons\pvz"
$allWebpFiles = Get-ChildItem -Path $iconFolder -Filter "*.webp"
$enums = Get-Content "pvz_game_enums.json" -Raw | ConvertFrom-Json

$normalizedLookup = @{}
foreach ($f in $allWebpFiles) {
    $base = $f.BaseName.ToLower()
    $clean = $base -replace '^spawn_', '' -replace '_', ''
    $normalizedLookup[$clean] = "images/game-icons/pvz/$($f.Name)"
    $normalizedLookup[$base] = "images/game-icons/pvz/$($f.Name)"
}

$zombieProps = ($enums.zombies | Get-Member -MemberType NoteProperty)
$unmatchedZ = @()
foreach ($z in $zombieProps) {
    if ($z.Name -eq "Nothing" -or $z.Name.StartsWith("EnumValueAsmResolver")) { continue }
    $clean = $z.Name.ToLower() -replace '^spawn_', '' -replace '_', ''
    if (-not $normalizedLookup.ContainsKey($clean)) {
        $unmatchedZ += $z.Name
    }
}
Write-Host "Unmatched zombies ($($unmatchedZ.Count)):"
$unmatchedZ | ForEach-Object {
    Write-Host "  $_"
}
