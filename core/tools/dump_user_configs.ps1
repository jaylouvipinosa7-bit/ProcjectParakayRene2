param()
Get-ChildItem "user_configs" -Filter "*.json" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Output "========================================"
    Write-Output "FILE: $($_.Name)"
    Write-Output "TIKTOK USERNAME: $($c.streamer.tiktokUsername)"
    Write-Output "SPINNERS COUNT: $($c.spinners.Count)"
    if ($c.spinners) {
        $c.spinners | ForEach-Object {
            Write-Output "  Spinner: ID=$($_.id) Name='$($_.name)' Enabled=$($_.enabled) GiftName='$($_.giftName)' GiftId='$($_.giftId)' TriggerType='$($_.triggerType)'"
        }
    }
    Write-Output "GIFTS COUNT: $($c.gifts.Count)"
    if ($c.gifts) {
        $c.gifts | ForEach-Object {
            Write-Output "  Gift Card #$($_.id): Name='$($_.giftName)' GiftId='$($_.giftId)' Action='$($_.actionType)' Cmd='$($_.command)' Enabled=$($_.enabled)"
        }
    }
}
