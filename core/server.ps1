# ==============================================================================
# PvZ Fusion 4.0 - Live Stream Control Server & In-Game Bridge
# ==============================================================================

$port = 8080
$folder = $PSScriptRoot

# Mod listens on 55001 (or 5003 backup)
$gamePorts = @(55001, 5003)

# Disable Expect100Continue to eliminate HTTP POST stall delays
[System.Net.ServicePointManager]::Expect100Continue = $false

$countsFile = Join-Path $folder "counts.json"
$configFile = Join-Path $folder "pvz_fusion_config.json"
$cardsFile  = Join-Path $folder "cards.json"
$enumsFile  = Join-Path $folder "pvz_game_enums.json"
$catalogFile = Join-Path $folder "pvz_units_catalog.json"
$runetifyMapFile = Join-Path $folder "runetify_all_commands_map.json"
$templateConfigFile = Join-Path $folder "pvz_fusion_template.json"
$userConfigsFolder = Join-Path $folder "user_configs"
if (-not (Test-Path $userConfigsFolder)) {
    New-Item -ItemType Directory -Path $userConfigsFolder -Force | Out-Null
}
$usersDbFile = Join-Path $userConfigsFolder "users_registry.json"
$activeSessions = [System.Collections.Hashtable]::Synchronized(@{})

function Get-UserConfigPath($email) {
    if (-not $email -or [string]::IsNullOrWhiteSpace($email)) {
        return $configFile
    }
    $clean = $email.Trim().TrimStart('@').ToLower()
    $safe = ($clean -replace '[^a-z0-9_.-]', '_')
    $exactPath = Join-Path $userConfigsFolder "$safe`_config.json"
    if (Test-Path $exactPath) { return $exactPath }

    # Try TikTok variant
    $tiktokVariant = Join-Path $userConfigsFolder "tiktok_$safe`_tiktok.live_config.json"
    if (Test-Path $tiktokVariant) { return $tiktokVariant }

    # Try matching any file containing the username
    $matched = Get-ChildItem -Path $userConfigsFolder -Filter "*$safe*_config.json" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($matched) { return $matched.FullName }

    return $exactPath
}

# Proper MIME types for WebP, JSON, JS, CSS, SVG, etc.
$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".svg"  = "image/svg+xml"
    ".gif"  = "image/gif"
    ".ico"  = "image/x-icon"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
}

# In-memory recent events for Overlay and Dashboard polling
$eventsList = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

# Load Runetify 1005 command endpoint mappings
$runetifyCommands = @{}
if (Test-Path $runetifyMapFile) {
    try {
        $rJson = Get-Content $runetifyMapFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $rJson.PSObject.Properties) {
            $runetifyCommands[$prop.Name.ToLower()] = $prop.Value
        }
    } catch {}
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
    ".ico"  = "image/x-icon"
}

# Load or initialize counts
$counts = @{}
if (Test-Path $countsFile) {
    try {
        $cJson = Get-Content $countsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $cJson.PSObject.Properties) {
            $counts[$prop.Name] = [int]$prop.Value
        }
    } catch {}
}

# Ensure at least cards 1..100 exist
for ($i = 1; $i -le 100; $i++) {
    $k = [string]$i
    if (-not $counts.ContainsKey($k)) {
        $counts[$k] = 0
    }
}

# Team Battle & Live Likes Tracking State
$userTeams = @{}
$teamPlantsLikes = 0
$teamZombiesLikes = 0
$script:lastStreamTotalLikes = 0
$script:lastTotalLikesTriggeredMilestone = 0
$script:cardMilestones = [System.Collections.Hashtable]::Synchronized(@{})
$script:followersFile = Join-Path $folder "session_followers.json"

function Get-DailyFollowersTable {
    $todayStr = (Get-Date -Format "yyyy-MM-dd")
    $table = [System.Collections.Hashtable]::Synchronized(@{})
    if (Test-Path $script:followersFile) {
        try {
            $data = Get-Content $script:followersFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($data -and $data.date -eq $todayStr -and $data.followers) {
                foreach ($prop in $data.followers.PSObject.Properties) {
                    $table[$prop.Name] = $prop.Value
                }
            }
        } catch {}
    }
    return $table
}

