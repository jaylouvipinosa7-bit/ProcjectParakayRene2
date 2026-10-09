New-Item -ItemType Directory -Force -Path "c:\Users\pc\Downloads\ano na\images\tiktok-gifts" | Out-Null

$m = Get-Content 'C:\Users\pc\AppData\Local\Runetify\game_mappings.json' -Raw | ConvertFrom-Json
$gifts = @{}
foreach ($prop in $m.PSObject.Properties) {
    if ($prop.Value) {
        foreach ($item in $prop.Value) {
            if ($item.trigger -and $item.trigger.type -eq 'gift' -and $item.trigger.giftId) {
                $id = $item.trigger.giftId
                if (-not $gifts.ContainsKey($id)) {
                    $gifts[$id] = @{
                        id = $id
                        name = $item.trigger.label
                        coins = if ($item.trigger.coins) { [int]$item.trigger.coins } else { 1 }
                        icon = $item.trigger.icon
                    }
                }
            }
        }
    }
}

# Also ensure essential gifts like Doughnut, Lion, Universe are in list
$extraGifts = @(
    @{ id = "5879"; name = "Doughnut"; coins = 30; icon = "https://p16-webcast.tiktokcdn.com/webcast-va/4e7ad6bdf0a1d860c538f38026d4e812~tplv-obj.image" },
    @{ id = "6094"; name = "Lion"; coins = 29999; icon = "https://p16-webcast.tiktokcdn.com/img/maliva/webcast-va/8e581db3a4794e24efb48e3cf9aeb51f~tplv-obj.webp" },
    @{ id = "6095"; name = "TikTok Universe"; coins = 34999; icon = "https://p16-webcast.tiktokcdn.com/img/maliva/webcast-va/db5c2faea746205e4125b03bb9116e07~tplv-obj.webp" },
    @{ id = "5881"; name = "Money Gun"; coins = 500; icon = "https://p16-webcast.tiktokcdn.com/img/maliva/webcast-va/e0589e95a2b41970f0f30f6202f5fce6~tplv-obj.webp" },
    @{ id = "6267"; name = "Corgi"; coins = 299; icon = "https://p16-webcast.tiktokcdn.com/img/maliva/webcast-va/148eef0884fdb12058d1c6897d1e02b9~tplv-obj.webp" },
    @{ id = "11046"; name = "Galaxy"; coins = 1000; icon = "https://p16-webcast.tiktokcdn.com/img/maliva/webcast-va/resource/79a02148079526539f7599150da9fd28.png~tplv-obj.webp" }
)
foreach ($eg in $extraGifts) {
    $gifts[$eg.id] = $eg
}

$downloadedCount = 0
$finalCatalogGifts = @()

foreach ($g in $gifts.Values) {
    $safeName = ($g.name.ToLower() -replace '[^a-z0-9]', '_').Trim('_')
    $localFile = "images/tiktok-gifts/$($g.id)_$($safeName).webp"
    $fullPath = "c:\Users\pc\Downloads\ano na\$localFile"

    if (-not (Test-Path $fullPath) -and $g.icon) {
        try {
            Invoke-WebRequest -Uri $g.icon -OutFile $fullPath -TimeoutSec 10 -UserAgent "Mozilla/5.0" -ErrorAction Stop
            $downloadedCount++
        } catch {
            Write-Warning "Failed downloading $($g.name): $($_.Exception.Message)"
        }
    }

    $entry = @{
        id = $g.id
        name = $g.name
        coins = $g.coins
        icon = if (Test-Path $fullPath) { $localFile } else { $g.icon }
        cdnIcon = $g.icon
    }
    $finalCatalogGifts += $entry
}

Write-Output "Downloaded $downloadedCount new gift images. Total TikTok gifts prepared: $($finalCatalogGifts.Count)"

$finalCatalogGifts = $finalCatalogGifts | Sort-Object coins, name
$finalCatalogGifts | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 "c:\Users\pc\Downloads\ano na\tiktok_gifts_verified.json"
