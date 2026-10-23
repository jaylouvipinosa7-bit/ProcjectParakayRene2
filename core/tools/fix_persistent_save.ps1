$enc = New-Object System.Text.UTF8Encoding($false)

# ==================== 1. FIX SERVER.PS1 ====================
$serverPath = "core/server.ps1"
$sContent = [System.IO.File]::ReadAllText((Resolve-Path $serverPath).Path, [System.Text.Encoding]::UTF8)

# 1a. Remove forced overwrite at lines 1231-1253
$target1 = @'
    # Ensure Card 2 (Team Zombies Likes) is ALWAYS Trident Jugger-nut Gargantuar with correct unitIcon and command
    if ($cfg -and $cfg.gifts) {
        $g2 = $cfg.gifts | Where-Object { [string]$_.id -eq "2" -or ($_.giftName -and $_.giftName -match "team\s*zombies\s*likes") }
        if ($g2) {
            if ($g2.command -ne 'spawn_trident_juggernut_gargantuar' -or $g2.unitIcon -notmatch 'spawn_trident_juggernut_gargantuar' -or $g2.label -notmatch 'Trident\s*Jugger') {
                $g2.command = 'spawn_trident_juggernut_gargantuar'
                $g2.unitIcon = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp'
                $g2.label = 'Spawn Trident Jugger-nut Gargantuar (240)'
                $g2.functionName = 'Spawn Trident Jugger-nut Gargantuar (240)'
                $g2.actionType = 'zombie'
                if ($g2.PSObject.Properties['funcImg']) { $g2.funcImg = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp' }
                if ($g2.PSObject.Properties['funcName']) { $g2.funcName = 'Spawn Trident Jugger-nut Gargantuar (240)' }
                $g2.commands = @([PSCustomObject]@{
                    name = "Commands #1"
                    command = "spawn_trident_juggernut_gargantuar"
                    label = "Spawn Trident Jugger-nut Gargantuar (240)"
                    icon = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                    actionType = "zombie"
                    amount = 1
                })
            }
        }
    }
'@

$replace1 = @'
    # Ensure Card 2 exists if missing, but NEVER overwrite user's saved command/unit
    if ($cfg -and $cfg.gifts) {
        $g2 = $cfg.gifts | Where-Object { [string]$_.id -eq "2" -or ($_.giftName -and $_.giftName -match "team\s*zombies\s*likes") }
        if (-not $g2) {
            $newCard2 = [PSCustomObject]@{
                id = "2"
                giftName = "Team zombies likes"
                coins = 0
                likeThreshold = 50
                command = "spawn_knight_captain"
                label = "Spawn Knight Captain Zombie (70)"
                unitIcon = "images/game-icons/pvz/spawn_knight_captain.webp"
                actionType = "zombie"
                enabled = $true
            }
            $cfg.gifts += $newCard2
        }
    }
'@

if ($sContent.Contains($target1)) {
    $sContent = $sContent.Replace($target1, $replace1)
    Write-Host "server.ps1: Fixed block 1 (startup card 2 overwrite)"
} else {
    Write-Host "Warning: block 1 target not found exactly in server.ps1"
}

# 1b. Remove forced command/label in Build-CardEventsFromConfig
$target2 = @'
        # Resolve correct command for Trident Jugger-nut Gargantuar if it had generic bucket zombie or knight captain
        if ($id -eq "2" -or ($ev.giftName -and $ev.giftName -match 'team\s*zombies\s*likes') -or ($lbl -match 'Trident\s*Jugger.*Gargantuar') -or ($cmd -eq 'spawn_knight_captain' -and $id -eq "2")) {
            $cmd = 'spawn_trident_juggernut_gargantuar'
            $lbl = 'Spawn Trident Jugger-nut Gargantuar (240)'
        }
'@

$replace2 = @'
        # Keep user configured command and label as-is
'@

if ($sContent.Contains($target2)) {
    $sContent = $sContent.Replace($target2, $replace2)
    Write-Host "server.ps1: Fixed block 2 (Build-CardEventsFromConfig forced command)"
}

# 1c. Remove forced uIcon in Build-CardEventsFromConfig
$target3 = @'
        if ($id -eq "2" -or $cmd -eq 'spawn_trident_juggernut_gargantuar' -or ($lbl -match 'Trident\s*Jugger')) {
            $uIcon = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
        } elseif ($ev.unitIcon) {
'@

$replace3 = @'
        if ($ev.unitIcon) {
'@

if ($sContent.Contains($target3)) {
    $sContent = $sContent.Replace($target3, $replace3)
    Write-Host "server.ps1: Fixed block 3 (Build-CardEventsFromConfig forced uIcon)"
}

# 1d. Remove forced overlay cards values in Sync-ConfigToCards
$target4 = @'
            if ([string]$g.id -eq "2" -or ($g.eventType -eq "team_zombies_likes") -or ($g.giftName -match "team\s*zombies\s*likes") -or ($g.command -eq 'spawn_trident_juggernut_gargantuar') -or ($g.label -match 'Trident\s*Jugger')) {
                $fName = "Spawn Trident Jugger-nut Gargantuar (240)"
                $uImg = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                $cmdStr = "spawn_trident_juggernut_gargantuar"
                $overlayAction = "LikeForEach"
                $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
            } else {
                $fName = if ($g.label -and $g.label -ne "Custom") { [string]$g.label } elseif ($g.functionName -and $g.functionName -ne "Custom") { [string]$g.functionName } elseif ($g.command) { [string]$g.command } else { "Action" }
                $uImg = if ($g.unitIcon -and $g.unitIcon -notmatch "func_2") { [string]$g.unitIcon } elseif ($g.command) { "images/game-icons/pvz/$($g.command).webp" } else { "images/func_2.png" }
                $uImg = $uImg -replace '^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\/', ''
                $cmdStr = [string]$g.command

                # Use configured commands/sub-commands if available
                if ($g.commands -and $g.commands.Count -gt 0) {
                    $subCmdList = @()
                    foreach ($sc in $g.commands) {
                        if ($sc.command) { $subCmdList += [string]$sc.command }
                    }
                    if ($subCmdList.Count -gt 0) {
                        $cmdStr = $subCmdList -join ';'
                    }
                }
            }
'@

$replace4 = @'
            # Use user configured command, label, and unitIcon faithfully
            $cmdStr = [string]$g.command
            if ($g.commands -and $g.commands.Count -gt 0) {
                $subCmdList = @()
                foreach ($sc in $g.commands) {
                    if ($sc.command) { $subCmdList += [string]$sc.command }
                }
                if ($subCmdList.Count -gt 0) {
                    $cmdStr = $subCmdList -join ';'
                }
            }

            $fName = if ($g.label -and $g.label -ne "Custom") { [string]$g.label } elseif ($g.functionName -and $g.functionName -ne "Custom") { [string]$g.functionName } elseif ($cmdStr) { [string]$cmdStr } else { "Action" }
            $uImg = if ($g.unitIcon -and $g.unitIcon -notmatch "func_2") { [string]$g.unitIcon } elseif ($g.funcImg -and $g.funcImg -notmatch "func_2") { [string]$g.funcImg } elseif ($cmdStr) { "images/game-icons/pvz/$($cmdStr.Split(';')[0]).webp" } else { "images/func_2.png" }
            $uImg = $uImg -replace '^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\/', ''
'@

if ($sContent.Contains($target4)) {
    $sContent = $sContent.Replace($target4, $replace4)
    Write-Host "server.ps1: Fixed block 4 (Sync-ConfigToCards forced overlay card values)"
}

# 1e. Remove forced overwrite in GET /api/config lines 3099-3119
$target5 = @'
                    if ($parsedCfg -and $parsedCfg.gifts) {
                        $c2Obj = $parsedCfg.gifts | Where-Object { [string]$_.id -eq "2" -or ($_.giftName -and $_.giftName -match "team\s*zombies\s*likes") }
                        if ($c2Obj -and ($c2Obj.command -ne 'spawn_trident_juggernut_gargantuar' -or $c2Obj.unitIcon -notmatch 'spawn_trident_juggernut_gargantuar' -or $c2Obj.label -notmatch 'Trident\s*Jugger')) {
                            $c2Obj.command = 'spawn_trident_juggernut_gargantuar'
                            $c2Obj.unitIcon = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp'
                            $c2Obj.label = 'Spawn Trident Jugger-nut Gargantuar (240)'
                            $c2Obj.functionName = 'Spawn Trident Jugger-nut Gargantuar (240)'
                            $c2Obj.actionType = 'zombie'
                            if ($c2Obj.PSObject.Properties['funcImg']) { $c2Obj.funcImg = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp' }
                            if ($c2Obj.PSObject.Properties['funcName']) { $c2Obj.funcName = 'Spawn Trident Jugger-nut Gargantuar (240)' }
                            $c2Obj.commands = @([PSCustomObject]@{
                                name = "Commands #1"
                                command = "spawn_trident_juggernut_gargantuar"
                                label = "Spawn Trident Jugger-nut Gargantuar (240)"
                                icon = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                                actionType = "zombie"
                                amount = 1
                            })
                            $cfgModified = $true
                        }
                    }
'@

$replace5 = @'
                    # Do NOT overwrite Card 2 on GET /api/config - respect user saved changes
'@

if ($sContent.Contains($target5)) {
    $sContent = $sContent.Replace($target5, $replace5)
    Write-Host "server.ps1: Fixed block 5 (GET /api/config forced overwrite)"
}

[System.IO.File]::WriteAllText((Resolve-Path $serverPath).Path, $sContent, $enc)
Write-Host "server.ps1 successfully saved."

# ==================== 2. FIX APP.HTML ====================
$appPath = "core/app.html"
$aContent = [System.IO.File]::ReadAllText((Resolve-Path $appPath).Path, [System.Text.Encoding]::UTF8)

# 2a. Remove forced overwrite in loadConfig()
$targetApp1 = @'
                        // Ensure Gift 2 (Zombies Likes) is accurately Trident Jugger-nut Gargantuar
                        const gift2 = config.gifts.find(g => String(g.id) === '2');
                        if (gift2 && (gift2.command === 'spawn_knight_captain' || (gift2.label && gift2.label.includes('Trident') && gift2.command !== 'spawn_trident_juggernut_gargantuar'))) {
                            gift2.command = 'spawn_trident_juggernut_gargantuar';
                            gift2.unitIcon = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp';
                            gift2.label = 'Spawn Trident Jugger-nut Gargantuar (240)';
                            gift2.functionName = 'Spawn Trident Jugger-nut Gargantuar (240)';
                            gift2.actionType = 'zombie';
                            gift2.commands = [{
                                name: 'Commands #1',
                                command: 'spawn_trident_juggernut_gargantuar',
                                label: 'Spawn Trident Jugger-nut Gargantuar (240)',
                                icon: 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp',
                                actionType: 'zombie',
                                amount: 1
                            }];
                        }
'@

$replaceApp1 = @'
                        // Card 2 respects user saved unit and command without forced reset
'@

if ($aContent.Contains($targetApp1)) {
    $aContent = $aContent.Replace($targetApp1, $replaceApp1)
    Write-Host "app.html: Fixed block 1 (loadConfig forced gift2 overwrite)"
}

# 2b. Ensure saveGiftModal properly sets funcImg and updates config.socialTriggers
$targetApp2 = @'
                                gift.functionName = functionName;
                                gift.label = functionName;
                                gift.unitIcon = unitIcon;
'@

$replaceApp2 = @'
                                gift.functionName = functionName;
                                gift.label = functionName;
                                const cleanUnitIcon = (unitIcon || '').replace(/^https?:\/\/[^\/]+\//, '');
                                gift.unitIcon = cleanUnitIcon;
                                gift.funcImg = cleanUnitIcon;
                                gift.funcName = functionName;
                                if (String(gift.id) === '2' && config.socialTriggers) {
                                    if (!config.socialTriggers.likes) config.socialTriggers.likes = {};
                                    config.socialTriggers.likes.command = joinedCommand;
                                    config.socialTriggers.likes.label = functionName;
                                    config.socialTriggers.likes.unitIcon = cleanUnitIcon;
                                    config.socialTriggers.likes.actionType = primaryActionType;
                                    config.socialTriggers.likes.threshold = likeThreshold;
                                }
'@

if ($aContent.Contains($targetApp2)) {
    $aContent = $aContent.Replace($targetApp2, $replaceApp2)
    Write-Host "app.html: Fixed block 2 (saveGiftModal funcImg and socialTriggers sync)"
}

[System.IO.File]::WriteAllText((Resolve-Path $appPath).Path, $aContent, $enc)
Write-Host "app.html successfully saved."

# ==================== 3. FIX STREAM-OVERLAY.HTML ====================
$streamPath = "core/stream-overlay.html"
$stContent = [System.IO.File]::ReadAllText((Resolve-Path $streamPath).Path, [System.Text.Encoding]::UTF8)

$targetSt = @'
            let funcSrc = (card.funcImg || card.unitIcon || 'images/game-icons/pvz/spawn_gatling_pea.webp').replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//i, '');
            if (String(card.id) === '2' || String(card.giftName || '').toLowerCase().includes('team zombies') || String(card.commands || '').includes('trident') || String(card.funcName || '').includes('Trident')) {
                funcSrc = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp';
            }
'@

$replaceSt = @'
            let funcSrc = (card.funcImg || card.unitIcon || (card.commands ? 'images/game-icons/pvz/' + card.commands + '.webp' : '') || 'images/game-icons/pvz/spawn_gatling_pea.webp').replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//i, '');
'@

if ($stContent.Contains($targetSt)) {
    $stContent = $stContent.Replace($targetSt, $replaceSt)
    [System.IO.File]::WriteAllText((Resolve-Path $streamPath).Path, $stContent, $enc)
    Write-Host "stream-overlay.html: Fixed forced funcSrc override"
}

# ==================== 4. FIX S2E-OVERLAY.HTML ====================
$s2ePath = "core/s2e-overlay.html"
$s2eContent = [System.IO.File]::ReadAllText((Resolve-Path $s2ePath).Path, [System.Text.Encoding]::UTF8)

$targetS2e = @'
            let funcSrc = (card.funcImg || card.unitIcon || 'images/game-icons/pvz/spawn_gatling_pea.webp').replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//i, '');
            if (String(card.id) === '2' || String(card.giftName || '').toLowerCase().includes('team zombies') || String(card.commands || '').includes('trident') || String(card.funcName || '').includes('Trident')) {
                funcSrc = 'images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp';
            }
'@

$replaceS2e = @'
            let funcSrc = (card.funcImg || card.unitIcon || (card.commands ? 'images/game-icons/pvz/' + card.commands + '.webp' : '') || 'images/game-icons/pvz/spawn_gatling_pea.webp').replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//i, '');
'@

if ($s2eContent.Contains($targetS2e)) {
    $s2eContent = $s2eContent.Replace($targetS2e, $replaceS2e)
    [System.IO.File]::WriteAllText((Resolve-Path $s2ePath).Path, $s2eContent, $enc)
    Write-Host "s2e-overlay.html: Fixed forced funcSrc override"
}

Write-Host "All persistent save fixes applied successfully!"