function Save-DailyFollowersTable {
    $todayStr = (Get-Date -Format "yyyy-MM-dd")
    try {
        $dict = @{}
        foreach ($k in $script:sessionFollowers.Keys) {
            $dict[$k] = $script:sessionFollowers[$k]
        }
        $obj = @{
            date = $todayStr
            followers = $dict
        }
        $json = $obj | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($script:followersFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:sessionFollowers = Get-DailyFollowersTable

$verifiedGiftsFile = Join-Path $folder "tiktok_gifts_verified.json"
$script:verifiedGiftsCatalog = $null
if (Test-Path $verifiedGiftsFile) {
    try {
        $script:verifiedGiftsCatalog = Get-Content $verifiedGiftsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}

# ==================== LEADERBOARD TRACKING ====================
$leaderboardFile = Join-Path $folder "leaderboard_state.json"
$leaderboardSettingsFile = Join-Path $folder "leaderboard_settings.json"

function Load-Leaderboard {
    if (Test-Path $leaderboardFile) {
        try {
            $raw = Get-Content $leaderboardFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        likes = @{}
        coins = @{}
        avatars = @{}
    }
}

function Save-Leaderboard {
    try {
        $json = $script:leaderboard | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($leaderboardFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Load-LeaderboardSettings {
    if (Test-Path $leaderboardSettingsFile) {
        try {
            $raw = Get-Content $leaderboardSettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        likesEnabled = $true
        coinsEnabled = $true
        donatorsEnabled = $true
        likesStyle = "classic"
        coinsStyle = "classic"
        donatorsStyle = "cute"
        likesPosition = "left"
        coinsPosition = "left"
        donatorsPosition = "right"
        likesCount = 10
        coinsCount = 10
        donatorsCount = 5
        likesTitle = "Top 10 Likes"
        coinsTitle = "Top 10 Coins"
        donatorsTitle = "Top Donators"
        accentColor = "#f43f5e"
        backgroundColor = "rgba(13,17,23,0.92)"
        cardSpacing = 4
        fontSize = 14
        showAvatars = $true
        avatarStyle = "circle"
        animationSpeed = "normal"
    }
}

function Save-LeaderboardSettings($settings) {
    try {
        $json = $settings | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($leaderboardSettingsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:leaderboard = Load-Leaderboard
$script:leaderboardSettings = Load-LeaderboardSettings

function Update-LeaderboardLikes([string]$username, [int]$likeCount, [string]$avatar) {
    if (-not $username -or $username -eq "Viewer") { return }
    $cleanUser = $username.Trim()
    if (-not $script:leaderboard.likes) { $script:leaderboard | Add-Member -NotePropertyName likes -NotePropertyValue @{} -Force }
    $current = 0
    if ($script:leaderboard.likes.PSObject -and $script:leaderboard.likes.PSObject.Properties[$cleanUser]) {
        $current = [int]$script:leaderboard.likes.$cleanUser
    }
    $script:leaderboard.likes | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([int]($current + $likeCount)) -Force
    if ($avatar -and $avatar.Trim()) {
        if (-not $script:leaderboard.avatars) { $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue @{} -Force }
        $script:leaderboard.avatars | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([string]$avatar.Trim()) -Force
    }
    Save-Leaderboard
}

function Update-LeaderboardCoins([string]$username, [int]$coinValue, [string]$avatar) {
    if (-not $username -or $username -eq "Viewer" -or $username -eq "StreamGoal") { return }
    $cleanUser = $username.Trim()
    if (-not $script:leaderboard.coins) { $script:leaderboard | Add-Member -NotePropertyName coins -NotePropertyValue @{} -Force }
    $current = 0
    if ($script:leaderboard.coins.PSObject -and $script:leaderboard.coins.PSObject.Properties[$cleanUser]) {
        $current = [int]$script:leaderboard.coins.$cleanUser
    }
    $script:leaderboard.coins | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([int]($current + $coinValue)) -Force
    if ($avatar -and $avatar.Trim()) {
        if (-not $script:leaderboard.avatars) { $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue @{} -Force }
        $script:leaderboard.avatars | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([string]$avatar.Trim()) -Force
    }
    Save-Leaderboard
}

function Get-LeaderboardTop([string]$type, [int]$count = 10) {
    $data = $null
    if ($type -eq "likes" -and $script:leaderboard.likes) { $data = $script:leaderboard.likes }
    elseif ($type -eq "coins" -and $script:leaderboard.coins) { $data = $script:leaderboard.coins }
    else { return @() }

    $sorted = @()
    if ($data.PSObject -and $data.PSObject.Properties) {
        foreach ($prop in $data.PSObject.Properties) {
            $av = ""
            if ($script:leaderboard.avatars -and $script:leaderboard.avatars.PSObject -and $script:leaderboard.avatars.PSObject.Properties[$prop.Name]) {
                $av = [string]$script:leaderboard.avatars.$($prop.Name)
            }
            $sorted += [PSCustomObject]@{
                username = $prop.Name
                value = [int]$prop.Value
                avatar = $av
            }
        }
    }
    $sorted = $sorted | Sort-Object -Property value -Descending | Select-Object -First $count
    return @($sorted)
}
# ==================== END LEADERBOARD TRACKING ====================

function SaveCounts {
    try {
        $json = $counts | ConvertTo-Json
        [System.IO.File]::WriteAllText($countsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

# Win / Lose Widget State & Persistence
$winWidgetFile = Join-Path $folder "win_widget_state.json"
function Load-WinWidget {
    if (Test-Path $winWidgetFile) {
        try {
            $w = Get-Content $winWidgetFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($w) { return $w }
        } catch {}
    }
    return [PSCustomObject]@{
        enabled = $true
        score = -4
        target = 5
        wins = 472
        losses = 6724
        autoWin = $true
        hotkeysEnabled = $true
        label = "Win"
    }
}

function Save-WinWidget($w) {
    try {
        $json = $w | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($winWidgetFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:winWidget = Load-WinWidget

function Update-WinWidgetScore([int]$delta, [string]$reason = "spinner", [string]$label = "") {
    if (-not $script:winWidget) { $script:winWidget = Load-WinWidget }
    if ($delta -gt 0) {
        $script:winWidget.wins = [int]$script:winWidget.wins + $delta
    } elseif ($delta -lt 0) {
        $script:winWidget.losses = [int]$script:winWidget.losses + [Math]::Abs($delta)
    }
    $script:winWidget.score = [int]$script:winWidget.wins - [int]$script:winWidget.losses
    Save-WinWidget $script:winWidget

    AddEventLog @{
        type = "win_widget_update"
        score = $script:winWidget.score
        target = $script:winWidget.target
        wins = $script:winWidget.wins
        losses = $script:winWidget.losses
        delta = $delta
        reason = $reason
        label = $label
        enabled = [bool]$script:winWidget.enabled
    }
    return $script:winWidget
}

$script:lastWinAdjustTime = 0
$script:lastWinAdjustAction = ""
$script:recentSpins = [System.Collections.Hashtable]::Synchronized(@{})

$historyFile = Join-Path $PSScriptRoot "spinner_history.json"

function Load-SpinnerHistory {
    if (Test-Path $historyFile) {
        try {
            $raw = Get-Content $historyFile -Raw -Encoding UTF8
            $obj = $raw | ConvertFrom-Json
            if ($obj) { return $obj }
        } catch {}
    }
    return @{
        enabled = $true
        history = @()
    }
}

function Save-SpinnerHistory($state) {
    try {
        $json = $state | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($historyFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:spinnerHistory = Load-SpinnerHistory

function Add-SpinnerHistoryRecord($user, $avatar, $slice, $spName, $spId) {
    if (-not $script:spinnerHistory) { $script:spinnerHistory = Load-SpinnerHistory }
    
    $cleanUser = if ($user) { [string]$user } else { "User" }
    $cleanAvatar = if ($avatar -and $avatar.Trim()) { [string]$avatar } else { "images/default_avatar.svg" }
    $cleanSpName = if ($spName) { [string]$spName } else { "Spinner" }
    $cleanSpId = if ($spId) { [string]$spId } else { "1" }
    
    $lbl = if ($slice -and $slice.label) { [string]$slice.label } else { "Prize" }
    $isNum = ($slice -and ($slice.actionType -eq "score" -or $slice.delta -ne $null -or ($lbl -match '^[+-]?\s*\d+$')))
    $deltaVal = if ($slice -and $slice.delta -ne $null) { [int]$slice.delta } else { $null }
    
    $item = @{
        id = "sh_" + ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) + "_" + (Get-Random -Minimum 100 -Maximum 999)
        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        timeStr = (Get-Date -Format "HH:mm:ss")
        username = $cleanUser
        avatar = $cleanAvatar
        spinnerName = $cleanSpName
        spinnerId = $cleanSpId
        sliceId = if ($slice -and $slice.id) { [string]$slice.id } else { "" }
        label = $lbl
        delta = $deltaVal
        actionType = if ($slice -and $slice.actionType) { [string]$slice.actionType } else { "plant" }
        rarity = if ($slice -and $slice.rarity) { [string]$slice.rarity } else { "Normal" }
        color = if ($slice -and $slice.color) { [string]$slice.color } else { "#10b981" }
        icon = if ($slice) { if ($slice.unitIcon) { [string]$slice.unitIcon } elseif ($slice.icon) { [string]$slice.icon } else { "" } } else { "" }
        isNumber = [bool]$isNum
    }
    
    $existing = if ($script:spinnerHistory.history) { @($script:spinnerHistory.history) } else { @() }
    $combined = @($item) + $existing
    if ($combined.Count -gt 40) {
        $combined = $combined[0..39]
    }
    $script:spinnerHistory.history = $combined
    Save-SpinnerHistory $script:spinnerHistory
    
    AddEventLog @{
        type = "spinner_history_update"
        item = $item
        history = $combined
        enabled = [bool]$script:spinnerHistory.enabled
    }
    return $item
}

function LoadConfig {
    $cfg = $null
    if (Test-Path $configFile) {
        try {
            $cfg = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
    }
    if ($cfg -and $cfg.gifts -and -not ($cfg.gifts | Where-Object { [string]$_.id -eq "3" })) {
        $c3 = [PSCustomObject]@{
            id = "3"
            giftName = "Total Likes"
            giftId = ""
            coins = 0
            icon = "images/trig_7.svg"
            unitIcon = "images/game-icons/pvz/spawn_ultimatehorse.webp"
            actionType = "zombie"
            command = "spawn_ultimatehorse"
            label = "Spawn UltimateHorse"
            amount = 20
            enabled = $true
            likeThreshold = 50000
            commands = @([PSCustomObject]@{
                name = "Commands #1"
                command = "spawn_ultimatehorse"
                label = "Spawn UltimateHorse"
                icon = "images/game-icons/pvz/spawn_ultimatehorse.webp"
                actionType = "zombie"
                amount = 1
            })
            functionName = "spawn summon horse"
            repetition = 20
            delay = 0
            interval = 100
            repetitionMultiplier = $true
            hideInOverlay = $false
            triggerType = "likes_all"
            triggerValue = "50000"
            platform = "tiktok"
            availableFor = "Anyone"
        }
        $gList = [System.Collections.ArrayList]@($cfg.gifts)
        $gList.Insert([Math]::Min(2, $gList.Count), $c3)
        $cfg.gifts = $gList
    }
    return $cfg
}

function LoadCards {
    if (Test-Path $cardsFile) {
        try {
            return Get-Content $cardsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
    }
    return @()
}

function Sync-ConfigToCards {
    try {
        if (-not (Test-Path $configFile)) { return }
        $cfg = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $cfg.gifts) { return }
        
        $overlayCards = @()
        foreach ($g in $cfg.gifts) {
            $overlayAction = "SelectedGift"
            $trigVal = ""

            if ($g.id -eq "1" -or ($g.eventType -eq "team_plants_likes") -or ($g.giftName -match "team\s*plants\s*likes")) {
                $overlayAction = "LikeForEach"
                $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
            } elseif ($g.id -eq "2" -or ($g.eventType -eq "team_zombies_likes") -or ($g.giftName -match "team\s*zombies\s*likes")) {
                $overlayAction = "LikeForEach"
                $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
            } elseif ($g.id -eq "3" -or ($g.eventType -eq "total_likes") -or ($g.triggerType -eq "likes_all") -or ($g.giftName -match "total\s*likes|all\s*likes")) {
                $overlayAction = "LikeAmount"
                $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } elseif ($g.triggerValue) { [string]$g.triggerValue } else { "50000" }
            } elseif ($g.id -eq "4" -or ($g.eventType -eq "follow") -or ($g.giftName -match "^follow(er)?$")) {
                $overlayAction = "Follow"
                $trigVal = ""
            } elseif ($g.actionType -eq "share" -or ($g.giftName -match "^share\s*stream$")) {
                $overlayAction = "Share"
                $trigVal = ""
            } else {
                $overlayAction = "SelectedGift"
                $trigVal = ""
            }

            $overlayCards += [PSCustomObject]@{
                id = [string]$g.id
                action = $overlayAction
                giftId = if ($g.giftId) { [string]$g.giftId } else { "" }
                giftName = if ($g.giftName) { [string]$g.giftName } else { "Gift" }
                funcName = if ($g.label) { [string]$g.label } else { [string]$g.command }
                funcImg = if ($g.unitIcon) { [string]$g.unitIcon } else { "images/game-icons/pvz/$($g.command).webp" }
                trigImg = if ($g.icon) { [string]$g.icon } else { "images/tiktok-gifts/5655_rose.webp" }
                triggerValue = $trigVal
                commands = [string]$g.command
                repetition = if ($g.repetition -and [int]$g.repetition -gt 0) { [int]$g.repetition } elseif ($g.amount -and [int]$g.amount -gt 0) { [int]$g.amount } else { 1 }
            }
        }

        $cardsJson = $overlayCards | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($cardsFile, $cardsJson, [System.Text.Encoding]::UTF8)
        
        $cardsDataJsFile = Join-Path $folder "cards-data.js"
        $cardsDataJs = "const cardsData = " + $cardsJson + ";"
        [System.IO.File]::WriteAllText($cardsDataJsFile, $cardsDataJs, [System.Text.Encoding]::UTF8)
    } catch {
        Write-Warning "Sync-ConfigToCards error: $_"
    }
}

# Load and index all 729 plants and 237 zombies from game enums
$plantMap = @{}
$zombieMap = @{}

if (Test-Path $enumsFile) {
    try {
        $enums = Get-Content $enumsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($enums.plants) {
            foreach ($p in $enums.plants.PSObject.Properties) {
                $norm = $p.Name.ToLower() -replace '[^a-z0-9]', ''
                $plantMap[$norm] = [int]$p.Value
            }
        }
        if ($enums.zombies) {
            foreach ($z in $enums.zombies.PSObject.Properties) {
                $norm = $z.Name.ToLower() -replace '[^a-z0-9]', ''
                $zombieMap[$norm] = [int]$z.Value
            }
        }
    } catch {}
}

function Resolve-PlantId([string]$name) {
    if ($name -match '^\d+$') { return [int]$name }
    if ($name -match 'effect=(\d+)') { return [int]$matches[1] }
    if ($name -match '\((\d+)\)') { return [int]$matches[1] }

    $clean = $name.ToLower() -replace '^spawn[_\-]?', '' -replace '[^a-z0-9]', ''
    if ($plantMap.ContainsKey($clean)) { return $plantMap[$clean] }

    switch ($clean) {
        'ultimatesnipergatling'  { return 309 }
        'alec'                   { return 309 }
        'snipergatling'          { return 309 }
        'nucleardoomcherry'      { return 959 }
        'ultimatecattail'        { return 958 }
        'cattail'                { return 1067 }
        'sunnut'                 { return 251 }
        'bigsunnut'              { return 251 }
        'supersunnut'            { return 905 }
        'wallnut'                { return 255 }
        'machinenut'             { return 1151 }
        'superthreepeater'       { return 919 }
        'ultimategatling'        { return 901 }
        'supernutshooter'        { return 1423 }
        'ultimatemelon'          { return 914 }
        'ultimatewintermelon'    { return 957 }
        'ultimatepotatonut'      { return 925 }
        'supercherryshooter'     { return 1005 }
        'icedoom'                { return 1040 }
        'ultimatedoomgatling'    { return 971 }
    }

    foreach ($k in $plantMap.Keys) {
        if ($k.Contains($clean) -or $clean.Contains($k)) { return $plantMap[$k] }
    }
    return 251
}

function Resolve-ZombieId([string]$name) {
    if ($name -match '^\d+$') { return [int]$name }
    if ($name -match 'effect=(\d+)') { return [int]$matches[1] }
    if ($name -match '\((\d+)\)') { return [int]$matches[1] }

    $clean = $name.ToLower() -replace '^spawn[_\-]?', '' -replace '[^a-z0-9]', ''
    if ($zombieMap.ContainsKey($clean)) { return $zombieMap[$clean] }

    switch -Regex ($clean) {
        'trident.*jugger|ultiwatergargantuar' { return 240 }
        'hydrofowl|boatimp'      { return 71 }
        'ultimatefootballzombie' { return 220 }
        'footballzombie'         { return 9 }
        'football'               { return 9 }
        'ultimategoldgargantuar' { return 241 }
        'goldgargantuar'         { return 241 }
        'gargantuar'             { return 35 }
        'supergargantuar'        { return 43 }
        'kirovc'                 { return 329 }
        'kirovzombie'            { return 26 }
        'jacksonc'               { return 309 }
        'jacksonzombie'          { return 10 }
        'driverzombie'           { return 16 }
        'driver'                 { return 16 }
        'ultimatehorse'          { return 231 }
        'ultimatemachinenutzombie'{ return 210 }
        'machinenutzombie'       { return 210 }
        'squalourzombie'         { return 91 }
        'zombieboss2'            { return 46 }
        'zombieboss'             { return 44 }
        'bucket'                 { return 4 }
        'bucketzombie'           { return 4 }
        'ultimatejackboxzombie'  { return 224 }
        'ultimatejackbox'        { return 224 }
        'chickenimp'             { return 68 }
        'ultimategargantuar'     { return 212 }
    }

    foreach ($k in $zombieMap.Keys) {
        if ($k.Contains($clean) -or $clean.Contains($k)) { return $zombieMap[$k] }
    }
    return 9
}

function AddEventLog($eventObj) {
    $eventObj["id"] = [System.Guid]::NewGuid().ToString()
    $eventObj["timestamp"] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    
    $eventsList.Add($eventObj) | Out-Null
    while ($eventsList.Count -gt 100) {
        $eventsList.RemoveAt(0)
    }
}

function Test-GamePort([int]$p) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $ar = $tcp.BeginConnect("127.0.0.1", $p, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(150, $false)) {
            $tcp.EndConnect($ar)
            $tcp.Close()
            return $true
        }
        $tcp.Close()
    } catch {}
    return $false
}

# Cache active game port to avoid duplicate calls across both ports (55001 & 5003)
$script:activeGamePort = $null

# Post direct action to the PvZ Fusion game mod
function SendSinglePvZCommand($endpoint, $payloadObj) {
    $dispatched = $false
    try {
        $json = $payloadObj | ConvertTo-Json -Compress
        $rawBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

        # Prioritize known active port or 55001 first
        $primaryPort = if ($script:activeGamePort) { $script:activeGamePort } else { 55001 }
        $candidatePorts = @($primaryPort) + ($gamePorts | Where-Object { $_ -ne $primaryPort })

        foreach ($p in $candidatePorts) {
            $bytesSent = $false
            try {
                $req = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$p$endpoint")
                $req.Timeout = 1500
                $req.ReadWriteTimeout = 1500
                $req.KeepAlive = $false
                $req.Method = "POST"
                $req.ContentType = "application/json"
                $req.ContentLength = $rawBytes.Length

                $stream = $req.GetRequestStream()
                $stream.Write($rawBytes, 0, $rawBytes.Length)
                $stream.Close()
                $bytesSent = $true
                $dispatched = $true
                $script:activeGamePort = $p

                try {
                    $resp = $req.GetResponse()
                    $resp.Close()
                } catch {}

                # CRITICAL FIX: Once request stream bytes are delivered to the game mod on this port,
                # NEVER send to backup port 5003! Both ports map to the exact same game process,
                # so sending to both produces 2x summons (e.g. 10 instead of 5).
                break
            } catch {
                if ($bytesSent) {
                    # Bytes were already written, do not double-dispatch
                    break
                }
            }
        }
    } catch {}

    return @{ success = $dispatched; message = "Dispatched to game engine" }
}

# Master router for all PvZ Fusion commands (supports sub-commands, repetition, delay, interval)
function SendToPvZGame($actionType, $command, $amount = 1, $username = "StreamViewer", $avatarUrl = "", $repetition = 1, $delay = 0, $interval = 0) {
    if (-not $command) { return @{ success = $false; message = "Empty command" } }

    if ($delay -gt 0) {
        Start-Sleep -Milliseconds ([Math]::Min([int]$delay, 5000))
    }

    # Extract sub-commands (semicolon-separated string or array/collection)
    $subCmds = @()
    if ($command -is [System.Collections.IEnumerable] -and -not ($command -is [string])) {
        foreach ($c in $command) {
            if ($c.command) { $subCmds += [string]$c.command } else { $subCmds += [string]$c }
        }
    } else {
        $subCmds = [string]$command -split ';'
    }

    $reps = [Math]::Max(1, [int]$repetition)
    $rawAmt = [Math]::Max(1, [int]$amount)

    # Distribute count per repetition so that the TOTAL summons across all waves
    # matches the user's intended amount (avoiding amount * repetition multiplication explosion)
    $countPerRep = 1
    if ($reps -eq 1) {
        $countPerRep = $rawAmt
    } elseif ($rawAmt -ge $reps -and ($rawAmt % $reps -eq 0)) {
        $countPerRep = [int]($rawAmt / $reps)
    } elseif ($rawAmt -ge $reps) {
        $countPerRep = [Math]::Max(1, [int][Math]::Round($rawAmt / $reps))
    } else {
        $countPerRep = 1
    }

    $lastResult = @{ success = $true; message = "OK" }

    for ($r = 0; $r -lt $reps; $r++) {
        foreach ($sub in $subCmds) {
            $rawCmd = $sub.Trim()
            if (-not $rawCmd) { continue }

        $clean = $rawCmd.TrimStart('/').ToLower() -replace '[^a-z0-9]', ''
        $cleanRaw = $rawCmd.TrimStart('/').ToLower()

        # 0. Check direct Runetify command mapping (covers all 1,005 authentic commands)
        if ($runetifyCommands.ContainsKey($cleanRaw) -or $runetifyCommands.ContainsKey($clean)) {
            $cmdKey = if ($runetifyCommands.ContainsKey($cleanRaw)) { $cleanRaw } else { $clean }
            $info = $runetifyCommands[$cmdKey]
            $ep = $info.endpoint
            $eff = $info.effect
            $payload = @{
                effect     = [string]$eff
                count      = [int]$countPerRep
                amount     = [int]$countPerRep
                senderName = [string]$username
                username   = [string]$username
            }
            $lastResult = SendSinglePvZCommand $ep $payload
            continue
        }

        # 1. World Powers / Cheats
        $cheatEndpoint = ""
        $cheatPayload = @{ effect = [string]$countPerRep; amount = [int]$countPerRep; count = [int]$countPerRep; username = $username; avatarUrl = $avatarUrl }

        if ($clean -match '^(planteverywhere|planteverywahre)') {
            $cheatEndpoint = "/planteverywhere"
        } elseif ($clean -match '^(killallzombies|killzombies)') {
            $cheatEndpoint = "/killallzombies"
        } elseif ($clean -match '^(killallplants|killplants)') {
            $cheatEndpoint = "/killallplants"
        } elseif ($clean -match '^(charmallzombies|charmzombies)') {
            $cheatEndpoint = "/charmallzombies"
        } elseif ($clean -match '^invulnerableplants') {
            $cheatEndpoint = "/invulnerableplants"
        } elseif ($clean -match '^addsun') {
            $cheatEndpoint = "/addsun"
            $sunAmt = if ($rawAmt -gt 1) { $rawAmt } else { 100 }
            $cheatPayload = @{ effect = [string]$sunAmt; amount = [int]$sunAmt; count = [int]$sunAmt }
        } elseif ($clean -match '^setsun') {
            $cheatEndpoint = "/setsun"
            $cheatPayload = @{ effect = [string]$rawAmt; amount = [int]$rawAmt }
        } elseif ($clean -match '^unlimitedsun') {
            $cheatEndpoint = "/unlimitedsun"
        } elseif ($clean -match '^freecooldown') {
            $cheatEndpoint = "/freecooldown"
        } elseif ($clean -match '^seedrain') {
            $cheatEndpoint = "/seedrain"
        } elseif ($clean -match '^(startlawnmower|startlawnmowers)') {
            $cheatEndpoint = "/startlawnmowers"
        } elseif ($clean -match '^(restartlawnmower|restartlawnmowers)') {
            $cheatEndpoint = "/restartlawnmowers"
        } elseif ($clean -match '^(deletelawnmower|deletelawnmowers)') {
            $cheatEndpoint = "/deletelawnmowers"
        } elseif ($clean -match '^spawnmeteor') {
            $cheatEndpoint = "/spawnmeteor"
        } elseif ($clean -match '^stopzombiespawn') {
            $cheatEndpoint = "/stopzombiespawn"
        } elseif ($clean -match '^stopgameover') {
            $cheatEndpoint = "/stopgameover"
        } elseif ($clean -match '^spawntrophy') {
            $cheatEndpoint = "/spawntrophy"
        } elseif ($clean -match '^spawnfertilizer') {
            $cheatEndpoint = "/spawnfertilizer"
        } elseif ($clean -match '^spawnbucket') {
            $cheatEndpoint = "/spawnbucket"
        } elseif ($clean -match '^spawnhelmet') {
            $cheatEndpoint = "/spawnhelmet"
        } elseif ($clean -match '^spawnjack') {
            $cheatEndpoint = "/spawnjack"
        } elseif ($clean -match '^spawnpickaxe') {
            $cheatEndpoint = "/spawnpickaxe"
        } elseif ($clean -match '^spawnmecha') {
            $cheatEndpoint = "/spawnmecha"
        } elseif ($clean -match '^spawnsupermecha') {
            $cheatEndpoint = "/spawnsupermecha"
        } elseif ($clean -match '^spawnsprout') {
            $cheatEndpoint = "/spawnsprout"
        } elseif ($clean -match '^zombiesx2demage') {
            $cheatEndpoint = "/zombiesx2demage"
        } elseif ($clean -match '^zombiesx100demage') {
            $cheatEndpoint = "/zombiesx100demage"
        } elseif ($clean -match '^zombiesx0demage') {
            $cheatEndpoint = "/zombiesx0demage"
        }

        if ($cheatEndpoint) {
            $lastResult = SendSinglePvZCommand $cheatEndpoint $cheatPayload
            continue
        }

        # 2. Plant Spawning
        $isPlant = ($actionType -eq "plant") -or ($rawCmd -match "spawnplant") -or ($clean -match "(cattail|sunnut|wallnut|peashooter|gatling|threepeater|doomcherry|melon|potato)")
        if ($isPlant -and ($actionType -ne "zombie")) {
            $plantId = Resolve-PlantId $rawCmd
            $payload = @{
                effect     = [string]$plantId
                count      = [int]$countPerRep
                amount     = [int]$countPerRep
                senderName = [string]$username
                username   = [string]$username
            }
            $lastResult = SendSinglePvZCommand "/spawnplant" $payload
            continue
        }

        # 3. Zombie Spawning (Default)
        $zombieId = Resolve-ZombieId $rawCmd
        $payload = @{
            effect     = [string]$zombieId
            count      = [int]$countPerRep
            amount     = [int]$countPerRep
            senderName = [string]$username
            username   = [string]$username
        }
        $lastResult = SendSinglePvZCommand "/spawnzombie" $payload
        }
        if ($r -lt ($reps - 1) -and $interval -gt 0) {
            Start-Sleep -Milliseconds ([Math]::Min([int]$interval, 2000))
        }
    }

    return $lastResult
}

function ReadRequestBody($req) {
    if (-not $req.HasEntityBody) { return "{}" }
    try {
        $mem = New-Object System.IO.MemoryStream
        $req.InputStream.CopyTo($mem)
        $bytes = $mem.ToArray()
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return "{}"
    }
}

# Start HTTP Server Listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    $listener.Start()
} catch {
    Write-Host "Port $port already in use or access denied: $_" -ForegroundColor Red
    exit 1
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  PvZ Fusion 4.0 Live Stream Studio running!" -ForegroundColor Cyan
Write-Host "  -> Control Dashboard : http://localhost:$port/app.html" -ForegroundColor Yellow
Write-Host "  -> OBS / Studio Overlay: http://localhost:$port/overlay.html" -ForegroundColor Yellow
Write-Host "  -> Stream Overlay     : http://localhost:$port/stream-overlay.html" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "Keep this window open while playing & streaming!" -ForegroundColor DarkGray

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".svg"  = "image/svg+xml"
    ".json" = "application/json; charset=utf-8"
    ".ico"  = "image/x-icon"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
}

function Send-JsonResponse($resp, $obj, [int]$status = 200) {
    try {
        $json = if ($obj -is [string]) { $obj } else { $obj | ConvertTo-Json -Depth 6 }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $resp.StatusCode = $status
        $resp.ContentType = 'application/json; charset=utf-8'
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        $resp.OutputStream.Flush()
        $resp.Close()
    } catch {}
}

$nodePath = "C:\Users\pc\AppData\Local\app.runetify.desktop\runtimes\node\24.18.0\node.exe"
if (-not (Test-Path $nodePath)) {
    $nodePath = "C:\Users\pc\AppData\Local\AsureLive\node-runtime\node-22.23.2-win-x64-0d0f5e39f9f3\node.exe"
}
$script:tiktokBridgeProc = $null

function Start-TikTokBridge([string]$targetUser) {
    Stop-TikTokBridge
    $cleanUser = $targetUser.Trim().TrimStart('@')
    if (-not $cleanUser) { return }
    $bridgeScript = Join-Path $folder "tiktok_bridge.js"
    if ((Test-Path $nodePath) -and (Test-Path $bridgeScript)) {
        try {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $nodePath
            $pinfo.Arguments = "`"$bridgeScript`" `"$cleanUser`""
            $pinfo.WorkingDirectory = $folder
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $script:tiktokBridgeProc = [System.Diagnostics.Process]::Start($pinfo)
            Write-Host "  -> TikTok Live Bridge launched for @$cleanUser (PID $($script:tiktokBridgeProc.Id))" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to launch TikTok bridge: $_" -ForegroundColor Red
        }
    }
}

function Stop-TikTokBridge {
    if ($script:tiktokBridgeProc) {
        try {
            if (-not $script:tiktokBridgeProc.HasExited) {
                $script:tiktokBridgeProc.Kill()
            }
        } catch {}
        $script:tiktokBridgeProc = $null
    }
    try {
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*tiktok_bridge.js*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    } catch {}
}

# Auto-start TikTok bridge if username is configured
$initialCfg = LoadConfig
if ($initialCfg -and $initialCfg.streamer -and $initialCfg.streamer.tiktokUsername) {
    Start-TikTokBridge $initialCfg.streamer.tiktokUsername
}

while ($true) {
    try {
        if (-not $listener.IsListening) {
            try { $listener.Start() } catch {}
        }
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $reqPath = $request.Url.LocalPath

        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "*")
        $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
        $response.Headers.Add("Pragma", "no-cache")
        $response.Headers.Add("Expires", "0")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        # 1. Status Check
        if ($reqPath -eq '/api/status' -or $reqPath -eq '/api/game/status') {
            $config = LoadConfig
            $cards = LoadCards
            
            # Check if game is responding
            $gameActive = $false
            foreach ($p in $gamePorts) {
                if (Test-GamePort $p) {
                    $gameActive = $true
                    break
                }
            }

            $stateFile = Join-Path $folder "tiktok_live_state.json"
            $stObj = if (Test-Path $stateFile) { try { Get-Content $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null } } else { $null }
            $isLiveConnected = if ($stObj) { [bool]$stObj.connected } else { $false }
            $activeTtUser = if ($stObj -and $stObj.username) { [string]$stObj.username } elseif ($config -and $config.streamer) { [string]$config.streamer.tiktokUsername } else { "" }

            $resObj = @{
                status = "ok"
                online = $gameActive
                gameOnline = $gameActive
                pingMs = 4
                gamePorts = $gamePorts
                tiktokConnected = $isLiveConnected
                tiktokUsername = $activeTtUser
                tiktokRoomId = if ($stObj) { [string]$stObj.roomId } else { "" }
                tiktokViewers = if ($stObj -and $stObj.viewerCount) { [int]$stObj.viewerCount } else { 0 }
                serverPort = $port
                totalCards = $cards.Count
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 1b. TikTok Live Control Endpoints
        if ($reqPath -eq '/api/tiktok/connect') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $user = if ($data.username) { [string]$data.username.Trim().TrimStart('@') } else { "" }
            if (-not $user) {
                Send-JsonResponse $response @{ status = "error"; message = "TikTok username is required" }
                continue
            }
            $cfg = LoadConfig
            if (-not $cfg.streamer) { $cfg | Add-Member -MemberType NoteProperty -Name streamer -Value @{} -Force }
            $cfg.streamer.tiktokUsername = $user
            [System.IO.File]::WriteAllText($configFile, ($cfg | ConvertTo-Json -Depth 6), [System.Text.Encoding]::UTF8)
            Start-TikTokBridge $user
            Send-JsonResponse $response @{ status = "ok"; message = "Connecting to @$user"; username = $user }
            continue
        }

        if ($reqPath -eq '/api/tiktok/disconnect') {
            Stop-TikTokBridge
            $stateFile = Join-Path $folder "tiktok_live_state.json"
            if (Test-Path $stateFile) {
                $st = @{ connected = $false; statusText = "Disconnected"; username = "" }
                [System.IO.File]::WriteAllText($stateFile, ($st | ConvertTo-Json), [System.Text.Encoding]::UTF8)
            }
            Send-JsonResponse $response @{ status = "ok"; message = "Disconnected" }
            continue
        }

        if ($reqPath -eq '/api/tiktok/status') {
            $stateFile = Join-Path $folder "tiktok_live_state.json"
            $stObj = if (Test-Path $stateFile) {
                try { Get-Content $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null }
            } else { $null }
            $isProcRunning = if ($script:tiktokBridgeProc -and -not $script:tiktokBridgeProc.HasExited) { $true } else { [bool]($stObj -and $stObj.connected) }
            $res = @{
                connected = if ($stObj) { [bool]$stObj.connected } else { $false }
                processRunning = $isProcRunning
                username = if ($stObj) { [string]$stObj.username } else { "" }
                roomId = if ($stObj) { [string]$stObj.roomId } else { "" }
                viewerCount = if ($stObj -and $stObj.viewerCount) { [int]$stObj.viewerCount } else { 0 }
                totalLikes = if ($stObj -and $stObj.totalLikes) { [int64]$stObj.totalLikes } else { 0 }
                statusText = if ($stObj) { [string]$stObj.statusText } else { "Offline" }
            }
            Send-JsonResponse $response $res
            continue
        }

        # 1c. Google Authentication & Session Endpoints
        if ($reqPath -eq '/api/auth/google' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $email = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
                $name = if ($data.name) { [string]$data.name.Trim() } else { "Google User" }
                $picture = if ($data.picture) { [string]$data.picture } else { "" }

                if (-not $email -or $email -notmatch '^.+@.+\..+$') {
                    Send-JsonResponse $response @{ success = $false; message = "Valid Google email required" } 400
                    continue
                }

                # Issue token
                $token = "pvz_sess_" + [System.Guid]::NewGuid().ToString("N")
                $sessObj = @{
                    token = $token
                    email = $email
                    name = $name
                    picture = $picture
                    loginTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
                $activeSessions[$token] = $sessObj

                # Persist user registry
                $registry = @{}
                if (Test-Path $usersDbFile) {
                    try {
                        $raw = Get-Content $usersDbFile -Raw -Encoding UTF8 | ConvertFrom-Json
                        foreach ($prop in $raw.PSObject.Properties) {
                            $registry[$prop.Name] = $prop.Value
                        }
                    } catch {}
                }
                $registry[$email] = @{
                    email = $email
                    name = $name
                    picture = $picture
                    lastLogin = (Get-Date).ToString("o")
                }
                [System.IO.File]::WriteAllText($usersDbFile, ($registry | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)

                # Check if this user already has custom triggers configured
                $userCfgPath = Get-UserConfigPath $email
                $isNewUser = (-not (Test-Path $userCfgPath))
                if ($isNewUser) {
                    # Brand new user or first open: Start with COMPLETELY EMPTY customizations!
                    # No zombies and no plants putting there so they customize from scratch!
                    $emptyConfig = @{
                        streamer = @{
                            tiktokUsername = ""
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $false
                            userEmail = $email
                            userName = $name
                            userPicture = $picture
                        }
                        gifts = @()
                        spinners = @()
                    }
                    $emptyJson = $emptyConfig | ConvertTo-Json -Depth 6
                    [System.IO.File]::WriteAllText($userCfgPath, $emptyJson, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $emptyJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                } else {
                    # User returning: activate their existing saved configuration
                    $userJson = [System.IO.File]::ReadAllText($userCfgPath, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $userJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                }

                Send-JsonResponse $response @{
                    success = $true
                    token = $token
                    isNewUser = $isNewUser
                    user = @{
                        email = $email
                        name = $name
                        picture = $picture
                    }
                }
            } catch {
                Send-JsonResponse $response @{ success = $false; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1d. TikTok Authentication Endpoint
        if ($reqPath -eq '/api/auth/tiktok' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $username = if ($data.username) { [string]$data.username.Trim().TrimStart('@') } else { "" }
                $displayName = if ($data.name) { [string]$data.name.Trim() } else { "@$username" }

                if (-not $username) {
                    Send-JsonResponse $response @{ success = $false; message = "TikTok username is required" } 400
                    continue
                }

                $token = "pvz_tk_" + [System.Guid]::NewGuid().ToString("N")
                $avatar = "https://ui-avatars.com/api/?name=" + [System.Uri]::EscapeDataString($username) + "&background=000000&color=25f4ee&size=128&bold=true"
                $email = "tiktok_$($username.ToLower())@tiktok.live"

                $sessObj = @{
                    token = $token
                    email = $email
                    name = $displayName
                    username = $username
                    platform = "tiktok"
                    picture = $avatar
                    loginTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
                $activeSessions[$token] = $sessObj

                # Check if this TikTok streamer already has a config
                $userCfgPath = Get-UserConfigPath $email
                $isNewUser = (-not (Test-Path $userCfgPath))

                if ($isNewUser) {
                    # Clean empty workspace for new TikTok streamer
                    $emptyConfig = @{
                        streamer = @{
                            tiktokUsername = $username
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $true
                            userEmail = $email
                            userName = $displayName
                            userPicture = $avatar
                            platform = "tiktok"
                        }
                        gifts = @()
                        spinners = @()
                    }
                    $emptyJson = $emptyConfig | ConvertTo-Json -Depth 6
                    [System.IO.File]::WriteAllText($userCfgPath, $emptyJson, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $emptyJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                } else {
                    $userJson = [System.IO.File]::ReadAllText($userCfgPath, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $userJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                }

                # Automatically connect live bridge
                Start-TikTokBridge $username

                Send-JsonResponse $response @{
                    success = $true
                    token = $token
                    isNewUser = $isNewUser
                    user = $sessObj
                }
            } catch {
                Send-JsonResponse $response @{ success = $false; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1e. Network & Host Resolver Endpoint (Resolves LAN IP for 2-PC / OBS Setup)
        if ($reqPath -eq '/api/network/ip') {
            $localIp = "127.0.0.1"
            try {
                $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" }
                if ($ips) {
                    $localIp = ($ips | Select-Object -First 1).IPAddress
                }
            } catch {}
            Send-JsonResponse $response @{
                ip = $localIp
                port = $port
                localhost = "http://localhost:$port"
                networkUrl = "http://${localIp}:$port"
            }
            continue
        }

        if ($reqPath -eq '/api/auth/session' -and $request.HttpMethod -eq 'GET') {
            $authHeader = $request.Headers["Authorization"]
            $token = ""
            if ($authHeader -and $authHeader -match 'Bearer\s+(.+)') {
                $token = $matches[1].Trim()
            } elseif ($request.QueryString['token']) {
                $token = $request.QueryString['token']
            }

            if ($token -and $activeSessions.ContainsKey($token)) {
                Send-JsonResponse $response @{
                    authenticated = $true
                    user = $activeSessions[$token]
                }
            } else {
                Send-JsonResponse $response @{
                    authenticated = $false
                    message = "Unauthenticated: Sign in with Google to continue"
                } 401
            }
            continue
        }

        if ($reqPath -eq '/api/auth/logout' -and $request.HttpMethod -eq 'POST') {
            $authHeader = $request.Headers["Authorization"]
            $token = ""
            if ($authHeader -and $authHeader -match 'Bearer\s+(.+)') {
                $token = $matches[1].Trim()
            } elseif ($request.QueryString['token']) {
                $token = $request.QueryString['token']
            }
            if ($token -and $activeSessions.ContainsKey($token)) {
                $activeSessions.Remove($token)
            }
            Send-JsonResponse $response @{ success = $true; message = "Signed out" }
            continue
        }

        # 2. Config Get / Save (Per-User Isolated)
        if ($reqPath -eq '/api/config') {
            $userParam = $request.QueryString['user']
            $targetPath = Get-UserConfigPath $userParam

            if ($request.HttpMethod -eq 'GET') {
                if (-not (Test-Path $targetPath)) {
                    # Auto-initialize empty configuration for new user
                    $emptyConfig = @{
                        streamer = @{
                            tiktokUsername = ""
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $false
                            userEmail = if ($userParam) { $userParam } else { "" }
                        }
                        gifts = @()
                        spinners = @()
                    }
                    $emptyJson = $emptyConfig | ConvertTo-Json -Depth 6
                    [System.IO.File]::WriteAllText($targetPath, $emptyJson, [System.Text.Encoding]::UTF8)
                    Send-JsonResponse $response $emptyJson
                    continue
                }
                $content = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
                try {
                    $parsedCfg = $content | ConvertFrom-Json
                    if ($parsedCfg -and $parsedCfg.gifts -and -not ($parsedCfg.gifts | Where-Object { [string]$_.id -eq "3" })) {
                        $card3Obj = [PSCustomObject]@{
                            id = "3"
                            giftName = "Total Likes"
                            giftId = ""
                            coins = 0
                            icon = "images/trig_7.svg"
                            unitIcon = "images/game-icons/pvz/spawn_ultimatehorse.webp"
                            actionType = "zombie"
                            command = "spawn_ultimatehorse"
                            label = "Spawn UltimateHorse"
                            amount = 20
                            enabled = $true
                            likeThreshold = 50000
                            commands = @([PSCustomObject]@{
                                name = "Commands #1"
                                command = "spawn_ultimatehorse"
                                label = "Spawn UltimateHorse"
                                icon = "images/game-icons/pvz/spawn_ultimatehorse.webp"
                                actionType = "zombie"
                                amount = 1
                            })
                            functionName = "spawn summon horse"
                            repetition = 20
                            delay = 0
                            interval = 100
                            repetitionMultiplier = $true
                            hideInOverlay = $false
                            triggerType = "likes_all"
                            triggerValue = "50000"
                            platform = "tiktok"
                            availableFor = "Anyone"
                        }
                        $gList = [System.Collections.ArrayList]@($parsedCfg.gifts)
                        $gList.Insert([Math]::Min(2, $gList.Count), $card3Obj)
                        $parsedCfg.gifts = $gList
                        $content = $parsedCfg | ConvertTo-Json -Depth 10
                    }
                } catch {}
                Send-JsonResponse $response $content
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                [System.IO.File]::WriteAllText($targetPath, $body, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $body, [System.Text.Encoding]::UTF8)
                if (-not $userParam -and (Test-Path $userConfigsFolder)) {
                    Get-ChildItem -Path $userConfigsFolder -Filter "*_config.json" | ForEach-Object {
                        try { [System.IO.File]::WriteAllText($_.FullName, $body, [System.Text.Encoding]::UTF8) } catch {}
                    }
                }
                Sync-ConfigToCards
                AddEventLog @{ type = "config_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
                Send-JsonResponse $response @{ status = "ok"; message = "Config saved and cards synchronized" }
                continue
            }
        }

        # 2b. Import Starter Template Preset
        if ($reqPath -eq '/api/config/template' -and $request.HttpMethod -eq 'POST') {
            $userParam = $request.QueryString['user']
            $targetPath = Get-UserConfigPath $userParam
            $srcTemplate = if (Test-Path $templateConfigFile) { $templateConfigFile } else { $configFile }
            if (Test-Path $srcTemplate) {
                $templateContent = [System.IO.File]::ReadAllText($srcTemplate, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($targetPath, $templateContent, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $templateContent, [System.Text.Encoding]::UTF8)
                Sync-ConfigToCards
                Send-JsonResponse $response @{ status = "ok"; message = "Starter template loaded successfully" }
            } else {
                Send-JsonResponse $response @{ status = "error"; message = "Template not found" } 404
            }
            continue
        }

        # 3. Units Catalog
        if ($reqPath -eq '/api/catalog') {
            $content = if (Test-Path $catalogFile) { [System.IO.File]::ReadAllText($catalogFile, [System.Text.Encoding]::UTF8) } else { "{}" }
            Send-JsonResponse $response $content
            continue
        }

        # 3b. Leaderboard API: Get rankings
        if ($reqPath -eq '/api/leaderboard') {
            $type = if ($request.QueryString['type']) { $request.QueryString['type'] } else { "all" }
            $count = if ($request.QueryString['count']) { [int]$request.QueryString['count'] } else { 10 }

            if ($type -eq "all") {
                $resObj = @{
                    likes = @(Get-LeaderboardTop "likes" $count)
                    coins = @(Get-LeaderboardTop "coins" $count)
                    donators = @(Get-LeaderboardTop "coins" $count)
                    settings = $script:leaderboardSettings
                }
            } elseif ($type -eq "likes") {
                $resObj = @{ data = @(Get-LeaderboardTop "likes" $count); settings = $script:leaderboardSettings }
            } elseif ($type -eq "coins" -or $type -eq "donators") {
                $resObj = @{ data = @(Get-LeaderboardTop "coins" $count); settings = $script:leaderboardSettings }
            } else {
                $resObj = @{ data = @(); settings = $script:leaderboardSettings }
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 3c. Leaderboard Settings API
        if ($reqPath -eq '/api/leaderboard/settings' -or $reqPath -eq '/api/leaderboard/config') {
            if ($request.HttpMethod -eq 'GET') {
                Send-JsonResponse $response $script:leaderboardSettings
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $newSettings = $body | ConvertFrom-Json
                    $script:leaderboardSettings = $newSettings
                    Save-LeaderboardSettings $newSettings
                    AddEventLog @{ type = "leaderboard_settings_update"; settings = $newSettings }
                    Send-JsonResponse $response @{ status = "ok"; message = "Leaderboard settings saved" }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        # 3d. Leaderboard Reset
        if ($reqPath -eq '/api/leaderboard/reset' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $resetType = if ($data.type) { $data.type } else { "all" }

            if ($resetType -eq "likes" -or $resetType -eq "all") {
                $script:leaderboard | Add-Member -NotePropertyName likes -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            if ($resetType -eq "coins" -or $resetType -eq "donators" -or $resetType -eq "all") {
                $script:leaderboard | Add-Member -NotePropertyName coins -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            if ($resetType -eq "all") {
                $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            Save-Leaderboard
            AddEventLog @{ type = "leaderboard_reset"; resetType = $resetType }
            Send-JsonResponse $response @{ status = "ok"; message = "Leaderboard reset: $resetType" }
            continue
        }

        # 3e. Leaderboard Test / Mock Generator
        if ($reqPath -eq '/api/leaderboard/test' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = if ($body) { $body | ConvertFrom-Json } else { @{} }
            $testType = if ($data.type) { $data.type } else { "all" }
            $sampleNames = @("Wolfich", "Stasie", "ShadowNinja", "SakuraQueen", "GamerPro99", "LuckyStar", "LunaCat", "DragonSlayer", "PixelKing", "MysticRose")
            $mockAvatars = @(
                "images/game-icons/pvz/spawn_ultimatecattail.webp",
                "images/game-icons/pvz/ultimate_gold_gargantuar.webp",
                "images/game-icons/pvz/spawn_gatlingpea.webp",
                "images/game-icons/pvz/spawn_cherrybomb.webp",
                "images/game-icons/pvz/spawn_repeater.webp",
                "images/game-icons/pvz/spawn_peashooter.webp",
                "images/game-icons/pvz/spawn_sunflower.webp",
                "images/game-icons/pvz/spawn_wallnut.webp",
                "images/game-icons/pvz/spawn_snowpea.webp",
                "images/game-icons/pvz/spawn_chomper.webp"
            )

            if ($testType -eq "single") {
                $u = if ($data.username) { $data.username } else { "TopSupporter" }
                $v = if ($data.value) { [int]$data.value } else { 50 }
                $av = if ($data.avatar) { $data.avatar } else { $mockAvatars[0] }
                $t = if ($data.target) { $data.target } else { "coins" }
                if ($t -eq "likes") {
                    Update-LeaderboardLikes $u $v $av
                } else {
                    Update-LeaderboardCoins $u $v $av
                }
            } else {
                $cValues = @(2540, 1820, 1250, 890, 640, 420, 310, 200, 150, 90)
                $lValues = @(15420, 11200, 8900, 6400, 4800, 3200, 2100, 1500, 950, 500)
                for ($idx = 0; $idx -lt 10; $idx++) {
                    $nm = $sampleNames[$idx]
                    $av = $mockAvatars[$idx % $mockAvatars.Count]
                    if ($testType -eq "all" -or $testType -eq "coins" -or $testType -eq "donators") {
                        Update-LeaderboardCoins $nm $cValues[$idx] $av
                    }
                    if ($testType -eq "all" -or $testType -eq "likes") {
                        Update-LeaderboardLikes $nm $lValues[$idx] $av
                    }
                }
            }
            AddEventLog @{ type = "leaderboard_test"; testType = $testType }
            Send-JsonResponse $response @{ status = "ok"; message = "Leaderboard test data populated" }
            continue
        }

        # 4. Trigger Game Action
        if ($reqPath -eq '/api/game/trigger') {
            $body = ReadRequestBody $request

            $data = $body | ConvertFrom-Json
            $actionType = if ($data.actionType) { $data.actionType } else { "custom" }
            $command = $data.command
            $amount = if ($data.amount) { [int]$data.amount } else { 1 }
            $username = if ($data.username) { $data.username } else { "Streamer" }
            $repetition = if ($data.repetition) { [int]$data.repetition } else { 1 }
            $delay = if ($data.delay) { [int]$data.delay } else { 0 }
            $interval = if ($data.interval) { [int]$data.interval } else { 100 }
            $hideInOverlay = ($data.hideInOverlay -eq $true -or $data.hideInOverlay -eq "true")

            $exec = SendToPvZGame $actionType $command $amount $username "" $repetition $delay $interval
            
            $logEntry = @{
                type = "game_trigger"
                label = if ($data.label) { $data.label } else { $command }
                command = $command
                actionType = $actionType
                amount = $amount
                username = $username
                hideInOverlay = $hideInOverlay
                success = $exec.success
            }
            AddEventLog $logEntry

            Send-JsonResponse $response $exec
            continue
        }

        # 5. Events Polling (Real-time feed for Overlay & Dashboard)
        if ($reqPath -eq '/api/events') {
            $since = 0
            if ($request.QueryString['since']) {
                $since = [int64]$request.QueryString['since']
            }

            $recent = @()
            $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            
            foreach ($item in $eventsList) {
                if ($item.timestamp -gt $since) {
                    $recent += $item
                }
            }

            $resObj = @{
                serverTime = $now
                events = $recent
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 6. Test Button Trigger (Fires to game + notifies overlay)
        if ($reqPath -eq '/api/test') {
            $body = ReadRequestBody $request

            $data = $body | ConvertFrom-Json
            $eventType = if ($data.type) { $data.type } else { "gift" }
            $label = if ($data.label) { $data.label } else { "Test Action" }
            $command = $data.command
            $actionType = if ($data.actionType) { $data.actionType } else { "zombie" }
            $amount = if ($data.amount) { [int]$data.amount } else { 1 }
            $username = if ($data.username) { $data.username } else { "TestGifter" }
            $icon = if ($data.icon) { $data.icon } else { "" }
            $coins = if ($data.coins) { [int]$data.coins } else { 1 }
            $repetition = if ($data.repetition) { [int]$data.repetition } else { 1 }
            $delay = if ($data.delay) { [int]$data.delay } else { 0 }
            $interval = if ($data.interval) { [int]$data.interval } else { 100 }
            $hideInOverlay = ($data.hideInOverlay -eq $true -or $data.hideInOverlay -eq "true")

            $exec = @{ success = $true }
            $isSpinnerTest = ($actionType -eq "spinner" -or $command -eq "spin_wheel" -or ($command -and $command -match "spinner_") -or $data.spinnerId)

            if ($isSpinnerTest) {
                $cfg = LoadConfig
                $targetSpinner = $null
                $spId = if ($data.spinnerId) { [string]$data.spinnerId } elseif ($command -match 'spinner_.*') { [string]$command } else { "" }
                if ($cfg -and $cfg.spinners) {
                    if ($spId) {
                        $targetSpinner = $cfg.spinners | Where-Object { [string]$_.id -eq $spId } | Select-Object -First 1
                    }
                    if (-not $targetSpinner) {
                        $targetSpinner = $cfg.spinners[0]
                    }
                } elseif ($cfg -and $cfg.spinner) {
                    $targetSpinner = $cfg.spinner
                }

                $slices = if ($targetSpinner -and $targetSpinner.slices) { $targetSpinner.slices } else { @() }
                $pickedSlice = $null
                if ($slices.Count -gt 0) {
                    $totalW = 0.0
                    foreach ($s in $slices) {
                        $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                        $totalW += $w
                    }
                    if ($totalW -le 0) { $totalW = 100.0 }
                    $rnd = (Get-Random -Minimum 0.0 -Maximum $totalW)
                    $curW = 0.0
                    foreach ($s in $slices) {
                        $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                        $curW += $w
                        if ($rnd -le $curW) { $pickedSlice = $s; break }
                    }
                    if (-not $pickedSlice) { $pickedSlice = $slices[0] }
                }

                $spName = if ($targetSpinner -and $targetSpinner.name) { $targetSpinner.name } else { "Spinner" }
                $targetSpId = if ($targetSpinner -and $targetSpinner.id) { [string]$targetSpinner.id } else { "1" }
                $testAvatar = if ($data.avatar) { [string]$data.avatar } else { "images/default_avatar.svg" }

                # Update score ONLY if number slice (never for plants or zombies)
                if ($pickedSlice) {
                    $isNumSlice = ($pickedSlice.isNumber -eq $true) -or 
                                  ($pickedSlice.actionType -eq "score") -or 
                                  ($pickedSlice.delta -ne $null -and $pickedSlice.delta -ne 0) -or 
                                  ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$')

                    if ($pickedSlice.actionType -eq "plant" -or $pickedSlice.actionType -eq "zombie" -or $pickedSlice.actionType -eq "power") {
                        $isNumSlice = $false
                    }

                    if ($isNumSlice) {
                        $deltaVal = 0
                        if ($pickedSlice.delta -ne $null) {
                            $deltaVal = [int]$pickedSlice.delta
                        } elseif ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$') {
                            $sign = if ($matches[1] -eq '-') { -1 } else { 1 }
                            $deltaVal = $sign * [int]$matches[2]
                        }
                        if ($deltaVal -ne 0) {
                            Update-WinWidgetScore $deltaVal "spinner" $pickedSlice.label
                        }
                    }
                }

                Add-SpinnerHistoryRecord $username $testAvatar $pickedSlice $spName $targetSpId

                AddEventLog @{
                    type = "spin_result"
                    label = if ($pickedSlice) { "$($spName) - $($pickedSlice.label)" } else { "$($spName) Spin" }
                    username = $username
                    slice = $pickedSlice
                    spinnerId = $targetSpId
                    spinnerName = $spName
                    slices = $slices
                    icon = $icon
                    hideInOverlay = $hideInOverlay
                    success = $true
                }
            } elseif ($command -and $command -ne "spin_wheel") {
                $exec = SendToPvZGame $actionType $command $amount $username "" $repetition $delay $interval

                # If this gift card also has a bound spinner (e.g. Heart Me -> Plus/Minus Spinner), trigger the spinner too!
                $cfg = LoadConfig
                $tGiftName = if ($data.giftName) { [string]$data.giftName } else { [string]$label }
                $tGiftId = if ($data.giftId) { [string]$data.giftId } else { "" }
                $matchedCardSpinner = $null
                if ($cfg -and $cfg.spinners) {
                    foreach ($sp in $cfg.spinners) {
                        if (-not $sp.enabled) { continue }
                        if ($tGiftId -and $sp.giftId -and ([string]$sp.giftId.Trim() -eq $tGiftId.Trim())) {
                            $matchedCardSpinner = $sp; break
                        }
                        if ($tGiftName -and $sp.giftName) {
                            $cleanReq = ($tGiftName -replace '[^a-zA-Z0-9]','').ToLower()
                            $cleanSp = ($sp.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                            if ($cleanReq -eq $cleanSp -or $sp.giftName.Trim().ToLower() -eq $tGiftName.Trim().ToLower()) {
                                $matchedCardSpinner = $sp; break
                            }
                        }
                    }
                }

                if ($matchedCardSpinner) {
                    $slices = if ($matchedCardSpinner.slices) { $matchedCardSpinner.slices } else { @() }
                    $pickedSlice = $null
                    if ($slices.Count -gt 0) {
                        $totalW = 0.0
                        foreach ($s in $slices) {
                            $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                            $totalW += $w
                        }
                        if ($totalW -le 0) { $totalW = 100.0 }
                        $rnd = (Get-Random -Minimum 0.0 -Maximum $totalW)
                        $curW = 0.0
                        foreach ($s in $slices) {
                            $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                            $curW += $w
                            if ($rnd -le $curW) { $pickedSlice = $s; break }
                        }
                        if (-not $pickedSlice) { $pickedSlice = $slices[0] }
                    }

                    $spName = if ($matchedCardSpinner.name) { $matchedCardSpinner.name } else { "Spinner" }
                    $targetSpId = if ($matchedCardSpinner.id) { [string]$matchedCardSpinner.id } else { "1" }
                    $testAvatar = if ($data.avatar) { [string]$data.avatar } else { "images/default_avatar.svg" }

                    if ($pickedSlice) {
                        $isNumSlice = ($pickedSlice.isNumber -eq $true) -or 
                                      ($pickedSlice.actionType -eq "score") -or 
                                      ($pickedSlice.delta -ne $null -and $pickedSlice.delta -ne 0) -or 
                                      ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$')

                        if ($pickedSlice.actionType -eq "plant" -or $pickedSlice.actionType -eq "zombie" -or $pickedSlice.actionType -eq "power") {
                            $isNumSlice = $false
                        }

                        if ($isNumSlice) {
                            $deltaVal = 0
                            if ($pickedSlice.delta -ne $null) {
                                $deltaVal = [int]$pickedSlice.delta
                            } elseif ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$') {
                                $sign = if ($matches[1] -eq '-') { -1 } else { 1 }
                                $deltaVal = $sign * [int]$matches[2]
                            }
                            if ($deltaVal -ne 0) {
                                Update-WinWidgetScore $deltaVal "spinner" $pickedSlice.label
                            }
                        }
                    }

                    Add-SpinnerHistoryRecord $username $testAvatar $pickedSlice $spName $targetSpId

                    AddEventLog @{
                        type = "spin_result"
                        label = if ($pickedSlice) { "$($spName) - $($pickedSlice.label)" } else { "$($spName) Spin" }
                        username = $username
                        slice = $pickedSlice
                        spinnerId = $targetSpId
                        spinnerName = $spName
                        slices = $slices
                        icon = if ($matchedCardSpinner.giftIcon) { $matchedCardSpinner.giftIcon } else { $icon }
                        hideInOverlay = $hideInOverlay
                        success = $true
                    }
                }
            }

            # If it corresponds to a card id, increment counts
            if ($data.cardId -and $counts.Contains($data.cardId)) {
                $counts[$data.cardId] = [int]$counts[$data.cardId] + $amount
                SaveCounts
            }

            $logEntry = @{
                type = $eventType
                label = $label
                giftName = if ($data.giftName) { $data.giftName } else { $label }
                giftId = if ($data.giftId) { $data.giftId } else { $data.cardId }
                cardId = $data.cardId
                command = $command
                actionType = $actionType
                amount = $amount
                username = $username
                icon = $icon
                coins = $coins
                hideInOverlay = $hideInOverlay
                success = $exec.success
            }
            AddEventLog $logEntry

            $resObj = @{
                status = "ok"
                gameExecuted = $exec.success
                event = $logEntry
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 6.9 Reset Spinners to Default Authentic 2 Spinners
        if ($reqPath -eq '/api/spinners/reset' -and $reqMethod -eq 'POST') {
            try {
                & ".\init_spinners.ps1" | Out-Null
                $refreshed = LoadConfig
                Send-JsonResponse $response @{ success = $true; spinners = $refreshed.spinners }
            } catch {
                Send-JsonResponse $response @{ success = $false; error = $_.Exception.Message } 500
            }
            continue
        }

        # 6.95. Win / Lose Widget Endpoints
        if ($reqPath -eq '/api/win-widget') {
            if ($request.HttpMethod -eq 'GET') {
                Send-JsonResponse $response (Load-WinWidget)
                continue
            }
            if ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $data = $body | ConvertFrom-Json
                    $cur = Load-WinWidget
                    if ($data.wins -ne $null) { $cur.wins = [int]$data.wins }
                    if ($data.losses -ne $null) { $cur.losses = [int]$data.losses }
                    if ($data.score -ne $null) {
                        $cur.score = [int]$data.score
                    } else {
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    if ($data.target -ne $null) { $cur.target = [int]$data.target }
                    if ($data.autoWin -ne $null) { $cur.autoWin = [bool]$data.autoWin }
                    if ($data.enabled -ne $null) { $cur.enabled = [bool]$data.enabled }
                    if ($data.label) { $cur.label = [string]$data.label }
                    
                    Save-WinWidget $cur
                    $script:winWidget = $cur

                    AddEventLog @{
                        type = "win_widget_update"
                        score = $cur.score
                        target = $cur.target
                        wins = $cur.wins
                        losses = $cur.losses
                        autoWin = $cur.autoWin
                        enabled = $cur.enabled
                        label = $cur.label
                        reason = "manual_update"
                    }
                    Send-JsonResponse $response $cur
                } catch {
                    Send-JsonResponse $response @{ error = $_.Exception.Message } 400
                }
                continue
            }
        }

        if ($reqPath -eq '/api/win-widget/adjust' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $cur = Load-WinWidget
                $action = if ($data.action) { [string]$data.action } else { "" }
                $delta = if ($data.delta -ne $null) { [int]$data.delta } else { 0 }

                # Server-side 350ms debounce: prevent double point increments from duplicate listeners/shortcuts
                $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                if ($action -and $script:lastWinAdjustAction -eq $action -and ($nowMs - $script:lastWinAdjustTime) -lt 350) {
                    Send-JsonResponse $response (Load-WinWidget)
                    continue
                }
                $script:lastWinAdjustTime = $nowMs
                $script:lastWinAdjustAction = $action

                switch ($action) {
                    "win" {
                        $cur.wins = [int]$cur.wins + 1
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "lose" {
                        $cur.losses = [int]$cur.losses + 1
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "win_plus" {
                        $cur.wins = [int]$cur.wins + 1
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "win_minus" {
                        $cur.wins = [Math]::Max(0, [int]$cur.wins - 1)
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "lose_plus" {
                        $cur.losses = [int]$cur.losses + 1
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "lose_minus" {
                        $cur.losses = [Math]::Max(0, [int]$cur.losses - 1)
                        $cur.score = [int]$cur.wins - [int]$cur.losses
                    }
                    "reset" {
                        $cur.score = 0
                        $cur.wins = 0
                        $cur.losses = 0
                    }
                    default {
                        if ($delta -ne 0) {
                            if ($delta -gt 0) {
                                $cur.wins = [int]$cur.wins + $delta
                            } else {
                                $cur.losses = [int]$cur.losses + [Math]::Abs($delta)
                            }
                            $cur.score = [int]$cur.wins - [int]$cur.losses
                        }
                    }
                }

                Save-WinWidget $cur
                $script:winWidget = $cur

                AddEventLog @{
                    type = "win_widget_update"
                    score = $cur.score
                    target = $cur.target
                    wins = $cur.wins
                    losses = $cur.losses
                    delta = $delta
                    action = $action
                    enabled = $cur.enabled
                    reason = "adjust"
                }
                Send-JsonResponse $response $cur
            } catch {
                Send-JsonResponse $response @{ error = $_.Exception.Message } 400
            }
            continue
        }

        # 6b. Spinner History Endpoints (GET, toggle, clear)
        if ($reqPath -eq '/api/spinner-history') {
            if ($request.HttpMethod -eq 'GET') {
                if (-not $script:spinnerHistory) { $script:spinnerHistory = Load-SpinnerHistory }
                Send-JsonResponse $response $script:spinnerHistory
                continue
            }
        }

        if ($reqPath -eq '/api/spinner-history/toggle' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            if (-not $script:spinnerHistory) { $script:spinnerHistory = Load-SpinnerHistory }
            try {
                $data = $body | ConvertFrom-Json
                if ($data.enabled -ne $null) {
                    $script:spinnerHistory.enabled = [bool]$data.enabled
                } else {
                    $script:spinnerHistory.enabled = -not [bool]$script:spinnerHistory.enabled
                }
                Save-SpinnerHistory $script:spinnerHistory
                AddEventLog @{ type = "spinner_history_update"; enabled = [bool]$script:spinnerHistory.enabled; history = $script:spinnerHistory.history }
                Send-JsonResponse $response $script:spinnerHistory
            } catch {
                Send-JsonResponse $response $script:spinnerHistory
            }
            continue
        }

        if ($reqPath -eq '/api/spinner-history/clear' -and $request.HttpMethod -eq 'POST') {
            if (-not $script:spinnerHistory) { $script:spinnerHistory = Load-SpinnerHistory }
            $script:spinnerHistory.history = @()
            Save-SpinnerHistory $script:spinnerHistory
            AddEventLog @{ type = "spinner_history_update"; history = @(); enabled = [bool]$script:spinnerHistory.enabled }
            Send-JsonResponse $response $script:spinnerHistory
            continue
        }

        # 7. Spin Lucky Wheel / Reel (Multi-Spinner Support)
        if ($reqPath -eq '/api/spin') {
            if ($request.HttpMethod -eq 'POST') { [void](ReadRequestBody $request) }
            $config = LoadConfig
            $spinnerId = $request.QueryString['spinnerId']
            $groupId = $request.QueryString['groupId']
            
            $targetSpinner = $null
            if ($config -and $config.spinners -and $config.spinners.Count -gt 0) {
                if ($spinnerId) {
                    $targetSpinner = $config.spinners | Where-Object { [string]$_.id -eq [string]$spinnerId } | Select-Object -First 1
                } elseif ($groupId) {
                    $targetSpinner = $config.spinners | Where-Object { [string]$_.groupId -eq [string]$groupId } | Select-Object -First 1
                }
                if (-not $targetSpinner) {
                    $targetSpinner = $config.spinners[0]
                }
            } elseif ($config -and $config.spinner) {
                $targetSpinner = $config.spinner
            }

            $slices = if ($targetSpinner -and $targetSpinner.slices) { $targetSpinner.slices } else { @() }
            $pickedSlice = $null
            if ($slices.Count -gt 0) {
                $totalWeight = 0.0
                foreach ($s in $slices) {
                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                    $totalWeight += $w
                }
                if ($totalWeight -le 0) { $totalWeight = 100.0 }
                $rnd = (Get-Random -Minimum 0.0 -Maximum $totalWeight)
                $cur = 0.0
                foreach ($s in $slices) {
                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                    $cur += $w
                    if ($rnd -le $cur) {
                        $pickedSlice = $s
                        break
                    }
                }
                if (-not $pickedSlice) { $pickedSlice = $slices[0] }
            }

            $username = if ($request.QueryString['username']) { $request.QueryString['username'] } elseif ($request.QueryString['user']) { $request.QueryString['user'] } else { "User" }
            $cleanUserKey = ($username.ToLower() -replace '[^a-z0-9]', '')
            $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

            # Prevent duplicate spin triggers for the same viewer within 8 seconds
            if ($cleanUserKey -and $script:recentSpins.ContainsKey($cleanUserKey)) {
                $lastSpinTime = [int64]$script:recentSpins[$cleanUserKey]
                if (($nowMs - $lastSpinTime) -lt 8000) {
                    Send-JsonResponse $response @{ status = "ok"; message = "Already spun for this donation" }
                    continue
                }
            }
            $script:recentSpins[$cleanUserKey] = $nowMs

            $avatar = if ($request.QueryString['avatar']) { $request.QueryString['avatar'] } else { "images/default_avatar.svg" }
            $noGame = ($request.QueryString['noGameTrigger'] -eq 'true')
            
            $exec = @{ success = $true }
            $spHide = $false
            if ($pickedSlice -and -not $noGame) {
                if ($pickedSlice.actionType -and $pickedSlice.actionType -ne "score" -and $pickedSlice.command) {
                    $spReps = if ($pickedSlice.repetition) { [int]$pickedSlice.repetition } else { 1 }
                    $spDelay = if ($pickedSlice.delay) { [int]$pickedSlice.delay } else { 0 }
                    $spInterval = if ($pickedSlice.interval) { [int]$pickedSlice.interval } else { 100 }
                    $spHide = ($pickedSlice.hideInOverlay -eq $true -or $pickedSlice.hideInOverlay -eq "true")
                    $exec = SendToPvZGame $pickedSlice.actionType $pickedSlice.command $pickedSlice.amount $username "" $spReps $spDelay $spInterval
                }
            }

            # ONLY update Win Widget if number slice! DO NOT add points for plants or zombies!
            $deltaVal = 0
            $isNumSlice = ($pickedSlice.isNumber -eq $true) -or 
                          ($pickedSlice.actionType -eq "score") -or 
                          ($pickedSlice.delta -ne $null -and $pickedSlice.delta -ne 0) -or 
                          ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$')

            # Plants, zombies, and powers MUST NEVER add points or change score!
            if ($pickedSlice.actionType -eq "plant" -or $pickedSlice.actionType -eq "zombie" -or $pickedSlice.actionType -eq "power") {
                $isNumSlice = $false
            }

            if ($isNumSlice) {
                if ($pickedSlice.delta -ne $null) {
                    $deltaVal = [int]$pickedSlice.delta
                } elseif ($pickedSlice.value -ne $null) {
                    $deltaVal = [int]$pickedSlice.value
                } elseif ($pickedSlice.label -match '^\s*([+-]?)\s*(\d+)\s*$') {
                    $sign = if ($matches[1] -eq '-') { -1 } else { 1 }
                    $deltaVal = $sign * [int]$matches[2]
                }
                if ($deltaVal -ne 0) {
                    Update-WinWidgetScore $deltaVal "spinner_number" $pickedSlice.label
                }
            }

            $spName = if ($targetSpinner -and $targetSpinner.name) { $targetSpinner.name } else { "Spinner" }
            $spDuration = if ($targetSpinner -and $targetSpinner.duration) { [int]$targetSpinner.duration } else { 2500 }
            $spTicks = if ($targetSpinner -and $targetSpinner.ticks) { [int]$targetSpinner.ticks } else { 100 }
            $spPointer = if ($targetSpinner -and $targetSpinner.pointerIcon) { $targetSpinner.pointerIcon } else { "" }

            $logEntry = @{
                type = "spin_result"
                label = if ($pickedSlice) { "$($spName) - Won $($pickedSlice.label)" } else { "$($spName) Spin" }
                slice = $pickedSlice
                spinnerId = if ($targetSpinner) { [string]$targetSpinner.id } else { "1" }
                spinnerName = $spName
                groupId = if ($targetSpinner) { [string]$targetSpinner.groupId } else { "1" }
                duration = $spDuration
                ticks = $spTicks
                pointerIcon = $spPointer
                slices = $slices
                username = $username
                avatar = $avatar
                hideInOverlay = $spHide
                success = $exec.success
            }
            AddEventLog $logEntry

            # Record in Spinner History system
            $targetSpinnerId = if ($targetSpinner -and $targetSpinner.id) { [string]$targetSpinner.id } else { "1" }
            Add-SpinnerHistoryRecord $username $avatar $pickedSlice $spName $targetSpinnerId

            $resObj = @{
                status = "ok"
                winner = $pickedSlice
                spinner = $targetSpinner
                username = $username
                avatar = $avatar
                gameExecuted = $exec.success
                winWidgetScore = $script:winWidget.score
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 8. Webhook for TikTok Live Connector (TikFinity / StreamToEarn / Local)
        if ($reqPath -eq '/api/webhook/tiktok') {
            $body = ReadRequestBody $request

            $config = LoadConfig
            try {
                $payload = $body | ConvertFrom-Json
                
                # Check if it is a gift event
                if ($payload.event -eq "gift") {
                    $giftName = $payload.giftName
                    $giftId = $payload.giftId
                    $repeatCount = if ($payload.repeatCount) { [int]$payload.repeatCount } else { 1 }
                    $user = if ($payload.username) { $payload.username } elseif ($payload.nickname) { $payload.nickname } else { "User" }
                    $avatar = if ($payload.profilePictureUrl) { $payload.profilePictureUrl } elseif ($payload.avatar) { $payload.avatar } elseif ($payload.avatarUrl) { $payload.avatarUrl } else { "images/default_avatar.svg" }
                    $icon = if ($payload.giftPictureUrl) { $payload.giftPictureUrl } else { "" }

                    # LEADERBOARD: Track coins accurately for this gift
                    $giftCoinValue = 0
                    if ($payload.coins -ne $null -and [int]$payload.coins -gt 0) {
                        $giftCoinValue = [int]$payload.coins
                    } elseif ($payload.diamondCount -ne $null -and [int]$payload.diamondCount -gt 0) {
                        $giftCoinValue = [int]$payload.diamondCount * $repeatCount
                    } elseif ($config -and $config.gifts) {
                        $lcGift = $config.gifts | Where-Object { $_.giftId -and ([string]$_.giftId.Trim() -eq [string]$giftId.Trim()) } | Select-Object -First 1
                        if ($lcGift -and $lcGift.coins -and [int]$lcGift.coins -gt 0) {
                            $giftCoinValue = [int]$lcGift.coins * $repeatCount
                        }
                    }

                    if ($giftCoinValue -le 0 -and $script:verifiedGiftsCatalog -and $giftId) {
                        $vg = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq [string]$giftId } | Select-Object -First 1
                        if ($vg -and $vg.coins) {
                            $giftCoinValue = [int]$vg.coins * $repeatCount
                        }
                    }

                    if ($giftCoinValue -le 0) {
                        $giftCoinValue = $repeatCount
                    }
                    Update-LeaderboardCoins $user $giftCoinValue $avatar

                    # 1. Check if gift matches a multi-spinner trigger
                    $matchedSpinner = $null
                    if ($config -and $config.spinners) {
                        foreach ($sp in $config.spinners) {
                            if (-not $sp.enabled) { continue }
                            if ($giftId -and $sp.giftId -and ([string]$sp.giftId.Trim() -eq [string]$giftId.Trim())) {
                                $matchedSpinner = $sp
                                break
                            }
                            if ($giftName -and $sp.giftName) {
                                $cleanReq = ($giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                $cleanSp = ($sp.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                if ($cleanReq -eq $cleanSp -or $sp.giftName.Trim().ToLower() -eq $giftName.Trim().ToLower()) {
                                    $matchedSpinner = $sp
                                    break
                                }
                            }
                        }
                    }

                    if ($matchedSpinner) {
                        # Debounce check: ignore duplicate webhook spins for this user within 3000ms
                        $cleanUserKey = ($user.ToLower() -replace '[^a-z0-9]', '')
                        $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                        if ($cleanUserKey -and $script:recentSpins.ContainsKey($cleanUserKey)) {
                            $lastTime = [int64]$script:recentSpins[$cleanUserKey]
                            if (($nowMs - $lastTime) -lt 3000) {
                                Send-JsonResponse $response @{ status = "ok"; message = "Debounced duplicate spin" }
                                continue
                            }
                        }
                        $script:recentSpins[$cleanUserKey] = $nowMs

                        # Trigger that specific spinner!
                        $spSlices = if ($matchedSpinner.slices) { $matchedSpinner.slices } else { @() }
                        $picked = $null
                        if ($spSlices.Count -gt 0) {
                            $totalWeight = 0.0
                            foreach ($s in $spSlices) {
                                $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                $totalWeight += $w
                            }
                            if ($totalWeight -le 0) { $totalWeight = 100.0 }
                            $rnd = (Get-Random -Minimum 0.0 -Maximum $totalWeight)
                            $cur = 0.0
                            foreach ($s in $spSlices) {
                                $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                $cur += $w
                                if ($rnd -le $cur) {
                                    $picked = $s
                                    break
                                }
                            }
                            if (-not $picked) { $picked = $spSlices[0] }
                        }

                        if ($picked) {
                            if ($picked.actionType -and $picked.actionType -ne "score" -and $picked.command) {
                                # Summon the won unit directly in PvZ Fusion mod!
                                $totalSpawns = [int]($picked.amount) * [Math]::Max(1, $repeatCount)
                                SendToPvZGame $picked.actionType $picked.command $totalSpawns $user | Out-Null
                            }

                            # Auto-adjust Win Widget score ONLY if slice is a number (never for plants or zombies)!
                            $isNumSlice = ($picked.isNumber -eq $true) -or 
                                          ($picked.actionType -eq "score") -or 
                                          ($picked.delta -ne $null -and $picked.delta -ne 0) -or 
                                          ($picked.label -match '^\s*([+-]?)\s*(\d+)\s*$')

                            if ($picked.actionType -eq "plant" -or $picked.actionType -eq "zombie" -or $picked.actionType -eq "power") {
                                $isNumSlice = $false
                            }

                            if ($isNumSlice) {
                                $deltaVal = 0
                                if ($picked.delta -ne $null) {
                                    $deltaVal = [int]$picked.delta
                                } elseif ($picked.value -ne $null) {
                                    $deltaVal = [int]$picked.value
                                } elseif ($picked.label -match '^\s*([+-]?)\s*(\d+)\s*$') {
                                    $sign = if ($matches[1] -eq '-') { -1 } else { 1 }
                                    $deltaVal = $sign * [int]$matches[2]
                                }

                                if ($deltaVal -ne 0) {
                                    Update-WinWidgetScore $deltaVal "tiktok_gift" $picked.label
                                }
                            }
                        }

                        $spName = $matchedSpinner.name
                        $spDuration = if ($matchedSpinner.duration) { [int]$matchedSpinner.duration } else { 2500 }
                        $spTicks = if ($matchedSpinner.ticks) { [int]$matchedSpinner.ticks } else { 100 }

                        # Also execute and increment the matched gift card action (e.g. Card 32: Heart Me -> Spawn Big Sun Nut x50)
                        if ($config -and $config.gifts) {
                            foreach ($g in $config.gifts) {
                                $cardMatch = $false
                                if ($g.enabled -and $g.giftId -and $giftId -and ([string]$g.giftId.Trim() -eq [string]$giftId.Trim())) {
                                    $cardMatch = $true
                                } elseif ($g.enabled -and $g.giftName -and $giftName) {
                                    $cleanG = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    $cleanR = ($giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    if ($cleanG -and $cleanG -eq $cleanR) { $cardMatch = $true }
                                }

                                if ($cardMatch) {
                                    $cardIdStr = [string]$g.id
                                    if ($cardIdStr -and $counts.ContainsKey($cardIdStr)) {
                                        $counts[$cardIdStr] = [int]$counts[$cardIdStr] + $repeatCount
                                        SaveCounts
                                    }

                                    # TRIGGER THE IN-GAME ACTION FOR THIS GIFT CARD (if not a spinner card)!
                                    if ($g.command -and $g.command -ne "spin_wheel" -and $g.actionType -ne "spinner" -and -not ($g.command -match '^spinner_')) {
                                        $totalAmt = [int]$g.amount
                                        $giftReps = if ($g.repetition) { [int]$g.repetition } else { 1 }
                                        if ($g.repetitionMultiplier -eq $true -or $g.repetitionMultiplier -eq "true") {
                                            $giftReps = $giftReps * $repeatCount
                                        } else {
                                            $totalAmt = $totalAmt * $repeatCount
                                        }
                                        $giftDelay = if ($g.delay) { [int]$g.delay } else { 0 }
                                        $giftInterval = if ($g.interval) { [int]$g.interval } else { 100 }
                                        $giftHide = ($g.hideInOverlay -eq $true -or $g.hideInOverlay -eq "true")
                                        SendToPvZGame $g.actionType $g.command $totalAmt $user "" $giftReps $giftDelay $giftInterval | Out-Null
                                        AddEventLog @{
                                            type = "gift"
                                            label = [string]$g.label
                                            command = $g.command
                                            actionType = $g.actionType
                                            amount = $totalAmt
                                            username = $user
                                            icon = if ($g.unitIcon) { $g.unitIcon } else { $icon }
                                            hideInOverlay = $giftHide
                                            noSpinnerTrigger = $true
                                            success = $true
                                        }
                                    }
                                    break
                                }
                            }
                        }

                        AddEventLog @{
                            type = "spin_result"
                            label = "$($spName) - $($picked.label)"
                            username = $user
                            slice = $picked
                            spinnerId = [string]$matchedSpinner.id
                            spinnerName = $spName
                            groupId = [string]$matchedSpinner.groupId
                            duration = $spDuration
                            ticks = $spTicks
                            pointerIcon = $matchedSpinner.pointerIcon
                            slices = $spSlices
                            icon = if ($matchedSpinner.giftIcon) { $matchedSpinner.giftIcon } else { $icon }
                            success = $true
                        }
                        Add-SpinnerHistoryRecord $user $avatar $picked $spName $matchedSpinner.id
                        Send-JsonResponse $response @{ status = "ok"; type = "spin_result"; spinner = $spName }
                        continue
                    }

                    $matchedGift = $null
                    if ($config -and $config.gifts) {
                        # 1. Match by giftId (exact string comparison)
                        if ($giftId) {
                            $strGId = [string]$giftId
                            foreach ($g in $config.gifts) {
                                if ($g.enabled -and $g.giftId -and ([string]$g.giftId.Trim() -eq $strGId.Trim())) {
                                    $matchedGift = $g
                                    break
                                }
                            }
                        }
                        # 2. Match by giftName
                        if (-not $matchedGift -and $giftName -and $giftName -ne "Gift") {
                            $cleanReqName = ($giftName -replace '[^a-zA-Z0-9]','').ToLower()
                            foreach ($g in $config.gifts) {
                                if ($g.enabled -and $g.giftName) {
                                    $cleanCfgName = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    if ($cleanCfgName -and ($cleanCfgName -eq $cleanReqName -or $g.giftName.Trim().ToLower() -eq $giftName.Trim().ToLower())) {
                                        $matchedGift = $g
                                        break
                                    }
                                }
                            }
                        }
                    }

                    if ($matchedGift) {
                        # Increment card count in $counts so overlay updates in real-time!
                        $cardIdStr = [string]$matchedGift.id
                        if ($cardIdStr -and $counts.ContainsKey($cardIdStr)) {
                            $counts[$cardIdStr] = [int]$counts[$cardIdStr] + $repeatCount
                            SaveCounts
                        }

                        if ($matchedGift.command -eq "spin_wheel") {
                            $slices = if ($config.spinner -and $config.spinner.slices) { $config.spinner.slices } else { @() }
                            $picked = $null
                            if ($slices.Count -gt 0) {
                                $totalWeight = 0.0
                                foreach ($s in $slices) {
                                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                    $totalWeight += $w
                                }
                                if ($totalWeight -le 0) { $totalWeight = 100.0 }
                                $rnd = (Get-Random -Minimum 0.0 -Maximum $totalWeight)
                                $cur = 0.0
                                foreach ($s in $slices) {
                                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                    $cur += $w
                                    if ($rnd -le $cur) {
                                        $picked = $s
                                        break
                                    }
                                }
                                if (-not $picked) { $picked = $slices[0] }
                            }
                            if ($picked) {
                                $spReps = if ($picked.repetition) { [int]$picked.repetition } else { 1 }
                                $spDelay = if ($picked.delay) { [int]$picked.delay } else { 0 }
                                $spInterval = if ($picked.interval) { [int]$picked.interval } else { 100 }
                                $spHide = ($picked.hideInOverlay -eq $true -or $picked.hideInOverlay -eq "true")
                                if ($picked.actionType -and $picked.actionType -ne "score" -and $picked.command) {
                                    SendToPvZGame $picked.actionType $picked.command $picked.amount $user "" $spReps $spDelay $spInterval | Out-Null
                                }

                                # Update Win Widget score ONLY on number slices (never on plants/zombies)!
                                $isNumSlice = ($picked.isNumber -eq $true) -or 
                                              ($picked.actionType -eq "score") -or 
                                              ($picked.delta -ne $null -and $picked.delta -ne 0) -or 
                                              ($picked.label -match '^\s*([+-]?)\s*(\d+)\s*$')

                                if ($picked.actionType -eq "plant" -or $picked.actionType -eq "zombie" -or $picked.actionType -eq "power") {
                                    $isNumSlice = $false
                                }

                                if ($isNumSlice) {
                                    $tkDelta = 0
                                    if ($picked.delta -ne $null) {
                                        $tkDelta = [int]$picked.delta
                                    } elseif ($picked.label -match '^\s*([+-]?)\s*(\d+)\s*$') {
                                        $tkSign = if ($matches[1] -eq '-') { -1 } else { 1 }
                                        $tkDelta = $tkSign * [int]$matches[2]
                                    }
                                    if ($tkDelta -ne 0) {
                                        Update-WinWidgetScore $tkDelta "tiktok_spin" $picked.label
                                    }
                                }

                                AddEventLog @{ type = "spin_result"; label = "Lucky Wheel: $($picked.label)"; username = $user; avatar = $avatar; slice = $picked; icon = $icon; hideInOverlay = $spHide }
                                Add-SpinnerHistoryRecord $user $avatar $picked "Lucky Wheel" "wheel"
                            }
                        } else {
                            $totalAmt = [int]$matchedGift.amount
                            $giftReps = if ($matchedGift.repetition) { [int]$matchedGift.repetition } else { 1 }
                            if ($matchedGift.repetitionMultiplier -eq $true -or $matchedGift.repetitionMultiplier -eq "true") {
                                $giftReps = $giftReps * $repeatCount
                            } else {
                                $totalAmt = $totalAmt * $repeatCount
                            }
                            $giftDelay = if ($matchedGift.delay) { [int]$matchedGift.delay } else { 0 }
                            $giftInterval = if ($matchedGift.interval) { [int]$matchedGift.interval } else { 100 }
                            $giftHide = ($matchedGift.hideInOverlay -eq $true -or $matchedGift.hideInOverlay -eq "true")
                            SendToPvZGame $matchedGift.actionType $matchedGift.command $totalAmt $user "" $giftReps $giftDelay $giftInterval | Out-Null
                            AddEventLog @{ type = "gift"; label = $matchedGift.label; command = $matchedGift.command; amount = $totalAmt; username = $user; icon = $icon; hideInOverlay = $giftHide }
                        }
                    } else {
                        # FALLBACK: Universal unconfigured gift trigger
                        # MUST NEVER spawn Rose's unit (spawn_ultimate_football_zombie)!
                        $fallbackCount = if ($repeatCount -gt 0) { $repeatCount } else { 1 }
                        if ($fallbackCount -ge 10) {
                            $spawnAmt = [Math]::Min($fallbackCount, 5)
                            SendToPvZGame "zombie" "ultimate_gold_gargantuar" $spawnAmt $user | Out-Null
                            AddEventLog @{ type = "gift"; label = if ($giftName -and $giftName -ne "Gift") { "$giftName (Gold Gargantuar)" } else { "Gift (Gold Gargantuar)" }; command = "ultimate_gold_gargantuar"; amount = $spawnAmt; username = $user; icon = $icon }
                        } else {
                            SendToPvZGame "zombie" "spawn_bucketzombie" $fallbackCount $user | Out-Null
                            AddEventLog @{ type = "gift"; label = if ($giftName -and $giftName -ne "Gift") { "$giftName (Buckethead Zombie)" } else { "Gift (Buckethead Zombie)" }; command = "spawn_bucketzombie"; amount = $fallbackCount; username = $user; icon = $icon }
                        }
                    }
                }
                # Chat event: Team Battle selection (!plants vs !zombies)
                elseif ($payload.event -eq "chat" -or $payload.type -eq "chat" -or $payload.comment) {
                    $user = if ($payload.username) { $payload.username } else { "Viewer" }
                    $comment = if ($payload.comment) { [string]$payload.comment } elseif ($payload.text) { [string]$payload.text } else { "" }
                    $cLower = $comment.Trim().ToLower()

                    if ($cLower -match '!plant(s)?|team\s*plant(s)?') {
                        $userTeams[$user] = "plants"
                        AddEventLog @{
                            type = "team_join"
                            label = "$user joined Team Plants!"
                            team = "plants"
                            username = $user
                            icon = "images/game-icons/pvz/spawn_ultimatecattail.webp"
                        }
                    } elseif ($cLower -match '!zombie(s)?|team\s*zombie(s)?') {
                        $userTeams[$user] = "zombies"
                        AddEventLog @{
                            type = "team_join"
                            label = "$user joined Team Zombies!"
                            team = "zombies"
                            username = $user
                            icon = "images/game-icons/pvz/ultimate_gold_gargantuar.webp"
                        }
                    }
                }
                # Like event: Team Battle (50 likes) + Total Stream Likes milestone (e.g. 57K)
                elseif ($payload.event -eq "like" -or $payload.type -eq "like") {
                    $likes = if ($payload.likeCount) { [int]$payload.likeCount } else { 1 }
                    $user = if ($payload.username) { $payload.username } else { "Viewer" }
                    $avatar = if ($payload.profilePictureUrl) { $payload.profilePictureUrl } elseif ($payload.avatar) { $payload.avatar } elseif ($payload.avatarUrl) { $payload.avatarUrl } else { "" }
                    $totalLikes = if ($payload.totalLikeCount) { [int64]$payload.totalLikeCount } elseif ($payload.totalLikes) { [int64]$payload.totalLikes } else { 0 }

                    # LEADERBOARD: Track likes
                    Update-LeaderboardLikes $user $likes $avatar

                    $card1 = $config.gifts | Where-Object { [string]$_.id -eq "1" }
                    $card2 = $config.gifts | Where-Object { [string]$_.id -eq "2" }
                    $card3 = $config.gifts | Where-Object { [string]$_.id -eq "3" }

                    $thresh1 = if ($card1 -and $card1.likeThreshold) { [int]$card1.likeThreshold } else { 50 }
                    $thresh2 = if ($card2 -and $card2.likeThreshold) { [int]$card2.likeThreshold } else { 50 }
                    $thresh3 = 500
                    if ($card3) {
                        if ($card3.likeThreshold -and [int64]$card3.likeThreshold -gt 0) {
                            $thresh3 = [int64]$card3.likeThreshold
                        } elseif ($card3.triggerValue -and [int64]$card3.triggerValue -gt 0) {
                            $thresh3 = [int64]$card3.triggerValue
                        }
                    }

                    # If viewer has no team, automatically put them on Team Plants and do NOT summon zombies
                    if (-not $userTeams.ContainsKey($user) -or [string]::IsNullOrWhiteSpace($userTeams[$user])) {
                        $userTeams[$user] = "plants"
                    }

                    $team = $userTeams[$user]

                    # 1. Team Plants Likes (Default for all unassigned users + explicit !plants)
                    if ($team -eq "plants") {
                        $teamPlantsLikes += $likes
                        while ($teamPlantsLikes -ge $thresh1) {
                            $teamPlantsLikes -= $thresh1
                            if ($card1 -and $card1.enabled) {
                                SendToPvZGame $card1.actionType $card1.command $card1.amount $user | Out-Null
                                if ($counts.Contains("1")) { $counts["1"] = [int]$counts["1"] + 1; SaveCounts }
                                AddEventLog @{
                                    type = "team_battle_spawn"
                                    label = "Team Plants ($thresh1 Likes) -> $($card1.label)"
                                    team = "plants"
                                    command = $card1.command
                                    amount = $card1.amount
                                    username = $user
                                    icon = $card1.unitIcon
                                    success = $true
                                }
                            }
                        }
                    }
                    # 2. Team Zombies Likes (ONLY for users who explicitly joined Team Zombies with !zombies)
                    elseif ($team -eq "zombies") {
                        $teamZombiesLikes += $likes
                        while ($teamZombiesLikes -ge $thresh2) {
                            $teamZombiesLikes -= $thresh2
                            if ($card2 -and $card2.enabled) {
                                SendToPvZGame $card2.actionType $card2.command $card2.amount $user | Out-Null
                                if ($counts.Contains("2")) { $counts["2"] = [int]$counts["2"] + 1; SaveCounts }
                                AddEventLog @{
                                    type = "team_battle_spawn"
                                    label = "Team Zombies ($thresh2 Likes) -> $($card2.label)"
                                    team = "zombies"
                                    command = $card2.command
                                    amount = $card2.amount
                                    username = $user
                                    icon = $card2.unitIcon
                                    success = $true
                                }
                            }
                        }
                    }

                    # 4. Total Stream Likes Milestone check (supports Card 3 and any custom "All Likes" / total likes card)
                    if ($totalLikes -gt 0 -and $config -and $config.gifts) {
                        $script:lastStreamTotalLikes = $totalLikes
                        $allLikesCards = @($config.gifts | Where-Object { 
                            $_.enabled -ne $false -and (
                                [string]$_.id -eq "3" -or 
                                $_.triggerType -eq "likes_all" -or 
                                $_.triggerType -eq "total_likes" -or 
                                $_.eventType -eq "total_likes" -or 
                                ($_.giftName -and $_.giftName -match "total\s*likes|all\s*likes")
                            )
                        })

                        foreach ($alc in $allLikesCards) {
                            $alcId = [string]$alc.id
                            $alcThresh = 50000
                            if ($alc.likeThreshold -and [int64]$alc.likeThreshold -gt 0) {
                                $alcThresh = [int64]$alc.likeThreshold
                            } elseif ($alc.triggerValue -and [int64]$alc.triggerValue -gt 0) {
                                $alcThresh = [int64]$alc.triggerValue
                            }

                            if ($alcThresh -le 0) { continue }

                            if (-not $script:cardMilestones.ContainsKey($alcId)) {
                                if ($totalLikes -ge $alcThresh) {
                                    $prevMilestone = [Math]::Floor($totalLikes / $alcThresh) * $alcThresh
                                    $script:cardMilestones[$alcId] = [int64]($prevMilestone - $alcThresh)
                                } else {
                                    $script:cardMilestones[$alcId] = [int64]0
                                }
                            }

                            $lastMilestone = [int64]$script:cardMilestones[$alcId]
                            if ($totalLikes -ge ($lastMilestone + $alcThresh)) {
                                $milestonesCrossed = [Math]::Floor(($totalLikes - $lastMilestone) / $alcThresh)
                                if ($milestonesCrossed -gt 0) {
                                    $script:cardMilestones[$alcId] = $lastMilestone + ($milestonesCrossed * $alcThresh)

                                    $alcCmd = if ($alc.command) { [string]$alc.command } else { "spawn_ultimatehorse" }
                                    $alcAction = if ($alc.actionType) { [string]$alc.actionType } else { "zombie" }
                                    $alcReps = if ($alc.repetition -and [int]$alc.repetition -gt 0) { [int]$alc.repetition } elseif ($alc.amount -and [int]$alc.amount -gt 0) { [int]$alc.amount } else { 1 }
                                    $alcAmt = if ($alc.amount -and [int]$alc.amount -gt 0) { [int]$alc.amount } else { $alcReps }
                                    $alcDelay = if ($alc.delay) { [int]$alc.delay } else { 0 }
                                    $alcInterval = if ($alc.interval) { [int]$alc.interval } else { 100 }
                                    $alcHide = ($alc.hideInOverlay -eq $true -or $alc.hideInOverlay -eq "true")
                                    $alcLabel = if ($alc.functionName) { [string]$alc.functionName } elseif ($alc.label) { [string]$alc.label } else { $alcCmd }
                                    $alcIcon = if ($alc.unitIcon) { [string]$alc.unitIcon } elseif ($alc.icon) { [string]$alc.icon } else { "images/game-icons/pvz/spawn_ultimatehorse.webp" }

                                    # Trigger the summon sequence in PvZ Fusion mod!
                                    SendToPvZGame $alcAction $alcCmd $alcAmt "StreamGoal" "" $alcReps $alcDelay $alcInterval | Out-Null

                                    if ($counts.ContainsKey($alcId)) {
                                        $counts[$alcId] = [int]$counts[$alcId] + $milestonesCrossed
                                        SaveCounts
                                    }

                                    AddEventLog @{
                                        type = "total_likes_milestone"
                                        label = "Stream Goal reached: $($totalLikes) Likes! Summoned $alcLabel ($alcReps x)"
                                        command = $alcCmd
                                        actionType = $alcAction
                                        amount = $alcReps
                                        username = "StreamGoal"
                                        icon = $alcIcon
                                        hideInOverlay = $alcHide
                                        success = $true
                                    }
                                }
                            }
                        }
                    }
                }
                # Follow event: Card 4 (Anti-Spam: Strictly 1 follow per viewer per day or per live)
                elseif ($payload.event -eq "follow" -or $payload.type -eq "follow") {
                    $user = if ($payload.username) { [string]$payload.username } else { "New Follower" }
                    $userId = if ($payload.userId) { [string]$payload.userId } else { "" }
                    $uniqueId = if ($payload.uniqueId) { [string]$payload.uniqueId } else { "" }
                    
                    $cleanUser = ($user.ToLower() -replace '[^a-z0-9]', '')
                    $cleanUnique = ($uniqueId.ToLower() -replace '[^a-z0-9]', '')
                    
                    $trackerKey = if ($userId) { "uid_$userId" } elseif ($cleanUnique) { "u_$cleanUnique" } else { "u_$cleanUser" }
                    
                    if ($trackerKey -and $script:sessionFollowers.ContainsKey($trackerKey)) {
                        Write-Host ">>> [FOLLOW IGNORED] @$user already followed today / in this live session." -ForegroundColor Yellow
                        Send-JsonResponse $response @{ status = "ok"; message = "Follow already processed for this user today / in this live session" }
                        continue
                    }
                    
                    # Also check by clean username as fallback
                    if ($cleanUser -and $cleanUser -ne "viewer" -and $cleanUser -ne "newfollower" -and $script:sessionFollowers.ContainsKey("u_$cleanUser")) {
                        Write-Host ">>> [FOLLOW IGNORED] @$user already followed today / in this live session." -ForegroundColor Yellow
                        Send-JsonResponse $response @{ status = "ok"; message = "Follow already processed for this user today / in this live session" }
                        continue
                    }

                    if ($trackerKey) {
                        $script:sessionFollowers[$trackerKey] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                    if ($cleanUser) {
                        $script:sessionFollowers["u_$cleanUser"] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                    Save-DailyFollowersTable

                    $followCards = @($config.gifts | Where-Object { 
                        $_.enabled -and ([string]$_.id -eq "4" -or $_.triggerType -eq "follow" -or $_.eventType -eq "follow" -or $_.giftName -match "^follow(er)?$")
                    })
                    
                    if ($followCards.Count -gt 0) {
                        foreach ($fc in $followCards) {
                            $fcAmt = if ($fc.amount) { [int]$fc.amount } else { 1 }
                            $fcReps = if ($fc.repetition) { [int]$fc.repetition } else { 1 }
                            $fcDelay = if ($fc.delay) { [int]$fc.delay } else { 0 }
                            $fcInt = if ($fc.interval) { [int]$fc.interval } else { 100 }
                            SendToPvZGame $fc.actionType $fc.command $fcAmt $user "" $fcReps $fcDelay $fcInt | Out-Null
                            
                            $fcIdStr = [string]$fc.id
                            if ($counts.Contains($fcIdStr)) { $counts[$fcIdStr] = [int]$counts[$fcIdStr] + 1; SaveCounts }
                            
                            AddEventLog @{
                                type = "follow"
                                label = "New Follower: $user -> Summoned $($fc.label)"
                                command = $fc.command
                                amount = $fcAmt
                                username = $user
                                icon = $fc.unitIcon
                                success = $true
                            }
                        }
                    }
                    Send-JsonResponse $response @{ status = "ok"; message = "Follow processed" }
                    continue
                }
                # Share event
                elseif ($payload.event -eq "share" -or $payload.type -eq "share") {
                    $user = if ($payload.username) { $payload.username } else { "Sharer" }
                    if ($config -and $config.socialTriggers -and $config.socialTriggers.share.enabled) {
                        $trig = $config.socialTriggers.share
                        SendToPvZGame $trig.actionType $trig.command $trig.amount $user | Out-Null
                        AddEventLog @{ type = "share"; label = $trig.label; amount = $trig.amount; username = $user }
                    }
                }
            } catch {}

            Send-JsonResponse $response @{ status = "ok" }
            continue
        }

        # 9. Legacy API: Counts
        if ($reqPath -eq '/api/counts') {
            $json = $counts | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = 'application/json; charset=utf-8'
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 10. Live Stream / Overlay API: Donate / Increment count AND trigger in-game spawn!
        if ($reqPath -eq '/api/donate') {
            $id = $request.QueryString['id']
            $amt = 1
            if ($request.QueryString['amount']) {
                $amt = [int]$request.QueryString['amount']
            }

            if ($id -and $counts.Contains($id)) {
                $counts[$id] = [int]$counts[$id] + $amt
                SaveCounts
            }

            # TRIGGER IN-GAME SPAWN FOR THIS CARD!
            $allCards = LoadCards
            $targetCard = $null
            foreach ($c in $allCards) {
                if ([string]$c.id -eq [string]$id) {
                    $targetCard = $c
                    break
                }
            }

            if ($targetCard) {
                $rep = if ($targetCard.repetition) { [int]$targetCard.repetition } else { 1 }
                $totalSpawns = $rep * $amt
                $cCmd = $targetCard.commands
                $gLabel = if ($targetCard.giftName) { $targetCard.giftName } else { "Card $id" }
                $actType = if ($cCmd -match 'spawnplant') { "plant" } else { "zombie" }

                $exec = SendToPvZGame $actType $cCmd $totalSpawns "Viewer"

                AddEventLog @{
                    type = "card_donation"
                    cardId = $id
                    label = "$gLabel ($($targetCard.funcName))"
                    command = $cCmd
                    amount = $totalSpawns
                    username = "StreamViewer"
                    icon = $targetCard.funcImg
                    success = $exec.success
                }
            }

            $json = $counts | ConvertTo-Json
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = 'application/json; charset=utf-8'
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            continue
        }

        # 11. Reset API
        if ($reqPath -eq '/api/reset') {
            foreach ($k in @($counts.Keys)) {
                $counts[$k] = 0
            }
            SaveCounts
            Send-JsonResponse $response @{ status = "ok" }
            continue
        }

        # ----------------- STATIC FILES ----------------- #
        $localRelPath = $reqPath.TrimStart('/').Replace('/', '\')
        $filePath = Join-Path $folder $localRelPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            try {
                $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
                $response.Headers.Add("Pragma", "no-cache")
                $response.Headers.Add("Expires", "0")
            } catch {}
            if ($request.HttpMethod -ne "HEAD") {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $response.Close()
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found: $reqPath")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            $response.Close()
        }
    } catch {
        Write-Host "Server Exception: $_" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 50
    }
}
