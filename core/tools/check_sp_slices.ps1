param()
$c = Get-Content "pvz_fusion_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$sp = $c.spinners | Where-Object { $_.id -eq 'spinner_plusminus' }
Write-Output "SLICES COUNT: $($sp.slices.Count)"
$sp.slices | ForEach-Object {
    Write-Output "Slice: label='$($_.label)' weight=$($_.weight) delta=$($_.delta) cmd='$($_.command)'"
}
