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
$permissionsFile = Join-Path $folder "permissions_registry.json"

function Load-Permissions {
    $defaultPerms = @{
        admin = ""
        admins = @()
        editors = @()
    }
    if (Test-Path $permissionsFile) {
        try {
            $raw = Get-Content $permissionsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $adm = if ($raw.admin) { [string]$raw.admin.Trim().ToLower() } else { "" }
            $adms = @()
            if ($raw.admins) {
                foreach ($a in $raw.admins) { if ($a) { $adms += [string]$a.Trim().ToLower() } }
            }
            if ($adm -and -not ($adms -contains $adm)) { $adms += $adm }
            $edts = @()
            if ($raw.editors) {
                foreach ($e in $raw.editors) { if ($e) { $edts += [string]$e.Trim().ToLower() } }
            }
            return @{
                admin = $adm
                admins = $adms
                editors = $edts
            }
        } catch {}
    }
    return $defaultPerms
}

function Save-Permissions($permsObj) {
    try {
        $json = $permsObj | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($permissionsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Get-UserRole($email) {
    if (-not $email -or [string]::IsNullOrWhiteSpace($email)) {
        return "viewer"
    }
    $clean = $email.Trim().ToLower()
    # Primary Admin guarantee for jaylouvipinosa7
    if ($clean -eq "jaylouvipinosa7@gmail.com" -or $clean.Contains("jaylouvipinosa7")) {
        return "admin"
    }
    $perms = Load-Permissions
    if ($clean -eq $perms.admin -or ($perms.admins -contains $clean)) {
        return "admin"
    }
    if ($perms.editors -contains $clean) {
        return "editor"
    }
    return "viewer"
}

function Get-CallerUser($request) {
    $authHeader = $request.Headers["Authorization"]
    $token = ""
    if ($authHeader -and $authHeader -match 'Bearer\s+(.+)') {
        $token = $matches[1].Trim()
    } elseif ($request.QueryString['token']) {
        $token = $request.QueryString['token']
    } elseif ($request.Headers["X-Auth-Token"]) {
        $token = $request.Headers["X-Auth-Token"]
    }
    if ($token -and $activeSessions.ContainsKey($token)) {
        return $activeSessions[$token]
    }
    return $null
}

function Get-CallerRole($request) {
    # Check if request originated from local host (the streamer's desktop)
    $remoteIp = if ($request.RemoteEndPoint) { $request.RemoteEndPoint.Address.ToString() } else { "127.0.0.1" }
    $isLocal = ($remoteIp -eq "127.0.0.1" -or $remoteIp -eq "::1" -or $request.Url.Host -eq "localhost" -or $request.Url.Host -eq "127.0.0.1")

    $user = Get-CallerUser $request
    if ($user -and $user.email) {
        $role = Get-UserRole $user.email
        if ($role -ne "viewer") { return $role }
        if ($isLocal) { return "admin" }
        return $role
    }
    $emailParam = $request.QueryString['user']
    if ($emailParam) {
        $role = Get-UserRole $emailParam
        if ($role -ne "viewer") { return $role }
        if ($isLocal) { return "admin" }
        return $role
    }
    if ($isLocal) {
        return "admin"
    }
    return "viewer"
}

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

function Resolve-AutoCorrectGift($gName, $gId) {
    if (-not $script:verifiedGiftsCatalog) {
        $vgFile = Join-Path $folder "tiktok_gifts_verified.json"
        if (Test-Path $vgFile) {
            try { $script:verifiedGiftsCatalog = Get-Content $vgFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
        }
    }
    if (-not $script:verifiedGiftsCatalog) { return $null }

    # 1. Match by Gift ID
    if ($gId) {
        $strId = [string]$gId.Trim()
        $found = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq $strId } | Select-Object -First 1
        if ($found) { return $found }
    }

    # 2. Match by Gift Name (Exact or Normalized)
    if ($gName) {
        $clean = ($gName -replace '[^a-zA-Z0-9]','').ToLower()
        if ($clean) {
            # Exact clean match
            $found = $script:verifiedGiftsCatalog | Where-Object {
                (($_.name -replace '[^a-zA-Z0-9]','').ToLower()) -eq $clean
            } | Select-Object -First 1
            if ($found) { return $found }

            # Known Popular Gift Aliases
            $aliasId = $null
            if ($clean -match '^(heart|heartme|hart|hartme|puso)$') { $aliasId = '7934' }
            elseif ($clean -match '^(rose|roze|rosas)$') { $aliasId = '5655' }
            elseif ($clean -match '^(icecream|icecreamcone|cone)$') { $aliasId = '5827' }
            elseif ($clean -match '^(perfume|perfum|parfum)$') { $aliasId = '5658' }
            elseif ($clean -match '^(doughnut|donut|doughnuts|donuts)$') { $aliasId = '5879' }
            elseif ($clean -match '^(hat|mustache|mustash|hatandmustache)$') { $aliasId = '6363' }
            elseif ($clean -match '^(tiktok|tt)$') { $aliasId = '5269' }
            elseif ($clean -match '^(fingerheart)$') { $aliasId = '5487' }
            elseif ($clean -match '^(confetti)$') { $aliasId = '5659' }
            elseif ($clean -match '^(swan)$') { $aliasId = '5660' }
            elseif ($clean -match '^(lion)$') { $aliasId = '6369' }
            elseif ($clean -match '^(galaxy)$') { $aliasId = '5828' }
            elseif ($clean -match '^(universe|tiktokuniverse)$') { $aliasId = '6059' }
            elseif ($clean -match '^(cap|baseballcap)$') { $aliasId = '5944' }
            elseif ($clean -match '^(sunglasses|glasses)$') { $aliasId = '5942' }

            if ($aliasId) {
                $found = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq $aliasId } | Select-Object -First 1
                if ($found) { return $found }
            }

            # Prefix or substring match
            $found = $script:verifiedGiftsCatalog | Where-Object {
                $vNorm = ($_.name -replace '[^a-zA-Z0-9]','').ToLower()
                $vNorm -and ($vNorm.StartsWith($clean) -or $clean.StartsWith($vNorm) -or $vNorm.Contains($clean) -or $clean.Contains($vNorm))
            } | Select-Object -First 1
            if ($found) { return $found }
        }
    }
    return $null
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
    if (-not $username) { $username = "Viewer" }
    $cleanUser = $username.Trim()
    if (-not $script:leaderboard.likes) { $script:leaderboard | Add-Member -NotePropertyName likes -NotePropertyValue @{} -Force }
    $current = 0
    if ($script:leaderboard.likes.PSObject -and $script:leaderboard.likes.PSObject.Properties[$cleanUser]) {
        $current = [int]$script:leaderboard.likes.$cleanUser
    }
    $newTotal = [int]($current + $likeCount)
    $script:leaderboard.likes | Add-Member -NotePropertyName $cleanUser -NotePropertyValue $newTotal -Force
    if ($avatar -and $avatar.Trim()) {
        if (-not $script:leaderboard.avatars) { $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue @{} -Force }
        $script:leaderboard.avatars | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([string]$avatar.Trim()) -Force
    }
    Save-Leaderboard
    AddEventLog @{
        type = "leaderboard_update"
        updateType = "likes"
        username = $cleanUser
        likeCount = $likeCount
        total = $newTotal
        avatar = $avatar
    }
}

function Update-LeaderboardCoins([string]$username, [int]$coinValue, [string]$avatar) {
    if (-not $username -or $username -eq "StreamGoal") { $username = "RENEarn_Viewer" }
    $cleanUser = $username.Trim()
    if (-not $script:leaderboard.coins) { $script:leaderboard | Add-Member -NotePropertyName coins -NotePropertyValue @{} -Force }
    $current = 0
    if ($script:leaderboard.coins.PSObject -and $script:leaderboard.coins.PSObject.Properties[$cleanUser]) {
        $current = [int]$script:leaderboard.coins.$cleanUser
    }
    $newTotal = [int]($current + $coinValue)
    $script:leaderboard.coins | Add-Member -NotePropertyName $cleanUser -NotePropertyValue $newTotal -Force
    if ($avatar -and $avatar.Trim()) {
        if (-not $script:leaderboard.avatars) { $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue @{} -Force }
        $script:leaderboard.avatars | Add-Member -NotePropertyName $cleanUser -NotePropertyValue ([string]$avatar.Trim()) -Force
    }
    Save-Leaderboard
    AddEventLog @{
        type = "leaderboard_update"
        updateType = "coins"
        username = $cleanUser
        coinValue = $coinValue
        total = $newTotal
        avatar = $avatar
    }
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

# ==================== REGION DETECTION & CONFIG ====================
$regionConfigFile = Join-Path $folder "region_config.json"

function Load-RegionConfig {
    if (Test-Path $regionConfigFile) {
        try {
            $raw = Get-Content $regionConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        autoDetect = $true
        selectedRegion = "PH"
        detectedRegion = [PSCustomObject]@{
            countryCode = "PH"
            countryName = "Philippines"
            flag = "🇵🇭"
            timezone = "Asia/Manila"
            detectedMethod = "locale_fallback"
        }
    }
}

function Detect-SystemRegion {
    # 1. IP Geolocation with timeout 2.5s
    try {
        $ipRes = Invoke-RestMethod -Uri "http://ip-api.com/json" -TimeoutSec 2.5 -ErrorAction Stop
        if ($ipRes -and $ipRes.countryCode) {
            $flagMap = @{ "PH"="🇵🇭"; "US"="🇺🇸"; "ID"="🇮🇩"; "MY"="🇲🇾"; "VN"="🇻🇳"; "TH"="🇹🇭"; "SG"="🇸🇬"; "GB"="🇬🇧"; "BR"="🇧🇷"; "CA"="🇨🇦"; "AU"="🇦🇺"; "JP"="🇯🇵"; "KR"="🇰🇷"; "DE"="🇩🇪"; "FR"="🇫🇷" }
            $cCode = [string]$ipRes.countryCode.ToUpper()
            $fl = if ($flagMap.ContainsKey($cCode)) { $flagMap[$cCode] } else { "🌐" }
            return [PSCustomObject]@{
                countryCode = $cCode
                countryName = [string]$ipRes.country
                flag = $fl
                timezone = [string]$ipRes.timezone
                detectedMethod = "ip_geolocation"
                ip = [string]$ipRes.query
                updatedAt = [DateTime]::UtcNow.ToString("o")
            }
        }
    } catch {}

    # 2. Fallback to OS Culture / TimeZone
    try {
        $cult = [System.Globalization.CultureInfo]::CurrentCulture.Name
        $tz = [System.TimeZoneInfo]::Local.Id
        $cCode = "PH"
        $cName = "Philippines"
        $flag = "🇵🇭"
        if ($cult -match '-([A-Z]{2})$') {
            $cCode = $matches[1]
            try { $cName = [System.Globalization.RegionInfo]::new($cCode).DisplayName } catch { $cName = $cCode }
        } elseif ($tz -match 'Manila|Singapore|Taipei|China') {
            $cCode = "PH"
            $cName = "Philippines"
        }
        return [PSCustomObject]@{
            countryCode = $cCode
            countryName = $cName
            flag = $flag
            timezone = $tz
            detectedMethod = "system_locale"
            updatedAt = [DateTime]::UtcNow.ToString("o")
        }
    } catch {}

    return [PSCustomObject]@{
        countryCode = "PH"
        countryName = "Philippines"
        flag = "🇵🇭"
        timezone = "Asia/Manila"
        detectedMethod = "default_fallback"
        updatedAt = [DateTime]::UtcNow.ToString("o")
    }
}

$script:regionConfig = Load-RegionConfig

function Save-RegionConfig($cfg) {
    try {
        $json = $cfg | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($regionConfigFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

# ==================== CUSTOM COMMUNITY GIFTS ====================
$customCommunityGiftsFile = Join-Path $folder "custom_community_gifts.json"

function Load-CustomCommunityGifts {
    if (Test-Path $customCommunityGiftsFile) {
        try {
            $raw = Get-Content $customCommunityGiftsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) {
                if ($raw -is [System.Array]) { return @($raw) }
                return @($raw)
            }
        } catch {}
    }
    return @()
}

function Save-CustomCommunityGifts($giftsList) {
    try {
        $json = $giftsList | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($customCommunityGiftsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:customCommunityGifts = Load-CustomCommunityGifts

# ==================== ON-SCREEN TRIGGER COUNTER ====================
$triggerCounterFile = Join-Path $folder "trigger_counter_state.json"

function Load-TriggerCounterState {
    if (Test-Path $triggerCounterFile) {
        try {
            $raw = Get-Content $triggerCounterFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        totalTriggers = 0
        streak = 0
        lastTriggerTime = 0
        goal = 100
        goalTitle = "Mega Wave Boss"
        gifts = [PSCustomObject]@{}
        recentTriggers = @()
    }
}

function Save-TriggerCounterState {
    try {
        $json = $script:triggerCounterState | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($triggerCounterFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:triggerCounterState = Load-TriggerCounterState

function Record-TriggerEvent([string]$giftName, [string]$giftId, [int]$count, [string]$user, [string]$avatar, [string]$icon, [string]$commandLabel) {
    if (-not $script:triggerCounterState) {
        $script:triggerCounterState = Load-TriggerCounterState
    }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $safeCount = [Math]::Max(1, $count)
    $script:triggerCounterState.totalTriggers = [int]$script:triggerCounterState.totalTriggers + $safeCount

    # Streak combo logic: combo stays alive if within 15 seconds
    $lastTime = if ($script:triggerCounterState.lastTriggerTime) { [int64]$script:triggerCounterState.lastTriggerTime } else { 0 }
    if (($now - $lastTime) -lt 15000) {
        $script:triggerCounterState.streak = [int]$script:triggerCounterState.streak + 1
    } else {
        $script:triggerCounterState.streak = 1
    }
    $script:triggerCounterState.lastTriggerTime = $now

    # Gift bucket
    $cleanName = if ($giftName) { $giftName } else { "Gift $giftId" }
    $gKey = ($cleanName -replace '[^a-zA-Z0-9]', '_').ToLower()
    if (-not $script:triggerCounterState.gifts) {
        $script:triggerCounterState | Add-Member -NotePropertyName gifts -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    $curGiftObj = $null
    if ($script:triggerCounterState.gifts.PSObject -and $script:triggerCounterState.gifts.PSObject.Properties[$gKey]) {
        $curGiftObj = $script:triggerCounterState.gifts.$gKey
    }
    $prevCount = if ($curGiftObj -and $curGiftObj.count) { [int]$curGiftObj.count } else { 0 }
    $newCount = $prevCount + $safeCount
    $giftRecord = [PSCustomObject]@{
        name = $cleanName
        giftId = [string]$giftId
        count = $newCount
        icon = if ($icon) { $icon } else { "images/trig_7.svg" }
        lastGifter = $user
    }
    $script:triggerCounterState.gifts | Add-Member -NotePropertyName $gKey -NotePropertyValue $giftRecord -Force

    # Recent triggers list
    $recentList = @()
    if ($script:triggerCounterState.recentTriggers) {
        $recentList = @($script:triggerCounterState.recentTriggers)
    }
    $trigItem = [PSCustomObject]@{
        id = "$now`_$((Get-Random -Minimum 1000 -Maximum 9999))"
        username = $user
        avatar = if ($avatar) { $avatar } else { "images/default_avatar.svg" }
        giftName = $cleanName
        giftIcon = if ($icon) { $icon } else { "images/trig_7.svg" }
        commandLabel = $commandLabel
        count = $safeCount
        timestamp = $now
    }
    $recentList += $trigItem
    if ($recentList.Count -gt 12) {
        $recentList = $recentList | Select-Object -Last 12
    }
    $script:triggerCounterState.recentTriggers = $recentList

    Save-TriggerCounterState

    # Broadcast SSE for real-time overlay animation
    AddEventLog @{
        type = "trigger_counter"
        totalTriggers = $script:triggerCounterState.totalTriggers
        streak = $script:triggerCounterState.streak
        latest = $trigItem
    }
}

# ==================== GIFT JAR OVERLAY TRACKING ====================
$jarSettingsFile = Join-Path $folder "jar_settings.json"
$jarStateFile = Join-Path $folder "jar_state.json"

function Load-JarSettings {
    if (Test-Path $jarSettingsFile) {
        try {
            $raw = Get-Content $jarSettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        skin = "mason"
        customSkinUrl = ""
        jarScale = 1.0
        maxCapacity = 80
        countMode = "items"
        gravity = 1.0
        bounciness = 0.45
        friction = 0.1
        giftScale = 1.0
        soundEnabled = $true
        soundVolume = 0.5
        showGifterBadge = $true
        showCounterBar = $true
        resetBehavior = "explosion"
        triggerGameEventOnFull = $true
        gameCommandOnFull = "spawn_fire_cattail"
        jarTitle = "TikTok Gift Jar"
        themeGlow = "rgba(56, 189, 248, 0.4)"
    }
}

function Save-JarSettings($settings) {
    try {
        $json = $settings | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($jarSettingsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Load-JarState {
    if (Test-Path $jarStateFile) {
        try {
            $raw = Get-Content $jarStateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        currentCount = 0
        totalCoins = 0
        isFull = $false
        lastDropTime = 0
        recentDrops = @()
    }
}

function Save-JarState($st) {
    try {
        $json = $st | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($jarStateFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:jarSettings = Load-JarSettings
$script:jarState = Load-JarState

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
$script:recentGiftDeduplication = [System.Collections.Hashtable]::Synchronized(@{})
$script:heartMeUsersToday = [System.Collections.Hashtable]::Synchronized(@{})
$script:heartMeUsersDate = [DateTime]::UtcNow.ToString("yyyyMMdd")

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

function Get-MasterTemplateConfig {
    $tmplGifts = @()
    $tmplSpinners = @()
    $tmplOverlay = $null
    
    if (Test-Path $templateConfigFile) {
        try {
            $tmpl = Get-Content $templateConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($tmpl -and $tmpl.gifts -and $tmpl.gifts.Count -gt 0) { $tmplGifts = @($tmpl.gifts) }
            if ($tmpl -and $tmpl.spinners -and $tmpl.spinners.Count -gt 0) { $tmplSpinners = @($tmpl.spinners) }
            if ($tmpl -and $tmpl.overlay) { $tmplOverlay = $tmpl.overlay }
        } catch {}
    }
    
    if (($tmplGifts.Count -eq 0 -or $tmplSpinners.Count -eq 0) -and (Test-Path $configFile)) {
        try {
            $baseCfg = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($tmplGifts.Count -eq 0 -and $baseCfg -and $baseCfg.gifts) { $tmplGifts = @($baseCfg.gifts) }
            if ($tmplSpinners.Count -eq 0 -and $baseCfg -and $baseCfg.spinners) { $tmplSpinners = @($baseCfg.spinners) }
            if (-not $tmplOverlay -and $baseCfg -and $baseCfg.overlay) { $tmplOverlay = $baseCfg.overlay }
        } catch {}
    }
    
    return @{
        gifts = $tmplGifts
        spinners = $tmplSpinners
        overlay = $tmplOverlay
    }
}

function LoadConfig($optionalUser = "") {
    $targetPath = $configFile
    if ($optionalUser -and -not [string]::IsNullOrWhiteSpace($optionalUser)) {
        $up = Get-UserConfigPath $optionalUser
        if (Test-Path $up) { $targetPath = $up }
    } elseif ($script:tiktokConnectedUser) {
        $up = Get-UserConfigPath $script:tiktokConnectedUser
        if (Test-Path $up) { $targetPath = $up }
    }

    if ((Test-Path $configFile) -and (Test-Path $targetPath) -and ($targetPath -ne $configFile)) {
        try {
            $cItem = Get-Item $configFile
            $tItem = Get-Item $targetPath
            if ($cItem.LastWriteTime -gt $tItem.LastWriteTime) {
                $targetPath = $configFile
            }
        } catch {}
    }

    $cfg = $null
    if (Test-Path $targetPath) {
        try {
            $cfg = Get-Content $targetPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {}
    }

    # If resolved config has no gifts, check latest user config in user_configs folder
    if ((-not $cfg -or -not $cfg.gifts -or $cfg.gifts.Count -eq 0) -and (Test-Path $userConfigsFolder)) {
        $latest = Get-ChildItem -Path $userConfigsFolder -Filter "*_config.json" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($latest) {
            try {
                $altCfg = Get-Content $latest.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($altCfg -and $altCfg.gifts -and $altCfg.gifts.Count -gt 0) {
                    $cfg = $altCfg
                }
            } catch {}
        }
    }

    # CRITICAL: If config still has no gifts (e.g. newly downloaded app or fresh user), auto-populate from master template!
    if (-not $cfg -or -not $cfg.gifts -or $cfg.gifts.Count -eq 0) {
        $master = Get-MasterTemplateConfig
        if ($master.gifts -and $master.gifts.Count -gt 0) {
            if (-not $cfg) {
                $cfg = [PSCustomObject]@{
                    streamer = [PSCustomObject]@{ tiktokUsername = ""; soundEnabled = $true; volume = 0.6; autoConnect = $true }
                    overlay = if ($master.overlay) { $master.overlay } else { [PSCustomObject]@{ zoom = 1; columns = 1; showGoals = $true; alertDuration = 4000; soundAlerts = $true; wheelPosition = "center" } }
                    gifts = $master.gifts
                    spinners = $master.spinners
                }
            } else {
                $cfg | Add-Member -MemberType NoteProperty -Name gifts -Value $master.gifts -Force
                if (-not $cfg.spinners -or $cfg.spinners.Count -eq 0) {
                    $cfg | Add-Member -MemberType NoteProperty -Name spinners -Value $master.spinners -Force
                }
            }
        }
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

    # Ensure spinners are NEVER empty so Reel & Number Card system work for all users
    if ($cfg -and (-not $cfg.spinners -or $cfg.spinners.Count -eq 0)) {
        $master = Get-MasterTemplateConfig
        if ($master.spinners -and $master.spinners.Count -gt 0) {
            $cfg | Add-Member -MemberType NoteProperty -Name spinners -Value $master.spinners -Force
        }
    }

    # Ensure Heart Me spinner (spinner_plusminus) is mapped to Heart Me (7934) and not obsolete Rose (5655)
    if ($cfg -and $cfg.spinners) {
        foreach ($sp in $cfg.spinners) {
            if ($sp.id -eq "spinner_plusminus") {
                $spGId = if ($sp.PSObject.Properties['giftId']) { [string]$sp.giftId } else { "" }
                $spGName = if ($sp.PSObject.Properties['giftName']) { [string]$sp.giftName } else { "" }
                if ($spGId -eq "5655" -or $spGName -eq "Rose" -or [string]::IsNullOrWhiteSpace($spGId)) {
                    if ($sp.PSObject.Properties['giftId']) { $sp.giftId = "7934" } else { $sp | Add-Member -MemberType NoteProperty -Name "giftId" -Value "7934" -Force }
                    if ($sp.PSObject.Properties['giftName']) { $sp.giftName = "Heart Me" } else { $sp | Add-Member -MemberType NoteProperty -Name "giftName" -Value "Heart Me" -Force }
                    if ($sp.PSObject.Properties['coins']) { $sp.coins = 1 } else { $sp | Add-Member -MemberType NoteProperty -Name "coins" -Value 1 -Force }
                    if ($sp.PSObject.Properties['giftIcon']) { $sp.giftIcon = "images/tiktok-gifts/7934_heart_me.webp" } else { $sp | Add-Member -MemberType NoteProperty -Name "giftIcon" -Value "images/tiktok-gifts/7934_heart_me.webp" -Force }
                }
            }
        }
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

function Normalize-PresetEvents($events, $presetName = "") {
    if (-not $events) { return @() }
    $normalized = @()
    $idx = 1
    foreach ($ev in $events) {
        $id = if ($ev.id) { [string]$ev.id } elseif ($ev._id) { [string]$ev._id } else { [string]$idx }
        
        # Resolve command
        $cmd = ""
        if ($ev.command) {
            $cmd = [string]$ev.command
        } elseif ($ev.function -and $ev.function.commands -and $ev.function.commands.Count -gt 0) {
            $rawCmds = @()
            foreach ($c in $ev.function.commands) {
                if ($c -is [string]) { $rawCmds += $c.Trim() }
                elseif ($c.command) { $rawCmds += [string]$c.command.Trim() }
            }
            $cmd = $rawCmds -join ";"
        } elseif ($ev.function -and $ev.function.command) {
            $cmd = [string]$ev.function.command
        }
        
        $lbl = ""
        if ($ev.label) { $lbl = [string]$ev.label }
        elseif ($ev.function -and $ev.function.name) { $lbl = [string]$ev.function.name }
        elseif ($ev.functionName) { $lbl = [string]$ev.functionName }
        else { $lbl = $cmd }

        # Resolve correct command for Trident Jugger-nut Gargantuar if it had generic bucket zombie
        if ($lbl -match 'Trident\s*Jugger.*Gargantuar' -and ($cmd -eq 'spawn_bucket_zombie' -or [string]::IsNullOrWhiteSpace($cmd))) {
            $cmd = 'spawn_trident_juggernut_gargantuar'
        }
        
        # Resolve actionType
        $act = if ($ev.actionType) { [string]$ev.actionType } else { "" }
        if (-not $act) {
            $cLower = $cmd.ToLower()
            if ($cLower -match 'plant|sunnut|cattail|pea|sunflower|potato|cherry|melon|nut|squash|chomper') {
                $act = "plant"
            } elseif ($cLower -match 'kill_|plant_every|lawnmower|charm_') {
                $act = "power"
            } elseif ($cLower -match 'spinner_') {
                $act = "spinner"
            } else {
                $act = "zombie"
            }
        }
        
        # Resolve repetition, delay, interval
        $reps = 1
        if ($ev.repetition -and [int]$ev.repetition -gt 0) { $reps = [int]$ev.repetition }
        elseif ($ev.function -and $ev.function.repetition -and [int]$ev.function.repetition -gt 0) { $reps = [int]$ev.function.repetition }
        elseif ($ev.amount -and [int]$ev.amount -gt 0) { $reps = [int]$ev.amount }
        
        $delay = 0
        if ($ev.delay -ne $null) { $delay = [int]$ev.delay }
        elseif ($ev.function -and $ev.function.delay -ne $null) { $delay = [int]$ev.function.delay }
        
        $interval = 100
        if ($ev.interval -ne $null) { $interval = [int]$ev.interval }
        elseif ($ev.function -and $ev.function.interval -ne $null) { $interval = [int]$ev.function.interval }
        
        $repMult = $true
        if ($ev.repetitionMultiplier -ne $null) { $repMult = [bool]$ev.repetitionMultiplier }
        elseif ($ev.function -and $ev.function.repetitionMultiplier -ne $null) { $repMult = [bool]$ev.function.repetitionMultiplier }
        
        $hideInOverlay = $false
        if ($ev.hideInOverlay -ne $null) { $hideInOverlay = [bool]$ev.hideInOverlay }
        elseif ($ev.function -and $ev.function.hideEventInOverlay -ne $null) { $hideInOverlay = [bool]$ev.function.hideEventInOverlay }
        
        # Unit Icon
        $uIcon = ""
        if ($ev.unitIcon) { $uIcon = [string]$ev.unitIcon }
        elseif ($ev.function -and $ev.function.image) { $uIcon = [string]$ev.function.image }
        else {
            $firstCmd = ($cmd.Split(';')[0]).Trim()
            $uIcon = "images/game-icons/pvz/$firstCmd.webp"
        }
        
        # Trigger resolution
        $trigType = "gift"
        $gName = "Gift"
        $gId = ""
        $coins = 1
        $tIcon = "images/tiktok-gifts/5655_rose.webp"
        $likeThresh = 50
        
        if ($ev.trigger) {
            $tAction = [string]$ev.trigger.action
            if ($tAction -eq "LikeForEach") {
                $trigType = "likes_person"
                $likeThresh = if ($ev.trigger.value) { [int]$ev.trigger.value } else { 50 }
                $gName = if ($ev.giftName) { [string]$ev.giftName } else { "Team likes" }
                $coins = 0
                $tIcon = "images/trig_7.svg"
            } elseif ($tAction -eq "LikeAmount") {
                $trigType = "likes_all"
                $likeThresh = if ($ev.trigger.value) { [int64]$ev.trigger.value } else { 50000 }
                $gName = if ($ev.giftName) { [string]$ev.giftName } else { "Total Likes" }
                $coins = 0
                $tIcon = "images/trig_7.svg"
            } elseif ($tAction -eq "Follow") {
                $trigType = "follow"
                $gName = "Follower"
                $coins = 0
                $tIcon = "images/trig_1.svg"
            } elseif ($tAction -eq "Share") {
                $trigType = "share"
                $gName = "Share Stream"
                $coins = 0
                $tIcon = "images/trig_1.svg"
            } else {
                # SelectedGift
                $trigType = "gift"
                $gId = if ($ev.trigger.giftId) { [string]$ev.trigger.giftId } else { "" }
                $gName = if ($ev.trigger.giftData -and $ev.trigger.giftData.name) { [string]$ev.trigger.giftData.name } elseif ($ev.giftName) { [string]$ev.giftName } else { "Gift" }
                $coins = if ($ev.trigger.giftData -and $ev.trigger.giftData.diamond_count) { [int]$ev.trigger.giftData.diamond_count } elseif ($ev.coins) { [int]$ev.coins } else { 1 }
                $tIcon = if ($ev.icon) { [string]$ev.icon } else { "images/tiktok-gifts/${gId}.webp" }
            }
        } else {
            $trigType = if ($ev.triggerType) { [string]$ev.triggerType } elseif ($ev.eventType) { [string]$ev.eventType } else { "gift" }
            $gName = if ($ev.giftName) { [string]$ev.giftName } else { "Gift" }
            $gId = if ($ev.giftId) { [string]$ev.giftId } else { "" }
            $coins = if ($ev.coins) { [int]$ev.coins } else { 1 }
            $tIcon = if ($ev.icon) { [string]$ev.icon } else { "images/tiktok-gifts/5655_rose.webp" }
            $likeThresh = if ($ev.likeThreshold) { [int64]$ev.likeThreshold } else { 50 }
        }
        
        # Sub-commands array of objects
        $cmdsList = @()
        if ($ev.commands -and $ev.commands.Count -gt 0 -and $ev.commands[0].command) {
            $cmdsList = $ev.commands
        } else {
            $parts = $cmd -split ';'
            $cIdx = 1
            foreach ($p in $parts) {
                $trimP = $p.Trim()
                if ($trimP) {
                    $cmdsList += [PSCustomObject]@{
                        name = "Commands #$cIdx"
                        command = $trimP
                        label = $lbl
                        icon = "images/game-icons/pvz/$trimP.webp"
                        actionType = $act
                        amount = 1
                    }
                    $cIdx++
                }
            }
        }
        
        $itemObj = [PSCustomObject]@{
            id = $id
            giftName = $gName
            giftId = $gId
            coins = $coins
            icon = $tIcon
            unitIcon = $uIcon
            actionType = $act
            command = $cmd
            label = $lbl
            amount = if ($ev.amount) { [int]$ev.amount } else { $reps }
            enabled = $true
            likeThreshold = $likeThresh
            commands = $cmdsList
            functionName = $lbl
            repetition = $reps
            delay = $delay
            interval = $interval
            repetitionMultiplier = $repMult
            hideInOverlay = $hideInOverlay
            triggerType = $trigType
            triggerValue = [string]$likeThresh
            platform = "tiktok"
            availableFor = "Anyone"
            allowImport = $true
        }
        $normalized += $itemObj
        $idx++
    }
    return $normalized
}

function Sync-ConfigToCards {
    try {
        $cfg = LoadConfig
        if (-not $cfg -or -not $cfg.gifts -or $cfg.gifts.Count -eq 0) {
            $master = Get-MasterTemplateConfig
            if ($master.gifts -and $master.gifts.Count -gt 0) {
                if (-not $cfg) { $cfg = [PSCustomObject]@{} }
                $cfg | Add-Member -MemberType NoteProperty -Name gifts -Value $master.gifts -Force
                $cfg | Add-Member -MemberType NoteProperty -Name spinners -Value $master.spinners -Force
            }
        }
        if (-not $cfg -or -not $cfg.gifts) { return }
        
        $overlayCards = @()
        foreach ($g in $cfg.gifts) {
            # Auto-correct & enrich gift metadata from verified catalog if ID or icon is missing
            $curGiftId = if ($g.PSObject.Properties['giftId']) { [string]$g.giftId } else { "" }
            $curIcon = if ($g.PSObject.Properties['icon']) { [string]$g.icon } else { "" }
            $curCoins = if ($g.PSObject.Properties['coins']) { [int]$g.coins } else { 0 }
            if ($g.giftName -and ([string]::IsNullOrWhiteSpace($curGiftId) -or [string]::IsNullOrWhiteSpace($curIcon))) {
                $auto = Resolve-AutoCorrectGift $g.giftName $curGiftId
                if ($auto) {
                    if ([string]::IsNullOrWhiteSpace($curGiftId)) {
                        if ($g.PSObject.Properties['giftId']) { $g.giftId = [string]$auto.id } else { $g | Add-Member -MemberType NoteProperty -Name "giftId" -Value ([string]$auto.id) -Force }
                    }
                    if ($curCoins -eq 0) {
                        if ($g.PSObject.Properties['coins']) { $g.coins = [int]$auto.coins } else { $g | Add-Member -MemberType NoteProperty -Name "coins" -Value ([int]$auto.coins) -Force }
                    }
                    if ([string]::IsNullOrWhiteSpace($curIcon) -or $curIcon -like "*default*") {
                        if ($g.PSObject.Properties['icon']) { $g.icon = [string]$auto.icon } else { $g | Add-Member -MemberType NoteProperty -Name "icon" -Value ([string]$auto.icon) -Force }
                    }
                }
            }

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

        if ($overlayCards.Count -gt 0) {
            $cardsJson = $overlayCards | ConvertTo-Json -Depth 6
            [System.IO.File]::WriteAllText($cardsFile, $cardsJson, [System.Text.Encoding]::UTF8)
            
            $cardsDataJsFile = Join-Path $folder "cards-data.js"
            $cardsDataJs = "const cardsData = " + $cardsJson + ";"
            [System.IO.File]::WriteAllText($cardsDataJsFile, $cardsDataJs, [System.Text.Encoding]::UTF8)

            # Ensure all card IDs are tracked in counts table
            foreach ($card in $overlayCards) {
                $cid = [string]$card.id
                if ($cid -and -not $counts.ContainsKey($cid)) {
                    $counts[$cid] = 0
                }
            }
            SaveCounts
        }
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
                $req.Timeout = 400
                $req.ReadWriteTimeout = 400
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
function SendToPvZGame($actionType, $command, $amount = 1, $username = "RENEarn", $avatarUrl = "", $repetition = 1, $delay = 0, $interval = 0) {
    if (-not $command) { return @{ success = $false; message = "Empty command" } }

    # Normalize username: If empty or generic tester placeholder, display as RENEarn.
    # When LIVE with real viewers/gifters, their genuine TikTok usernames pass straight through!
    if (-not $username -or $username -in @("StreamViewer", "Viewer", "Streamer", "Tester", "TestViewer", "TestGifter", "SocialTester", "User", "Sharer", "Follower", "")) {
        $username = "RENEarn"
    }

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
    if (-not $lastResult.success) {
        # Game engine is offline, skip remaining repetitions to avoid blocking webhooks
        break
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
        $len = [int]$req.ContentLength64
        if ($len -gt 0) {
            $buffer = New-Object byte[] $len
            $totalRead = 0
            while ($totalRead -lt $len) {
                $read = $req.InputStream.Read($buffer, $totalRead, $len - $totalRead)
                if ($read -le 0) { break }
                $totalRead += $read
            }
            return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $totalRead)
        } else {
            $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
            return $reader.ReadToEnd()
        }
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
Write-Host "  RENEarn - PvZ Fusion Live Stream Studio running!" -ForegroundColor Cyan
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

function Ensure-Dependencies {
    # 1. Unpack portable node.exe if bin\node.exe does not exist
    $binDir = Join-Path $folder "bin"
    $binNode = Join-Path $binDir "node.exe"
    $nodeArchive = Join-Path $folder "node_runtime.tar.gz"
    if (-not (Test-Path $binNode)) {
        if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
        if (Test-Path $nodeArchive) {
            Write-Host "  [SETUP] Unpacking portable Node.js runtime for this PC..." -ForegroundColor Yellow
            try {
                & tar -xzf $nodeArchive -C $binDir
                if (Test-Path $binNode) {
                    Write-Host "  [SETUP] Portable Node.js unpacked successfully!" -ForegroundColor Green
                }
            } catch {
                Write-Host "  [WARNING] tar extraction of node runtime failed: $_" -ForegroundColor Red
            }
        }
    }

    # 2. Unpack node_modules if missing
    $nmDir = Join-Path $folder "node_modules"
    $connectorDir = Join-Path $nmDir "tiktok-live-connector"
    $modulesArchive = Join-Path $folder "runtime_modules.tar.gz"
    if ((-not (Test-Path $nmDir) -or -not (Test-Path $connectorDir)) -and (Test-Path $modulesArchive)) {
        Write-Host "  [SETUP] Unpacking TikTok Live Connector modules..." -ForegroundColor Yellow
        try {
            & tar -xzf $modulesArchive -C $folder
            if (Test-Path $connectorDir) {
                Write-Host "  [SETUP] TikTok Live Connector unpacked successfully!" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [WARNING] tar extraction of modules failed: $_" -ForegroundColor Red
        }
    }
}

function Find-NodeExecutable {
    # 0. Ensure bundled archives are extracted first
    Ensure-Dependencies

    # 1. Check local bundled bin folder inside project
    $binNode = Join-Path $folder "bin\node.exe"
    if (Test-Path $binNode) { return $binNode }
    $parentBinNode = Join-Path (Split-Path $folder -Parent) "bin\node.exe"
    if (Test-Path $parentBinNode) { return $parentBinNode }

    # 2. Check system PATH
    try {
        $cmdNode = (Get-Command node -ErrorAction SilentlyContinue).Source
        if ($cmdNode -and (Test-Path $cmdNode)) { return $cmdNode }
    } catch {}

    # 3. Dynamic search across common locations for any user on Windows
    $candidates = @(
        "$env:LOCALAPPDATA\app.runetify.desktop\runtimes\node\*\node.exe",
        "$env:LOCALAPPDATA\AsureLive\node-runtime\*\node.exe",
        "$env:ProgramFiles\nodejs\node.exe",
        "${env:ProgramFiles(x86)}\nodejs\node.exe",
        "$env:LOCALAPPDATA\Programs\node\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe",
        "C:\Users\*\AppData\Local\app.runetify.desktop\runtimes\node\*\node.exe",
        "C:\Users\*\AppData\Local\AsureLive\node-runtime\*\node.exe",
        "C:\Users\*\AppData\Local\Programs\nodejs\node.exe"
    )

    foreach ($pat in $candidates) {
        $found = Get-Item $pat -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found -and (Test-Path $found.FullName)) {
            return $found.FullName
        }
    }

    # 4. Auto-download portable Node.js if missing (fallback for friends/other users without archives)
    try {
        $binDir = Join-Path $folder "bin"
        if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
        $dlTarget = Join-Path $binDir "node.exe"
        Write-Host "  [SETUP] Downloading lightweight Node.js runtime for TikTok Live..." -ForegroundColor Yellow
        $nodeUrl = "https://nodejs.org/dist/v20.18.0/win-x64/node.exe"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($nodeUrl, $dlTarget)
        if (Test-Path $dlTarget) {
            Write-Host "  [SETUP] Downloaded Node.js successfully to $dlTarget" -ForegroundColor Green
            return $dlTarget
        }
    } catch {
        Write-Host "  [WARNING] Unable to auto-download Node.js: $_" -ForegroundColor Red
    }

    return $null
}

$script:nodePath = Find-NodeExecutable
$script:tiktokBridgeProc = $null

function Start-TikTokBridge([string]$targetUser) {
    Stop-TikTokBridge
    $cleanUser = $targetUser.Trim().TrimStart('@')
    if ($cleanUser -match 'tiktok\.com\/@([a-zA-Z0-9_.-]+)') {
        $cleanUser = $matches[1]
    } else {
        $cleanUser = $cleanUser.Split('/')[0].Split('?')[0].Split('&')[0].Trim()
    }
    if (-not $cleanUser) { return }

    $script:tiktokConnectedUser = $cleanUser

    # Ensure dependencies are available before launching
    Ensure-Dependencies
    if (-not $script:nodePath -or -not (Test-Path $script:nodePath)) {
        $script:nodePath = Find-NodeExecutable
    }

    $bridgeScript = Join-Path $folder "tiktok_bridge.js"
    if ($script:nodePath -and (Test-Path $script:nodePath) -and (Test-Path $bridgeScript)) {
        try {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $script:nodePath
            $pinfo.Arguments = "`"$bridgeScript`" `"$cleanUser`""
            $pinfo.WorkingDirectory = $folder
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $script:tiktokBridgeProc = [System.Diagnostics.Process]::Start($pinfo)
            Write-Host "  -> TikTok Live Bridge launched for @$cleanUser (PID $($script:tiktokBridgeProc.Id)) using $script:nodePath" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to launch TikTok bridge: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [ERROR] Cannot start TikTok Live bridge: Node runtime not found." -ForegroundColor Red
        $stateFile = Join-Path $folder "tiktok_live_state.json"
        $st = @{
            connected = $false
            processRunning = $false
            username = $cleanUser
            statusText = "Node runtime not found. Please install Node.js from nodejs.org or restart app with internet for auto-setup."
        }
        [System.IO.File]::WriteAllText($stateFile, ($st | ConvertTo-Json), [System.Text.Encoding]::UTF8)
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

# Auto-start TikTok bridge only if streamer username is configured AND autoConnect is enabled
$initialCfg = LoadConfig
if ($initialCfg -and $initialCfg.streamer -and $initialCfg.streamer.tiktokUsername -and ($initialCfg.streamer.autoConnect -eq $true)) {
    Start-TikTokBridge $initialCfg.streamer.tiktokUsername
}

# Ensure Global Windows Hotkey Hook is running for Alt+- and Alt+=
$hotkeyExe = Join-Path $folder "tools\GlobalHotkeyService.exe"
if (Test-Path $hotkeyExe) {
    $existingHk = Get-Process -Name 'GlobalHotkeyService', 'RENEarn_Studio' -ErrorAction SilentlyContinue
    if (-not $existingHk) {
        try {
            Start-Process -FilePath $hotkeyExe -WindowStyle Hidden
            Write-Host "  -> Global Hotkey Service started (Alt+- : Lose / Alt+= : Win)" -ForegroundColor Green
        } catch {}
    }
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

        # 1a. Game Directory & Path Settings
        if ($reqPath -eq '/api/game/directory' -and $request.HttpMethod -eq 'POST') {
            $callerRole = Get-CallerRole $request
            if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                Send-JsonResponse $response @{ status = "error"; message = "Access denied: Viewers cannot update game directory." } 403
                continue
            }
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $dirPath = if ($data.directory) { [string]$data.directory.Trim() } else { "" }
                $gameDirFile = Join-Path $folder "game_directory.txt"
                if ($dirPath) {
                    [System.IO.File]::WriteAllText($gameDirFile, $dirPath, [System.Text.Encoding]::UTF8)
                }
                Send-JsonResponse $response @{ status = "ok"; directory = $dirPath; exists = (Test-Path $dirPath) }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        if ($reqPath -eq '/api/game/open-folder' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $folderToOpen = if ($data.path) { [string]$data.path.Trim() } else { "C:\Users\pc\Downloads\ano na\Game Files" }
                if (Test-Path $folderToOpen) {
                    Start-Process "explorer.exe" -ArgumentList "`"$folderToOpen`""
                    Send-JsonResponse $response @{ status = "ok"; message = "Folder opened in File Explorer" }
                } else {
                    Send-JsonResponse $response @{ status = "warn"; message = "Directory not found: $folderToOpen" }
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1a-detect. Game Directory Detection & MelonLoader Integration
        if ($reqPath -eq '/api/game/detect' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $gameDir = if ($data.directory) { [string]$data.directory.Trim() } else { "" }
                if (-not $gameDir) {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    if (Test-Path $gameDirFile) { $gameDir = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() }
                }
                if (-not $gameDir -or -not (Test-Path $gameDir)) {
                    Send-JsonResponse $response @{ status = "error"; message = "Game directory not found: $gameDir"; connected = $false }
                    continue
                }

                # Detect MelonLoader
                $mlDir = Join-Path $gameDir "MelonLoader"
                $hasMelonLoader = Test-Path $mlDir
                $mlVersion = ""
                if ($hasMelonLoader) {
                    $mlDll = Join-Path $mlDir "net6\MelonLoader.dll"
                    if (Test-Path $mlDll) {
                        try {
                            $fi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($mlDll)
                            $mlVersion = $fi.ProductVersion
                        } catch { $mlVersion = "detected" }
                    }
                }

                # Detect installed mods
                $modsDir = Join-Path $gameDir "Mods"
                $installedMods = @()
                if (Test-Path $modsDir) {
                    Get-ChildItem $modsDir -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
                        $modEntry = @{ name = $_.BaseName; size = $_.Length; lastModified = $_.LastWriteTime.ToString("o") }
                        if ($_.Name -like "*RENEarn*" -or $_.Name -like "*Runetify*") { $modEntry.isRENEarn = $true }
                        if ($_.Name -like "*S2E*") { $modEntry.isS2E = $true }
                        $installedMods += $modEntry
                    }
                }

                # Detect game executable
                $gameExe = ""
                $gameExeNames = @("PlantsVsZombiesRH.exe", "PlantsVsZombies.exe")
                foreach ($exeName in $gameExeNames) {
                    $exePath = Join-Path $gameDir $exeName
                    if (Test-Path $exePath) { $gameExe = $exeName; break }
                }

                # Check if game is running
                $gameRunning = $false
                foreach ($p in $gamePorts) {
                    if (Test-GamePort $p) { $gameRunning = $true; break }
                }

                # Read renearn_info.json or runetify_info.json
                $modInfo = $null
                $renearnInfoPath = Join-Path $gameDir "renearn_info.json"
                $runetifyInfoPath = Join-Path $gameDir "runetify_info.json"
                if (Test-Path $renearnInfoPath) {
                    try { $modInfo = Get-Content $renearnInfoPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                } elseif (Test-Path $runetifyInfoPath) {
                    try { $modInfo = Get-Content $runetifyInfoPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                }

                $resObj = @{
                    status = "ok"
                    connected = $gameRunning
                    directory = $gameDir
                    hasMelonLoader = $hasMelonLoader
                    melonLoaderVersion = $mlVersion
                    gameExecutable = $gameExe
                    gameRunning = $gameRunning
                    modsInstalled = $installedMods
                    modInfo = $modInfo
                    activePorts = $gamePorts
                }
                Send-JsonResponse $response $resObj
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1a-melonlog. Read MelonLoader Latest.log from game directory
        if ($reqPath -eq '/api/game/melonlog') {
            try {
                $gameDir = ""
                $gameDirFile = Join-Path $folder "game_directory.txt"
                if (Test-Path $gameDirFile) { $gameDir = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() }
                $logFile = Join-Path $gameDir "MelonLoader\Latest.log"
                if (Test-Path $logFile) {
                    $tailLines = 100
                    $qTail = $request.QueryString['lines']
                    if ($qTail) { $tailLines = [Math]::Min([int]$qTail, 500) }
                    $logContent = Get-Content $logFile -Tail $tailLines -ErrorAction SilentlyContinue
                    $logText = $logContent -join "`n"
                    Send-JsonResponse $response @{ status = "ok"; log = $logText; lines = $logContent.Count; file = $logFile }
                } else {
                    Send-JsonResponse $response @{ status = "warn"; message = "MelonLoader log not found at $logFile"; log = "" }
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1b. TikTok Live Control Endpoints
        if ($reqPath -eq '/api/tiktok/connect') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $user = if ($data.username) { [string]$data.username.Trim() } else { "" }
            if ($user -match 'tiktok\.com\/@([a-zA-Z0-9_.-]+)') {
                $user = $matches[1]
            } else {
                $user = $user.TrimStart('@').Split('/')[0].Split('?')[0].Split('&')[0].Trim()
            }
            if (-not $user) {
                Send-JsonResponse $response @{ status = "error"; message = "TikTok username is required" }
                continue
            }
            $script:tiktokConnectedUser = $user
            $cfg = LoadConfig $user
            if (-not $cfg.streamer) { $cfg | Add-Member -MemberType NoteProperty -Name streamer -Value @{} -Force }
            $cfg.streamer.tiktokUsername = $user
            $userCfgFile = Get-UserConfigPath $user
            [System.IO.File]::WriteAllText($userCfgFile, ($cfg | ConvertTo-Json -Depth 6), [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($configFile, ($cfg | ConvertTo-Json -Depth 6), [System.Text.Encoding]::UTF8)
            Start-TikTokBridge $user
            Send-JsonResponse $response @{ status = "ok"; message = "Connecting to @$user"; username = $user }
            continue
        }

        if ($reqPath -eq '/api/tiktok/disconnect') {
            Stop-TikTokBridge
            $script:tiktokConnectedUser = $null
            $stateFile = Join-Path $folder "tiktok_live_state.json"
            if (Test-Path $stateFile) {
                $st = @{ connected = $false; processRunning = $false; statusText = "Disconnected"; username = "" }
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
            $isProcRunning = if ($script:tiktokBridgeProc -and -not $script:tiktokBridgeProc.HasExited) { $true } elseif ($stObj -and $stObj.processRunning) { $true } else { $false }
            $nodeAvailable = [bool]($script:nodePath -and (Test-Path $script:nodePath))
            $cfg = LoadConfig
            $fallbackUser = if ($cfg -and $cfg.streamer) { [string]$cfg.streamer.tiktokUsername } else { "" }
            $res = @{
                connected = if ($stObj) { [bool]$stObj.connected } else { $false }
                processRunning = $isProcRunning
                nodeAvailable = $nodeAvailable
                username = if ($stObj -and $stObj.username) { [string]$stObj.username } else { $fallbackUser }
                roomId = if ($stObj) { [string]$stObj.roomId } else { "" }
                viewerCount = if ($stObj -and $stObj.viewerCount) { [int]$stObj.viewerCount } else { 0 }
                totalLikes = if ($stObj -and $stObj.totalLikes) { [int64]$stObj.totalLikes } else { 0 }
                statusText = if (-not $nodeAvailable) { "Node.js runtime missing" } elseif ($stObj) { [string]$stObj.statusText } else { "Ready to connect" }
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

                if ($email -and -not $email.Contains('@')) {
                    $email = "$email@gmail.com"
                }

                if (-not $email -or $email -notmatch '^.+@.+\..+$') {
                    Send-JsonResponse $response @{ success = $false; message = "Valid Google email required" } 400
                    continue
                }

                # Determine user role
                $role = Get-UserRole $email
                $perms = Load-Permissions
                if ($email -eq "jaylouvipinosa7@gmail.com") {
                    $perms.admin = "jaylouvipinosa7@gmail.com"
                    $admsList = @("jaylouvipinosa7@gmail.com")
                    if ($perms.admins) {
                        foreach ($a in $perms.admins) {
                            if ($a -and $a.ToLower() -ne "jaylouvipinosa7@gmail.com" -and -not ($admsList -contains $a.ToLower())) {
                                $admsList += $a.ToLower()
                            }
                        }
                    }
                    $perms.admins = $admsList
                    Save-Permissions $perms
                    $role = "admin"
                } elseif (-not $perms.admin -and ($perms.admins.Count -eq 0)) {
                    $perms.admin = $email
                    $perms.admins = @($email)
                    Save-Permissions $perms
                    $role = "admin"
                }

                # Issue token
                $token = "pvz_sess_" + [System.Guid]::NewGuid().ToString("N")
                $sessObj = @{
                    token = $token
                    email = $email
                    name = $name
                    picture = $picture
                    role = $role
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
                    role = $role
                    lastLogin = (Get-Date).ToString("o")
                }
                [System.IO.File]::WriteAllText($usersDbFile, ($registry | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)

                # Check if this user already has custom triggers configured
                $userCfgPath = Get-UserConfigPath $email
                $isNewUser = (-not (Test-Path $userCfgPath))
                $master = Get-MasterTemplateConfig
                $tmplGifts = $master.gifts
                $tmplSpinners = $master.spinners

                if ($isNewUser) {
                    # Preload full 64 gift commands and multi-spinners pool for new user/streamer
                    $userConfig = @{
                        streamer = @{
                            tiktokUsername = ""
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $false
                            userEmail = $email
                            userName = $name
                            userPicture = $picture
                            role = $role
                        }
                        overlay = if ($master.overlay) { $master.overlay } else { @{ zoom = 1; columns = 1; showGoals = $true; alertDuration = 4000; soundAlerts = $true; wheelPosition = "center" } }
                        gifts = $tmplGifts
                        spinners = $tmplSpinners
                    }
                    $userJson = $userConfig | ConvertTo-Json -Depth 8
                    [System.IO.File]::WriteAllText($userCfgPath, $userJson, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $userJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                } else {
                    # User returning: activate existing saved configuration, repair gifts or spinners if empty
                    if (Test-Path $userCfgPath) {
                        $userJson = [System.IO.File]::ReadAllText($userCfgPath, [System.Text.Encoding]::UTF8)
                        try {
                            $uObj = $userJson | ConvertFrom-Json
                            $repaired = $false
                            if (-not $uObj.gifts -or $uObj.gifts.Count -eq 0) {
                                $uObj.gifts = $tmplGifts
                                $repaired = $true
                            }
                            if (-not $uObj.spinners -or $uObj.spinners.Count -eq 0) {
                                $uObj.spinners = $tmplSpinners
                                $repaired = $true
                            }
                            if ($repaired) {
                                $userJson = $uObj | ConvertTo-Json -Depth 8
                                [System.IO.File]::WriteAllText($userCfgPath, $userJson, [System.Text.Encoding]::UTF8)
                            }
                        } catch {}
                        [System.IO.File]::WriteAllText($configFile, $userJson, [System.Text.Encoding]::UTF8)
                        Sync-ConfigToCards
                    }
                }

                Send-JsonResponse $response @{
                    success = $true
                    token = $token
                    isNewUser = $isNewUser
                    user = @{
                        email = $email
                        name = $name
                        picture = $picture
                        role = $role
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

                $userRole = Get-UserRole $email
                $sessObj = @{
                    token = $token
                    email = $email
                    name = $displayName
                    username = $username
                    platform = "tiktok"
                    picture = $avatar
                    role = $userRole
                    loginTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
                $activeSessions[$token] = $sessObj

                # Check if this TikTok streamer already has a config
                $userCfgPath = Get-UserConfigPath $email
                $isNewUser = (-not (Test-Path $userCfgPath))
                $master = Get-MasterTemplateConfig
                $tmplGifts = $master.gifts
                $tmplSpinners = $master.spinners

                if ($isNewUser) {
                    # Preload full 64 working gift commands and multi-spinners pool for TikTok streamer
                    $userConfig = @{
                        streamer = @{
                            tiktokUsername = $username
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $true
                            userEmail = $email
                            userName = $displayName
                            userPicture = $avatar
                            role = $userRole
                            platform = "tiktok"
                        }
                        overlay = if ($master.overlay) { $master.overlay } else { @{ zoom = 1; columns = 1; showGoals = $true; alertDuration = 4000; soundAlerts = $true; wheelPosition = "center" } }
                        gifts = $tmplGifts
                        spinners = $tmplSpinners
                    }
                    $userJson = $userConfig | ConvertTo-Json -Depth 8
                    [System.IO.File]::WriteAllText($userCfgPath, $userJson, [System.Text.Encoding]::UTF8)
                    [System.IO.File]::WriteAllText($configFile, $userJson, [System.Text.Encoding]::UTF8)
                    Sync-ConfigToCards
                } else {
                    $userJson = [System.IO.File]::ReadAllText($userCfgPath, [System.Text.Encoding]::UTF8)
                    try {
                        $uObj = $userJson | ConvertFrom-Json
                        $repaired = $false
                        if (-not $uObj.gifts -or $uObj.gifts.Count -eq 0) {
                            $uObj.gifts = $tmplGifts
                            $repaired = $true
                        }
                        if (-not $uObj.spinners -or $uObj.spinners.Count -eq 0) {
                            $uObj.spinners = $tmplSpinners
                            $repaired = $true
                        }
                        if ($repaired) {
                            $userJson = $uObj | ConvertTo-Json -Depth 8
                            [System.IO.File]::WriteAllText($userCfgPath, $userJson, [System.Text.Encoding]::UTF8)
                        }
                    } catch {}
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
                $sess = $activeSessions[$token]
                $sess.role = Get-UserRole $sess.email
                Send-JsonResponse $response @{
                    authenticated = $true
                    user = $sess
                }
            } else {
                $perms = Load-Permissions
                $adm = if ($perms.admin) { $perms.admin } else { "jaylouvipinosa7@gmail.com" }
                $newToken = if ($token) { $token } else { [System.Guid]::NewGuid().ToString() }
                $sess = @{
                    email = $adm
                    name = "gohanmalunggay"
                    role = "admin"
                    platform = "google"
                    picture = "https://ui-avatars.com/api/?name=Admin&background=10b981&color=fff&size=128&bold=true"
                }
                $activeSessions[$newToken] = $sess
                Send-JsonResponse $response @{
                    authenticated = $true
                    token = $newToken
                    user = $sess
                }
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

        # 1f. Permissions & Role Management Endpoints
        if ($reqPath -eq '/api/permissions' -and $request.HttpMethod -eq 'GET') {
            $caller = Get-CallerUser $request
            $perms = Load-Permissions
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { $perms.admin }
            $callerRole = Get-CallerRole $request
            $resObj = @{
                status = "ok"
                admin = $perms.admin
                admins = @($perms.admins)
                editors = @($perms.editors)
                currentUserEmail = $callerEmail
                currentUserRole = $callerRole
                isSetupMode = (-not $perms.admin -and ($perms.admins.Count -eq 0))
            }
            Send-JsonResponse $response $resObj
            continue
        }

        if ($reqPath -eq '/api/permissions/add-editor' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } elseif ($data.callerEmail) { $data.callerEmail } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only an Admin can add editors." } 403
                continue
            }
            $newEmail = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
            if (-not $newEmail -or $newEmail -notmatch '^.+@.+\..+$') {
                Send-JsonResponse $response @{ success = $false; message = "Valid Gmail/email address required." } 400
                continue
            }
            $perms = Load-Permissions
            $curEditors = @($perms.editors)
            if (-not ($curEditors -contains $newEmail)) {
                $curEditors += $newEmail
                $perms.editors = $curEditors
                Save-Permissions $perms
            }
            # Update any active sessions for this email
            foreach ($k in $activeSessions.Keys) {
                if ($activeSessions[$k].email -eq $newEmail) {
                    $activeSessions[$k].role = "editor"
                }
            }
            Send-JsonResponse $response @{ success = $true; message = "Added $newEmail as Editor"; editors = @($perms.editors) }
            continue
        }

        if ($reqPath -eq '/api/permissions/remove-editor' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } elseif ($data.callerEmail) { $data.callerEmail } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only an Admin can remove editors." } 403
                continue
            }
            $targetEmail = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
            $perms = Load-Permissions
            $perms.editors = @($perms.editors | Where-Object { $_ -ne $targetEmail })
            Save-Permissions $perms
            # Update any active sessions for this email
            foreach ($k in $activeSessions.Keys) {
                if ($activeSessions[$k].email -eq $targetEmail) {
                    $activeSessions[$k].role = "viewer"
                }
            }
            Send-JsonResponse $response @{ success = $true; message = "Removed $targetEmail from Editors"; editors = @($perms.editors) }
            continue
        }

        if ($reqPath -eq '/api/permissions/set-admin' -and $request.HttpMethod -eq 'POST') {
            $perms = Load-Permissions
            $caller = Get-CallerUser $request
            $isSetup = (-not $perms.admin -and ($perms.admins.Count -eq 0))
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $callerEmail = if ($caller -and $caller.email) { $caller.email } elseif ($data.callerEmail) { $data.callerEmail } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            
            if (-not $isSetup -and $role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only the current Admin can change Admin settings." } 403
                continue
            }
            $adminEmail = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
            if (-not $adminEmail -or $adminEmail -notmatch '^.+@.+\..+$') {
                Send-JsonResponse $response @{ success = $false; message = "Valid Gmail address required." } 400
                continue
            }
            $perms.admin = $adminEmail
            $curAdmins = @($perms.admins)
            if (-not ($curAdmins -contains $adminEmail)) {
                $curAdmins += $adminEmail
                $perms.admins = $curAdmins
            }
            Save-Permissions $perms
            if ($caller) {
                $caller.role = Get-UserRole $caller.email
            }
            Send-JsonResponse $response @{ success = $true; message = "Designated $adminEmail as Admin/Owner"; admin = $adminEmail; admins = @($perms.admins) }
            continue
        }

        # 2. Config Get / Save (Per-User Isolated)
        if ($reqPath -eq '/api/config') {
            $userParam = $request.QueryString['user']
            $targetPath = Get-UserConfigPath $userParam

            if ($request.HttpMethod -eq 'GET') {
                $master = Get-MasterTemplateConfig
                $tmplGifts = $master.gifts
                $tmplSpinners = $master.spinners

                if (-not (Test-Path $targetPath)) {
                    # Auto-initialize configuration with full 64 gift commands and multi-spinners pool
                    $userConfig = @{
                        streamer = @{
                            tiktokUsername = ""
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $false
                            userEmail = if ($userParam) { $userParam } else { "" }
                        }
                        overlay = if ($master.overlay) { $master.overlay } else { @{ zoom = 1; columns = 1; showGoals = $true; alertDuration = 4000; soundAlerts = $true; wheelPosition = "center" } }
                        gifts = $tmplGifts
                        spinners = $tmplSpinners
                    }
                    $userJson = $userConfig | ConvertTo-Json -Depth 8
                    [System.IO.File]::WriteAllText($targetPath, $userJson, [System.Text.Encoding]::UTF8)
                    Send-JsonResponse $response $userJson
                    continue
                }
                $content = [System.IO.File]::ReadAllText($targetPath, [System.Text.Encoding]::UTF8)
                try {
                    $parsedCfg = $content | ConvertFrom-Json
                    $cfgModified = $false
                    if ($parsedCfg -and (-not $parsedCfg.gifts -or $parsedCfg.gifts.Count -eq 0)) {
                        $parsedCfg | Add-Member -MemberType NoteProperty -Name gifts -Value $tmplGifts -Force
                        $cfgModified = $true
                    }
                    if ($parsedCfg -and (-not $parsedCfg.spinners -or $parsedCfg.spinners.Count -eq 0)) {
                        $parsedCfg | Add-Member -MemberType NoteProperty -Name spinners -Value $tmplSpinners -Force
                        $cfgModified = $true
                    }
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
                        $cfgModified = $true
                    }
                    if ($cfgModified) {
                        $content = $parsedCfg | ConvertTo-Json -Depth 10
                        try { [System.IO.File]::WriteAllText($targetPath, $content, [System.Text.Encoding]::UTF8) } catch {}
                    }
                } catch {}
                Send-JsonResponse $response $content
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $callerRole = Get-CallerRole $request
                if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                    Send-JsonResponse $response @{ status = "error"; message = "Access denied: You are in Viewer (Read-Only) mode. Only the Admin and authorized Editors can save changes." } 403
                    continue
                }
                $body = ReadRequestBody $request
                [System.IO.File]::WriteAllText($targetPath, $body, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $body, [System.Text.Encoding]::UTF8)
                if (Test-Path $userConfigsFolder) {
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
            $callerRole = Get-CallerRole $request
            if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                Send-JsonResponse $response @{ status = "error"; message = "Access denied: Viewer mode cannot import templates. Editor or Admin permission required." } 403
                continue
            }
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

        # 2c. Import Events (S2E / External Apps / JSON Payload)
        if ($reqPath -eq '/api/events/import' -and $request.HttpMethod -eq 'POST') {
            $callerRole = Get-CallerRole $request
            if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                Send-JsonResponse $response @{ status = "error"; message = "Access denied: Editor or Admin permission required to import events." } 403
                continue
            }
            $userParam = $request.QueryString['user']
            $targetPath = Get-UserConfigPath $userParam

            try {
                $body = ReadRequestBody $request
                $importData = $body | ConvertFrom-Json
                
                $items = @()
                if ($importData -is [System.Array]) {
                    $items = $importData
                } elseif ($importData.events) {
                    $items = @($importData.events)
                } elseif ($importData.gifts) {
                    $items = @($importData.gifts)
                } else {
                    $items = @($importData)
                }

                $existingConfig = if (Test-Path $targetPath) {
                    Get-Content $targetPath -Raw -Encoding UTF8 | ConvertFrom-Json
                } else {
                    Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
                }

                if (-not $existingConfig.gifts) {
                    $existingConfig | Add-Member -MemberType NoteProperty -Name "gifts" -Value @() -Force
                }

                $destMode = if ($request.QueryString['mode']) { $request.QueryString['mode'] } else { "merge" }
                $importedCount = 0

                if ($destMode -eq "replace_all") {
                    $existingConfig.gifts = @()
                }

                $currentGiftsList = [System.Collections.ArrayList]@($existingConfig.gifts)

                foreach ($item in $items) {
                    $itemName = if ($item.giftName) { $item.giftName } elseif ($item.name) { $item.name } else { "Imported Trigger" }
                    $itemCmd = if ($item.command) { $item.command } else { "spawn_ultimatehorse" }
                    $itemRep = if ($item.repetition) { [int]$item.repetition } elseif ($item.amount) { [int]$item.amount } else { 1 }
                    $itemThresh = if ($item.likeThreshold) { [int64]$item.likeThreshold } elseif ($item.triggerValue) { [int64]$item.triggerValue } else { 50000 }
                    $itemAllowImport = if ($null -ne $item.allowImport) { [bool]$item.allowImport } else { $true }

                    $newEntry = [PSCustomObject]@{
                        id = if ($item.id) { [string]$item.id } else { ("imp_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + "_" + (Get-Random -Minimum 100 -Maximum 999)) }
                        giftName = $itemName
                        giftId = if ($item.giftId) { [string]$item.giftId } else { "" }
                        coins = if ($item.coins) { [int]$item.coins } else { 1 }
                        likeThreshold = $itemThresh
                        triggerType = if ($item.triggerType) { $item.triggerType } else { "gift" }
                        triggerValue = if ($item.triggerValue) { [string]$item.triggerValue } else { [string]$itemThresh }
                        platform = if ($item.platform) { $item.platform } else { "tiktok" }
                        availableFor = if ($item.availableFor) { $item.availableFor } else { "Anyone" }
                        functionName = if ($item.functionName) { $item.functionName } else { $itemName }
                        label = if ($item.label) { $item.label } else { $itemName }
                        actionType = if ($item.actionType) { $item.actionType } else { "zombie" }
                        command = $itemCmd
                        commands = if ($item.commands) { $item.commands } else { @(@{ name = "Commands #1"; command = $itemCmd; amount = $itemRep }) }
                        amount = $itemRep
                        repetition = $itemRep
                        delay = if ($item.delay) { [int]$item.delay } else { 0 }
                        interval = if ($null -ne $item.interval) { [int]$item.interval } else { 100 }
                        repetitionMultiplier = if ($null -ne $item.repetitionMultiplier) { [bool]$item.repetitionMultiplier } else { $true }
                        allowImport = $itemAllowImport
                        hideInOverlay = if ($null -ne $item.hideInOverlay) { [bool]$item.hideInOverlay } else { $false }
                        enabled = if ($null -ne $item.enabled) { [bool]$item.enabled } else { $true }
                        unitIcon = if ($item.unitIcon) { $item.unitIcon } else { "images/game-icons/pvz/$itemCmd.webp" }
                        icon = if ($item.icon) { $item.icon } else { "images/tiktok-gifts/5655_rose.webp" }
                    }

                    # Check for match in merge mode
                    $matchIdx = -1
                    for ($k = 0; $k -lt $currentGiftsList.Count; $k++) {
                        $ex = $currentGiftsList[$k]
                        if (($ex.giftId -and $newEntry.giftId -and $ex.giftId -eq $newEntry.giftId) -or
                            ($ex.id -and $newEntry.id -and $ex.id -eq $newEntry.id) -or
                            ($ex.giftName -and $newEntry.giftName -and $ex.giftName.ToLower() -eq $newEntry.giftName.ToLower() -and $ex.triggerType -eq $newEntry.triggerType)) {
                            $matchIdx = $k
                            break
                        }
                    }

                    if ($matchIdx -ge 0 -and $destMode -eq "merge") {
                        $currentGiftsList[$matchIdx] = $newEntry
                    } else {
                        [void]$currentGiftsList.Add($newEntry)
                    }
                    $importedCount++
                }

                $existingConfig.gifts = @($currentGiftsList)
                $updatedJson = $existingConfig | ConvertTo-Json -Depth 10
                [System.IO.File]::WriteAllText($targetPath, $updatedJson, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $updatedJson, [System.Text.Encoding]::UTF8)
                Sync-ConfigToCards

                Send-JsonResponse $response @{
                    status = "ok"
                    importedCount = $importedCount
                    totalGifts = $currentGiftsList.Count
                    message = "Successfully imported $importedCount event(s) from S2E / external app"
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "Failed to parse import payload: $_" } 400
            }
            continue
        }

        # 2d. Export Events (For S2E / External Apps / Webhook integrations)
        if ($reqPath -eq '/api/events/export' -and $request.HttpMethod -eq 'GET') {
            $userParam = $request.QueryString['user']
            $targetPath = Get-UserConfigPath $userParam
            $srcPath = if (Test-Path $targetPath) { $targetPath } else { $configFile }
            
            if (Test-Path $srcPath) {
                $cfg = Get-Content $srcPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $allowList = @()
                if ($cfg.gifts) {
                    $allowList = @($cfg.gifts | Where-Object { $null -eq $_.allowImport -or $_.allowImport -eq $true })
                }
                $exportPayload = @{
                    app = "s2e"
                    format = "pvz_fusion_s2e_v1"
                    exportDate = [DateTime]::UtcNow.ToString("o")
                    totalEvents = $allowList.Count
                    events = $allowList
                }
                Send-JsonResponse $response $exportPayload
            } else {
                Send-JsonResponse $response @{ status = "error"; message = "Config not found" } 404
            }
            continue
        }

        # 2e. S2E Preset / Event Code Resolver (Fetches by 24-char hex code e.g. 6ab90a09802d615caa9b8877)
        if ($reqPath -eq '/api/s2e/preset') {
            $code = if ($request.QueryString['code']) { $request.QueryString['code'].Trim() } elseif ($request.QueryString['id']) { $request.QueryString['id'].Trim() } else { "" }
            if ($code -match '([0-9a-fA-F]{24})') {
                $code = $matches[1].ToLower()
            }

            if (-not $code) {
                Send-JsonResponse $response @{ status = "error"; message = "S2E code required" } 400
                continue
            }

            $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
            $localPresets = @{}
            if (Test-Path $s2ePresetsFile) {
                try {
                    $jsonText = Get-Content $s2ePresetsFile -Raw -Encoding UTF8
                    $parsedObj = $jsonText | ConvertFrom-Json
                    if ($parsedObj) {
                        foreach ($prop in $parsedObj.PSObject.Properties) {
                            $localPresets[$prop.Name] = $prop.Value
                        }
                    }
                } catch {}
            }

            if ($localPresets.ContainsKey($code)) {
                Send-JsonResponse $response @{ status = "ok"; source = "local"; code = $code; data = $localPresets[$code] }
                continue
            }

            # Fallback to StreamToEarn Cloud API
            try {
                $s2eUrl = "https://api.streamtoearn.io/apiserver/overlay/getpreset/$code"
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                $raw = $wc.DownloadString($s2eUrl)
                if ($raw -and $raw.Trim() -ne '"error"' -and $raw.Trim() -ne 'null') {
                    $parsed = $raw | ConvertFrom-Json
                    if ($parsed -and ($parsed.events -or $parsed._id)) {
                        # Cache locally
                        $localPresets[$code] = $parsed
                        [System.IO.File]::WriteAllText($s2ePresetsFile, ($localPresets | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
                        Send-JsonResponse $response @{ status = "ok"; source = "streamtoearn_cloud"; code = $code; data = $parsed }
                        continue
                    }
                }
            } catch {}

            Send-JsonResponse $response @{
                status = "not_found"
                code = $code
                message = "S2E code $code was not found on StreamToEarn cloud or local presets."
            }
            continue
        }

        # 2f. S2E Preset Save (Register 24-character code)
        if ($reqPath -eq '/api/s2e/save' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $payload = $body | ConvertFrom-Json
                $code = if ($payload._id) { [string]$payload._id } elseif ($payload.id -and $payload.id -match '^[0-9a-fA-F]{24}$') { [string]$payload.id } else {
                    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString("x8")
                    $rand = -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) })
                    ($ts + $rand).ToLower()
                }

                $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
                $localPresets = @{}
                if (Test-Path $s2ePresetsFile) {
                    try {
                        $jsonText = Get-Content $s2ePresetsFile -Raw -Encoding UTF8
                        $parsedObj = $jsonText | ConvertFrom-Json
                        if ($parsedObj) {
                            foreach ($prop in $parsedObj.PSObject.Properties) {
                                $localPresets[$prop.Name] = $prop.Value
                            }
                        }
                    } catch {}
                }

                $payload | Add-Member -MemberType NoteProperty -Name "_id" -Value $code -Force
                $localPresets[$code] = $payload
                [System.IO.File]::WriteAllText($s2ePresetsFile, ($localPresets | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)

                Send-JsonResponse $response @{ status = "ok"; code = $code; message = "Saved S2E preset" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "$_" } 400
            }
            continue
        }

        # 2g. Presets Management (List all, Activate, Save, Duplicate, Delete)
        if ($reqPath -eq '/api/presets' -and $request.HttpMethod -eq 'GET') {
            $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
            $presetsList = @()
            if (Test-Path $s2ePresetsFile) {
                try {
                    $jsonText = Get-Content $s2ePresetsFile -Raw -Encoding UTF8
                    $parsedObj = $jsonText | ConvertFrom-Json
                    if ($parsedObj) {
                        foreach ($prop in $parsedObj.PSObject.Properties) {
                            $item = $prop.Value
                            $item | Add-Member -MemberType NoteProperty -Name "_key" -Value $prop.Name -Force
                            if (-not $item.id) { $item | Add-Member -MemberType NoteProperty -Name "id" -Value $prop.Name -Force }
                            $presetsList += $item
                        }
                    }
                } catch {}
            }
            $activeId = "preset_live_balagbagan"
            if (Test-Path $configFile) {
                try {
                    $cfgObj = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($cfgObj.activePresetId) { $activeId = $cfgObj.activePresetId }
                } catch {}
            }
            Send-JsonResponse $response @{
                status = "ok"
                activePresetId = $activeId
                presets = $presetsList
            }
            continue
        }

        if ($reqPath -eq '/api/presets/activate' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $payload = $body | ConvertFrom-Json
                $presetId = if ($payload.id) { [string]$payload.id } else { "" }
                if (-not $presetId) {
                    Send-JsonResponse $response @{ status = "error"; message = "Preset ID required" } 400
                    continue
                }

                $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
                $foundPreset = $null
                $foundKey = $null
                if (Test-Path $s2ePresetsFile) {
                    $jsonText = Get-Content $s2ePresetsFile -Raw -Encoding UTF8
                    $parsedObj = $jsonText | ConvertFrom-Json
                    foreach ($p in $parsedObj.PSObject.Properties) {
                        $itemPresetId = if ($p.Value.id) { [string]$p.Value.id } else { "" }
                        $itemUId = if ($p.Value._id) { [string]$p.Value._id } else { "" }
                        if ($p.Name -eq $presetId -or $itemPresetId -eq $presetId -or $itemUId -eq $presetId) {
                            $foundPreset = $p.Value
                            $foundKey = $p.Name
                            break
                        }
                    }
                }

                if (-not $foundPreset) {
                    Send-JsonResponse $response @{ status = "error"; message = "Preset not found: $presetId" } 404
                    continue
                }

                # Normalize preset events to guarantee full standard working schema
                $normalizedEvents = Normalize-PresetEvents $foundPreset.events $foundPreset.name

                # Update active config
                $targetPath = Get-UserConfigPath $null
                $cfgObj = if (Test-Path $targetPath) { Get-Content $targetPath -Raw -Encoding UTF8 | ConvertFrom-Json } else {
                    Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
                }

                $cfgObj | Add-Member -MemberType NoteProperty -Name "activePresetId" -Value $foundKey -Force
                $cfgObj.gifts = $normalizedEvents

                $updatedJson = $cfgObj | ConvertTo-Json -Depth 10
                [System.IO.File]::WriteAllText($configFile, $updatedJson, [System.Text.Encoding]::UTF8)
                if ($targetPath -and (Test-Path $targetPath) -and ($targetPath -ne $configFile)) {
                    [System.IO.File]::WriteAllText($targetPath, $updatedJson, [System.Text.Encoding]::UTF8)
                }

                # Update all user configs in user_configs/ so no stale active preset exists anywhere
                if (Test-Path $userConfigsFolder) {
                    Get-ChildItem -Path $userConfigsFolder -Filter "*_config.json" -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            $uCfg = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                            $uCfg | Add-Member -MemberType NoteProperty -Name "activePresetId" -Value $foundKey -Force
                            $uCfg.gifts = $normalizedEvents
                            [System.IO.File]::WriteAllText($_.FullName, ($uCfg | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
                        } catch {}
                    }
                }

                if ($script:cardMilestones) { $script:cardMilestones.Clear() }
                Sync-ConfigToCards
                AddEventLog @{ type = "config_updated"; activePresetId = $foundKey; presetName = $foundPreset.name; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }

                Send-JsonResponse $response @{
                    status = "ok"
                    activePresetId = $foundKey
                    presetName = $foundPreset.name
                    game = $foundPreset.game
                    eventsCount = if ($normalizedEvents) { $normalizedEvents.Count } else { 0 }
                    message = "Preset '$($foundPreset.name)' is now live!"
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "$_" } 400
            }
            continue
        }

        if ($reqPath -eq '/api/presets/save' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $payload = $body | ConvertFrom-Json
                $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
                $localPresets = [ordered]@{}
                if (Test-Path $s2ePresetsFile) {
                    $raw = Get-Content $s2ePresetsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    foreach ($p in $raw.PSObject.Properties) { $localPresets[$p.Name] = $p.Value }
                }

                $saveTargetId = if ($payload.id) { [string]$payload.id } else { ("preset_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) }
                $existingKey = $null
                foreach ($k in $localPresets.Keys) {
                    $val = $localPresets[$k]
                    if ($k -eq $saveTargetId -or ($val.id -and [string]$val.id -eq $saveTargetId) -or ($val._id -and [string]$val._id -eq $saveTargetId)) {
                        $existingKey = $k
                        break
                    }
                }
                $saveKey = if ($existingKey) { $existingKey } else { $saveTargetId }
                $payload | Add-Member -MemberType NoteProperty -Name "_id" -Value $saveKey -Force
                $payload | Add-Member -MemberType NoteProperty -Name "id" -Value $saveKey -Force
                $localPresets[$saveKey] = $payload
                [System.IO.File]::WriteAllText($s2ePresetsFile, ($localPresets | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)

                Send-JsonResponse $response @{ status = "ok"; id = $saveKey; message = "Preset saved successfully" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "$_" } 400
            }
            continue
        }

        if ($reqPath -eq '/api/presets/duplicate' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $payload = $body | ConvertFrom-Json
                $origId = if ($payload.id) { [string]$payload.id } else { "" }
                $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
                $localPresets = [ordered]@{}
                if (Test-Path $s2ePresetsFile) {
                    $raw = Get-Content $s2ePresetsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    foreach ($p in $raw.PSObject.Properties) { $localPresets[$p.Name] = $p.Value }
                }

                $origPreset = $null
                foreach ($k in $localPresets.Keys) {
                    $val = $localPresets[$k]
                    if ($k -eq $origId -or ($val.id -and [string]$val.id -eq $origId) -or ($val._id -and [string]$val._id -eq $origId)) {
                        $origPreset = $val
                        break
                    }
                }

                if (-not $origPreset) {
                    Send-JsonResponse $response @{ status = "error"; message = "Preset not found" } 404
                    continue
                }

                $clone = $origPreset | ConvertTo-Json -Depth 10 | ConvertFrom-Json
                $newId = "preset_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                $clone | Add-Member -MemberType NoteProperty -Name "_id" -Value $newId -Force
                $clone | Add-Member -MemberType NoteProperty -Name "id" -Value $newId -Force
                $clone | Add-Member -MemberType NoteProperty -Name "name" -Value ([string]$clone.name + " (Copy)") -Force
                $clone | Add-Member -MemberType NoteProperty -Name "createdAt" -Value (Get-Date -Format "MM/dd/yyyy") -Force
                $localPresets[$newId] = $clone
                [System.IO.File]::WriteAllText($s2ePresetsFile, ($localPresets | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)

                Send-JsonResponse $response @{ status = "ok"; newId = $newId; preset = $clone; message = "Preset duplicated successfully" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "$_" } 400
            }
            continue
        }

        if ($reqPath -eq '/api/presets/delete' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $payload = $body | ConvertFrom-Json
                $delId = if ($payload.id) { [string]$payload.id } else { "" }
                $s2ePresetsFile = Join-Path $folder "s2e_presets.json"
                $localPresets = [ordered]@{}
                $deletedCount = 0
                if (Test-Path $s2ePresetsFile) {
                    $raw = Get-Content $s2ePresetsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    foreach ($p in $raw.PSObject.Properties) {
                        $itemPresetId = if ($p.Value.id) { [string]$p.Value.id } else { "" }
                        $itemUId = if ($p.Value._id) { [string]$p.Value._id } else { "" }
                        $matches = ($p.Name -eq $delId) -or ($itemPresetId -eq $delId) -or ($itemUId -eq $delId)
                        if ($matches) {
                            $deletedCount++
                        } else {
                            $localPresets[$p.Name] = $p.Value
                        }
                    }
                }
                [System.IO.File]::WriteAllText($s2ePresetsFile, ($localPresets | ConvertTo-Json -Depth 10), [System.Text.Encoding]::UTF8)
                Send-JsonResponse $response @{ status = "ok"; id = $delId; deletedCount = $deletedCount; message = "Preset deleted successfully" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = "$_" } 400
            }
            continue
        }

        # 3. Units Catalog (with merged Custom Community Gifts & Regional Metadata)
        if ($reqPath -eq '/api/catalog') {
            try {
                $rawCatalog = if (Test-Path $catalogFile) { [System.IO.File]::ReadAllText($catalogFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json } else { [PSCustomObject]@{} }
                
                # Merge custom community gifts into tiktokGifts array
                $commGifts = Load-CustomCommunityGifts
                if ($commGifts -and $commGifts.Count -gt 0 -and $rawCatalog.tiktokGifts) {
                    $existingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                    foreach ($tg in $rawCatalog.tiktokGifts) {
                        if ($tg.id) { [void]$existingIds.Add([string]$tg.id) }
                    }
                    $mergedList = [System.Collections.ArrayList]::new(@($rawCatalog.tiktokGifts))
                    foreach ($cg in $commGifts) {
                        if ($cg.id -and -not $existingIds.Contains([string]$cg.id)) {
                            [void]$mergedList.Add($cg)
                            [void]$existingIds.Add([string]$cg.id)
                        }
                    }
                    $rawCatalog.tiktokGifts = @($mergedList)
                }

                # Attach detected region info
                $rawCatalog | Add-Member -NotePropertyName region -NotePropertyValue $script:regionConfig -Force
                $rawCatalog | Add-Member -NotePropertyName communityGifts -NotePropertyValue $commGifts -Force

                Send-JsonResponse $response $rawCatalog
            } catch {
                $content = if (Test-Path $catalogFile) { [System.IO.File]::ReadAllText($catalogFile, [System.Text.Encoding]::UTF8) } else { "{}" }
                Send-JsonResponse $response $content
            }
            continue
        }

        # 3e. Region Detection & Settings API
        if ($reqPath -eq '/api/region') {
            if ($request.HttpMethod -eq 'GET') {
                # Auto-refresh detection if autoDetect is enabled and stale or not yet detected
                if ($script:regionConfig.autoDetect) {
                    $needsDetect = $false
                    if (-not $script:regionConfig.detectedRegion) {
                        $needsDetect = $true
                    } elseif ($script:regionConfig.detectedRegion.updatedAt) {
                        try {
                            $lastDt = [DateTime]::Parse($script:regionConfig.detectedRegion.updatedAt)
                            if (([DateTime]::UtcNow - $lastDt).TotalHours -ge 2) { $needsDetect = $true }
                        } catch { $needsDetect = $true }
                    }
                    if ($needsDetect) {
                        $det = Detect-SystemRegion
                        $script:regionConfig.detectedRegion = $det
                        $script:regionConfig.selectedRegion = $det.countryCode
                        Save-RegionConfig $script:regionConfig
                    }
                }
                Send-JsonResponse $response @{
                    status = "ok"
                    region = $script:regionConfig.detectedRegion
                    config = $script:regionConfig
                }
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $data = $body | ConvertFrom-Json
                    if ($data.autoDetect -ne $null) {
                        $script:regionConfig.autoDetect = [bool]$data.autoDetect
                    }
                    if ($data.region -and [string]$data.region.Trim()) {
                        $script:regionConfig.selectedRegion = [string]$data.region.Trim().ToUpper()
                    }
                    if ($data.redetect -eq $true -or $script:regionConfig.autoDetect) {
                        $det = Detect-SystemRegion
                        $script:regionConfig.detectedRegion = $det
                        if ($script:regionConfig.autoDetect) {
                            $script:regionConfig.selectedRegion = $det.countryCode
                        }
                    }
                    Save-RegionConfig $script:regionConfig
                    AddEventLog @{ type = "region_update"; region = $script:regionConfig }
                    Send-JsonResponse $response @{
                        status = "ok"
                        message = "Region updated"
                        region = $script:regionConfig.detectedRegion
                        config = $script:regionConfig
                    }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        if ($reqPath -eq '/api/region/report' -and $request.HttpMethod -eq 'POST') {
            # TikTok Bridge reports streamer's room/account locale discovered from TikTok Webcast API
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                if ($data.countryCode) {
                    $cCode = [string]$data.countryCode.ToUpper()
                    $flagMap = @{ "PH"="🇵🇭"; "US"="🇺🇸"; "ID"="🇮🇩"; "MY"="🇲🇾"; "VN"="🇻🇳"; "TH"="🇹🇭"; "SG"="🇸🇬"; "GB"="🇬🇧"; "BR"="🇧🇷" }
                    $fl = if ($flagMap.ContainsKey($cCode)) { $flagMap[$cCode] } else { "🌐" }
                    $script:regionConfig.detectedRegion = [PSCustomObject]@{
                        countryCode = $cCode
                        countryName = if ($data.countryName) { [string]$data.countryName } else { $cCode }
                        flag = $fl
                        detectedMethod = "tiktok_api"
                        updatedAt = [DateTime]::UtcNow.ToString("o")
                    }
                    if ($script:regionConfig.autoDetect) {
                        $script:regionConfig.selectedRegion = $cCode
                    }
                    Save-RegionConfig $script:regionConfig
                }
                Send-JsonResponse $response @{ status = "ok"; message = "TikTok region reported" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
            }
            continue
        }

        # 3f. Custom Community Gifts API
        if ($reqPath -eq '/api/gifts/community') {
            if ($request.HttpMethod -eq 'GET') {
                $commGifts = Load-CustomCommunityGifts
                Send-JsonResponse $response @{ status = "ok"; gifts = $commGifts }
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $newGift = $body | ConvertFrom-Json
                    if (-not $newGift.name) {
                        Send-JsonResponse $response @{ status = "error"; message = "Gift name is required" } 400
                        continue
                    }
                    $commList = [System.Collections.ArrayList]::new(@(Load-CustomCommunityGifts))
                    $giftId = if ($newGift.id) { [string]$newGift.id } else { "comm_$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())" }
                    $item = [PSCustomObject]@{
                        id = $giftId
                        name = [string]$newGift.name
                        coins = if ($newGift.coins) { [int]$newGift.coins } else { 1 }
                        icon = if ($newGift.icon) { [string]$newGift.icon } else { "images/tiktok-gifts/5655_rose.webp" }
                        isCommunity = $true
                        source = if ($newGift.source) { [string]$newGift.source } else { "custom_manual" }
                        addedAt = [DateTime]::UtcNow.ToString("o")
                    }
                    # Update if exists, else append
                    $foundIdx = -1
                    for ($i = 0; $i -lt $commList.Count; $i++) {
                        if ([string]$commList[$i].id -eq $giftId -or [string]$commList[$i].name.ToLower() -eq [string]$newGift.name.ToLower()) {
                            $foundIdx = $i; break
                        }
                    }
                    if ($foundIdx -ge 0) {
                        $commList[$foundIdx] = $item
                    } else {
                        [void]$commList.Add($item)
                    }
                    $script:customCommunityGifts = @($commList)
                    Save-CustomCommunityGifts $script:customCommunityGifts
                    AddEventLog @{ type = "community_gift_added"; gift = $item }
                    Send-JsonResponse $response @{ status = "ok"; message = "Community gift saved"; gift = $item; total = $commList.Count }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        if ($reqPath -eq '/api/gifts/community-sync' -and $request.HttpMethod -eq 'POST') {
            # TikTok Bridge automatically pushes live room gifts discovered via TikTok Webcast API
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $incoming = if ($data.gifts) { @($data.gifts) } else { @() }
                $commList = [System.Collections.ArrayList]::new(@(Load-CustomCommunityGifts))
                $existingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($g in $commList) { if ($g.id) { [void]$existingIds.Add([string]$g.id) } }

                $addedCount = 0
                foreach ($ig in $incoming) {
                    if ($ig.id -and -not $existingIds.Contains([string]$ig.id)) {
                        $item = [PSCustomObject]@{
                            id = [string]$ig.id
                            name = [string]$ig.name
                            coins = if ($ig.coins) { [int]$ig.coins } elseif ($ig.diamond_count) { [int]$ig.diamond_count } else { 1 }
                            icon = if ($ig.icon) { [string]$ig.icon } else { "" }
                            isCommunity = $true
                            source = "tiktok_live_room"
                            addedAt = [DateTime]::UtcNow.ToString("o")
                        }
                        [void]$commList.Add($item)
                        [void]$existingIds.Add([string]$ig.id)
                        $addedCount++
                    }
                }
                if ($addedCount -gt 0) {
                    $script:customCommunityGifts = @($commList)
                    Save-CustomCommunityGifts $script:customCommunityGifts
                    AddEventLog @{ type = "community_gifts_synced"; added = $addedCount; total = $commList.Count }
                }
                Send-JsonResponse $response @{ status = "ok"; added = $addedCount; total = $commList.Count }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
            }
            continue
        }

        # 3g. On-Screen Trigger Counter API
        if ($reqPath -eq '/api/trigger-counter') {
            if ($request.HttpMethod -eq 'GET') {
                $st = if ($script:triggerCounterState) { $script:triggerCounterState } else { Load-TriggerCounterState }
                Send-JsonResponse $response $st
                continue
            }
        }

        if ($reqPath -eq '/api/trigger-counter/reset' -and $request.HttpMethod -eq 'POST') {
            $script:triggerCounterState = [PSCustomObject]@{
                totalTriggers = 0
                streak = 0
                lastTriggerTime = 0
                goal = if ($script:triggerCounterState -and $script:triggerCounterState.goal) { $script:triggerCounterState.goal } else { 100 }
                goalTitle = if ($script:triggerCounterState -and $script:triggerCounterState.goalTitle) { $script:triggerCounterState.goalTitle } else { "Mega Wave Boss" }
                gifts = [PSCustomObject]@{}
                recentTriggers = @()
            }
            Save-TriggerCounterState
            AddEventLog @{ type = "trigger_counter"; totalTriggers = 0; streak = 0 }
            Send-JsonResponse $response @{ status = "ok"; message = "Trigger counter reset"; state = $script:triggerCounterState }
            continue
        }

        if ($reqPath -eq '/api/trigger-counter/goal' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                if ($data.goal -ne $null) {
                    $script:triggerCounterState.goal = [int]$data.goal
                }
                if ($data.goalTitle) {
                    $script:triggerCounterState.goalTitle = [string]$data.goalTitle
                }
                Save-TriggerCounterState
                Send-JsonResponse $response @{ status = "ok"; state = $script:triggerCounterState }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
            }
            continue
        }

        if ($reqPath -eq '/api/trigger-counter/test' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = try { $body | ConvertFrom-Json } catch { $null }
            $tUser = if ($data -and $data.username) { [string]$data.username } else { "RENEarn_Supporter" }
            $tGift = if ($data -and $data.giftName) { [string]$data.giftName } else { "Rose" }
            $tId = if ($data -and $data.giftId) { [string]$data.giftId } else { "5655" }
            $tCount = if ($data -and $data.count) { [int]$data.count } else { 5 }
            $tIcon = if ($data -and $data.icon) { [string]$data.icon } else { "images/tiktok-gifts/5655_rose.webp" }
            $tLabel = if ($data -and $data.label) { [string]$data.label } else { "Spawn Blazer Snipea (1167)" }
            Record-TriggerEvent $tGift $tId $tCount $tUser "images/default_avatar.svg" $tIcon $tLabel
            Send-JsonResponse $response @{ status = "ok"; message = "Test trigger event fired"; state = $script:triggerCounterState }
            continue
        }

        # 3h. Interactive Gift Jar Overlay Endpoints
        if ($reqPath -eq '/api/jar/settings') {
            if ($request.HttpMethod -eq 'GET') {
                $st = if ($script:jarSettings) { $script:jarSettings } else { Load-JarSettings }
                Send-JsonResponse $response $st
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $newSt = $body | ConvertFrom-Json
                    $script:jarSettings = $newSt
                    Save-JarSettings $newSt
                    AddEventLog @{ type = "jar_settings_update"; settings = $newSt }
                    Send-JsonResponse $response @{ status = "ok"; message = "Jar settings saved"; settings = $newSt }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        if ($reqPath -eq '/api/jar/state' -and $request.HttpMethod -eq 'GET') {
            $st = if ($script:jarState) { $script:jarState } else { Load-JarState }
            Send-JsonResponse $response $st
            continue
        }

        if ($reqPath -eq '/api/jar/reset' -and $request.HttpMethod -eq 'POST') {
            $script:jarState = [PSCustomObject]@{
                currentCount = 0
                totalCoins = 0
                isFull = $false
                lastDropTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                recentDrops = @()
            }
            Save-JarState $script:jarState
            AddEventLog @{ type = "jar_reset" }
            Send-JsonResponse $response @{ status = "ok"; message = "Jar reset triggered"; state = $script:jarState }
            continue
        }

        if ($reqPath -eq '/api/jar/drop' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = try { $body | ConvertFrom-Json } catch { $null }
            $gName = if ($data -and $data.giftName) { [string]$data.giftName } else { "Gift" }
            $gId = if ($data -and $data.giftId) { [string]$data.giftId } else { "" }
            $gIcon = if ($data -and $data.icon) { [string]$data.icon } else { "" }
            if (-not $gIcon -and $script:verifiedGiftsCatalog) {
                $autoGift = Resolve-AutoCorrectGift $gName $gId
                if ($autoGift -and $autoGift.icon) { $gIcon = [string]$autoGift.icon }
                elseif ($autoGift -and $autoGift.cdnIcon) { $gIcon = [string]$autoGift.cdnIcon }
                else {
                    $vg = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq $gId -or [string]$_.name -eq $gName } | Select-Object -First 1
                    if ($vg -and $vg.icon) { $gIcon = [string]$vg.icon }
                    elseif ($vg -and $vg.cdnIcon) { $gIcon = [string]$vg.cdnIcon }
                }
            }
            if (-not $gIcon -or $gIcon -eq "images/default_avatar.svg") {
                if ($gName -match '(?i)heart') { $gIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                elseif ($gName -match '(?i)ice') { $gIcon = "images/tiktok-gifts/5827_ice_cream_cone.webp" }
                elseif ($gName -match '(?i)tiktok') { $gIcon = "images/tiktok-gifts/5269_tiktok.webp" }
                elseif ($gName -match '(?i)cap') { $gIcon = "images/tiktok-gifts/6104_cap.webp" }
                elseif ($gName -match '(?i)gg') { $gIcon = "images/tiktok-gifts/6064_gg.webp" }
                elseif ($gName -match '(?i)doughnut|donut') { $gIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                else { $gIcon = "images/tiktok-gifts/5655_rose.webp" }
            }
            if ($gName -eq "Gift" -or -not $gName) {
                $gName = "Rose"
            }
            $dropId = if ($data -and $data.id) { [string]$data.id } else { [System.Guid]::NewGuid().ToString() }
            $gCount = if ($data -and $data.count) { [int]$data.count } else { 1 }
            $gCoins = if ($data -and $data.coins) { [int]$data.coins } else { 1 }
            $uName = if ($data -and $data.username) { [string]$data.username } else { "RENEarn_Viewer" }
            $uAvatar = if ($data -and $data.avatar) { [string]$data.avatar } else { "images/default_avatar.svg" }

            # 1. Update Leaderboard score for gifter
            Update-LeaderboardCoins $uName $gCoins $uAvatar

            # 2. Add Event Log for jar drop and leaderboard update
            AddEventLog @{
                id = $dropId
                type = "jar_drop"
                giftName = $gName
                giftId = $gId
                icon = $gIcon
                count = $gCount
                coins = $gCoins
                username = $uName
                avatar = $uAvatar
            }
            AddEventLog @{
                type = "leaderboard_update"
                updateType = "coins"
                username = $uName
                coins = $gCoins
                avatar = $uAvatar
            }
            if ($script:jarState) {
                $script:jarState.currentCount += $gCount
                $script:jarState.totalCoins += $gCoins
                $script:jarState.lastDropTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                Save-JarState $script:jarState
            }
            Send-JsonResponse $response @{ status = "ok"; message = "Gift dropped into jar"; state = $script:jarState; dropId = $dropId }
            continue
        }

        if ($reqPath -eq '/api/jar/full-trigger' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = try { $body | ConvertFrom-Json } catch { $null }
            $cmd = if ($data -and $data.command) { [string]$data.command } else { "spawn_fire_cattail" }
            SendToPvZGame "plant" $cmd 1 "Gift Jar Celebration" | Out-Null
            AddEventLog @{ type = "gift"; label = "Jar Full Celebration: $cmd"; command = $cmd; amount = 1; username = "Gift Jar Celebration" }
            Send-JsonResponse $response @{ status = "ok"; message = "Jar full reward triggered in game" }
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
                $callerRole = Get-CallerRole $request
                if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                    Send-JsonResponse $response @{ status = "error"; message = "Access denied: Viewers cannot modify leaderboard settings." } 403
                    continue
                }
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
            $callerRole = Get-CallerRole $request
            if ($callerRole -ne "admin" -and $callerRole -ne "editor") {
                Send-JsonResponse $response @{ status = "error"; message = "Access denied: Viewers cannot reset leaderboard." } 403
                continue
            }
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
            $sampleNames = @("Omodox", "Gonta", "Sahavovo", "Wolfich", "Stasie", "jendeRENO", "Top 7", "Top 8", "Top 9", "Top 10")
            $mockAvatars = @(
                "images/game-icons/pvz/spawn_ultimatecattail.webp",
                "images/game-icons/pvz/ultimate_gold_gargantuar.webp",
                "images/game-icons/pvz/spawn_gatlingpea.webp",
                "images/game-icons/pvz/spawn_cherrybomb.webp",
                "images/game-icons/pvz/spawn_repeater.webp",
                "images/game-icons/pvz/spawn_peashooter.webp"
            )

            if ($testType -eq "single") {
                $u = if ($data.username) { $data.username } else { "SuperGifter" }
                $v = if ($data.value) { [int]$data.value } else { 100 }
                $av = if ($data.avatar) { $data.avatar } else { $mockAvatars[0] }
                $t = if ($data.target) { $data.target } else { "coins" }
                if ($t -eq "likes") {
                    Update-LeaderboardLikes $u $v $av
                } else {
                    Update-LeaderboardCoins $u $v $av
                }
            } elseif ($testType -eq "overtake") {
                $u = if ($data.username) { $data.username } else { "👑 NewLeader" }
                $currentTop = Get-LeaderboardTop "coins" 1
                $topVal = if ($currentTop -and $currentTop.Count -gt 0 -and $currentTop[0].value) { [int]$currentTop[0].value } else { 2840 }
                $overtakeVal = $topVal + 250
                $av = $mockAvatars[1]
                Update-LeaderboardCoins $u $overtakeVal $av
            } else {
                # Matches Reference Image 1 exactly
                $cValues = @(2840, 2310, 1750, 1420, 980, 620, 0, 0, 0, 0)
                $lValues = @(1540, 2210, 960, 480, 320, 96, 0, 0, 0, 0)
                for ($idx = 0; $idx -lt 6; $idx++) {
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
            AddEventLog @{ type = "leaderboard_update"; testType = $testType }
            Send-JsonResponse $response @{ status = "ok"; message = "Leaderboard updated successfully"; testType = $testType }
            continue
        }

        # 4. Trigger Game Action
        if ($reqPath -eq '/api/game/trigger') {
            $body = ReadRequestBody $request

            $data = $body | ConvertFrom-Json
            $actionType = if ($data.actionType) { $data.actionType } else { "custom" }
            $command = $data.command
            $repetition = if ($data.repetition) { [int]$data.repetition } elseif ($data.amount) { [int]$data.amount } else { 1 }
            $amount = if ($data.amount) { [int]$data.amount } else { $repetition }
            $username = if ($data.username) { $data.username } else { "RENEarn" }
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
            $username = if ($data.username -and $data.username -notin @("TestGifter", "Tester", "TestViewer", "StreamViewer", "Viewer", "Streamer", "SocialTester", "User", "")) { $data.username } else { "RENEarn" }
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
                    groupId = if ($targetSpinner) { [string]$targetSpinner.groupId } else { "1" }
                    $reqMode = if ($request.QueryString['mode']) { $request.QueryString['mode'] } elseif ($targetSpinner -and $targetSpinner.mode) { $targetSpinner.mode } else { "wheel" }
                mode = $reqMode
                    wheelTheme = if ($targetSpinner -and $targetSpinner.wheelTheme) { $targetSpinner.wheelTheme } else { "casino_royale" }
                    centerFinial = if ($targetSpinner -and $targetSpinner.centerFinial) { $targetSpinner.centerFinial } else { "turret_3d" }
                    pointerTheme = if ($targetSpinner -and $targetSpinner.pointerTheme) { $targetSpinner.pointerTheme } else { "brass_chevron" }
                    wheelRarityStyle = if ($targetSpinner -and $targetSpinner.wheelRarityStyle) { $targetSpinner.wheelRarityStyle } else { "rarity_enamel" }
                    reelTheme = if ($targetSpinner -and $targetSpinner.reelTheme) { $targetSpinner.reelTheme } else { "casino_felt" }
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
                        groupId = if ($matchedCardSpinner) { [string]$matchedCardSpinner.groupId } else { "1" }
                        mode = if ($matchedCardSpinner -and $matchedCardSpinner.mode) { $matchedCardSpinner.mode } else { "wheel" }
                        wheelTheme = if ($matchedCardSpinner -and $matchedCardSpinner.wheelTheme) { $matchedCardSpinner.wheelTheme } else { "casino_royale" }
                        centerFinial = if ($matchedCardSpinner -and $matchedCardSpinner.centerFinial) { $matchedCardSpinner.centerFinial } else { "turret_3d" }
                        pointerTheme = if ($matchedCardSpinner -and $matchedCardSpinner.pointerTheme) { $matchedCardSpinner.pointerTheme } else { "brass_chevron" }
                        wheelRarityStyle = if ($matchedCardSpinner -and $matchedCardSpinner.wheelRarityStyle) { $matchedCardSpinner.wheelRarityStyle } else { "rarity_enamel" }
                        reelTheme = if ($matchedCardSpinner -and $matchedCardSpinner.reelTheme) { $matchedCardSpinner.reelTheme } else { "casino_felt" }
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
                branding = "RENEarn"
                embedTitle = "RENEarn Interactive Stream Engine"
                gameId = if ($data.gameId) { $data.gameId } else { "pvz_fusion_4" }
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
                brand = "RENEarn"
                embedTitle = "RENEarn Interactive Stream Engine"
                gameExecuted = $exec.success
                event = $logEntry
            }
            Send-JsonResponse $response $resObj
            continue
        }

        # 6.5. RENEarn Active Game Engine & Universal Presets Endpoints
        if ($reqPath -eq '/api/games/active') {
            if ($request.HttpMethod -eq 'GET') {
                $activeId = if ($script:renearnActiveGameId) { $script:renearnActiveGameId } else { "pvz_fusion_4" }
                Send-JsonResponse $response @{ brand = "RENEarn"; activeGameId = $activeId; status = "connected" }
                continue
            }
            if ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $d = $body | ConvertFrom-Json
                    if ($d.gameId) { $script:renearnActiveGameId = [string]$d.gameId }
                    Send-JsonResponse $response @{ brand = "RENEarn"; activeGameId = $script:renearnActiveGameId; status = "success" }
                } catch {
                    Send-JsonResponse $response @{ error = $_.Exception.Message } 400
                }
                continue
            }
        }

        if ($reqPath -eq '/api/presets/apply' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $d = $body | ConvertFrom-Json
                $script:renearnActivePresetId = if ($d.presetId) { [string]$d.presetId } else { "classic_streamer" }
                AddEventLog @{
                    type = "preset_applied"
                    brand = "RENEarn"
                    presetId = $script:renearnActivePresetId
                    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
                Send-JsonResponse $response @{ brand = "RENEarn"; presetId = $script:renearnActivePresetId; status = "applied" }
            } catch {
                Send-JsonResponse $response @{ error = $_.Exception.Message } 400
            }
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

                # Server-side fast debounce: prevent accidental duplicate keystrokes while staying ultra responsive
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
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } elseif ($request.QueryString['user']) { $request.QueryString['user'] } else { "" }
            $config = LoadConfig $callerEmail
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
            if ($slices.Count -eq 0 -and (Test-Path $templateConfigFile)) {
                try {
                    $tmpl = Get-Content $templateConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($tmpl -and $tmpl.spinners -and $tmpl.spinners.Count -gt 0) {
                        $targetSpinner = $tmpl.spinners[0]
                        $slices = $targetSpinner.slices
                    }
                } catch {}
            }
            $pickedSlice = $null
            $sliceId = $request.QueryString['sliceId']
            if ($sliceId -and $slices.Count -gt 0) {
                $matched = $slices | Where-Object { [string]$_.id -eq [string]$sliceId } | Select-Object -First 1
                if ($matched) {
                    $pickedSlice = $matched
                }
            }
            if (-not $pickedSlice -and $slices.Count -gt 0) {
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

            $username = if ($request.QueryString['username']) { $request.QueryString['username'] } elseif ($request.QueryString['user']) { $request.QueryString['user'] } else { "RENEarn" }
            if (-not $username -or $username -in @("User", "Tester", "TestViewer", "Streamer", "StreamViewer", "SocialTester", "TestGifter", "")) { $username = "RENEarn" }
            $cleanUserKey = ($username.ToLower() -replace '[^a-z0-9]', '')
            $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

            $avatar = if ($request.QueryString['avatar']) { $request.QueryString['avatar'] } else { "images/default_avatar.svg" }
            $noGame = ($request.QueryString['noGameTrigger'] -eq 'true')
            
            $exec = @{ success = $true }
            $spHide = $false
            if ($pickedSlice -and -not $noGame) {
                if ($pickedSlice.actionType -and $pickedSlice.actionType -ne "score" -and $pickedSlice.command) {
                    $spReps = if ($pickedSlice.repetition) { [int]$pickedSlice.repetition } elseif ($pickedSlice.amount) { [int]$pickedSlice.amount } else { 1 }
                    $spDelay = if ($pickedSlice.delay) { [int]$pickedSlice.delay } else { 0 }
                    $spInterval = if ($pickedSlice.interval) { [int]$pickedSlice.interval } else { 100 }
                    $spHide = ($pickedSlice.hideInOverlay -eq $true -or $pickedSlice.hideInOverlay -eq "true")
                    $spAmount = if ($pickedSlice.amount) { [int]$pickedSlice.amount } else { $spReps }
                    $exec = SendToPvZGame $pickedSlice.actionType $pickedSlice.command $spAmount $username "" $spReps $spDelay $spInterval
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
                mode = if ($request.QueryString['mode']) { $request.QueryString['mode'] } elseif ($targetSpinner -and $targetSpinner.mode) { $targetSpinner.mode } else { "wheel" }
                wheelTheme = if ($targetSpinner -and $targetSpinner.wheelTheme) { $targetSpinner.wheelTheme } else { "casino_royale" }
                centerFinial = if ($targetSpinner -and $targetSpinner.centerFinial) { $targetSpinner.centerFinial } else { "turret_3d" }
                pointerTheme = if ($targetSpinner -and $targetSpinner.pointerTheme) { $targetSpinner.pointerTheme } else { "brass_chevron" }
                wheelRarityStyle = if ($targetSpinner -and $targetSpinner.wheelRarityStyle) { $targetSpinner.wheelRarityStyle } else { "rarity_enamel" }
                reelTheme = if ($targetSpinner -and $targetSpinner.reelTheme) { $targetSpinner.reelTheme } else { "casino_felt" }
                duration = $spDuration
                ticks = $spTicks
                pointerIcon = $spPointer
                slices = $slices
                username = $username
                avatar = $avatar
                hideInOverlay = $spHide
                success = $exec.success
                winWidgetScore = $script:winWidget.score
                winWidget = $script:winWidget
            }
            AddEventLog $logEntry

            # Record in Spinner History system
            $targetSpinnerId = if ($targetSpinner -and $targetSpinner.id) { [string]$targetSpinner.id } else { "1" }
            Add-SpinnerHistoryRecord $username $avatar $pickedSlice $spName $targetSpinnerId

            $resObj = @{
                status = "ok"
                eventId = $logEntry["id"]
                winner = $pickedSlice
                spinner = $targetSpinner
                username = $username
                avatar = $avatar
                gameExecuted = $exec.success
                winWidgetScore = $script:winWidget.score
                winWidget = $script:winWidget
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
                
                # Check for community gifts sync event from TikTok bridge
                if ($payload.event -eq "community_gifts_sync" -or $payload.event -eq "sync_gifts") {
                    $incoming = if ($payload.gifts) { @($payload.gifts) } else { @() }
                    $commList = [System.Collections.ArrayList]::new(@(Load-CustomCommunityGifts))
                    $existingIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                    foreach ($g in $commList) { if ($g.id) { [void]$existingIds.Add([string]$g.id) } }

                    $addedCount = 0
                    foreach ($ig in $incoming) {
                        if ($ig.id -and -not $existingIds.Contains([string]$ig.id)) {
                            $item = [PSCustomObject]@{
                                id = [string]$ig.id
                                name = [string]$ig.name
                                coins = if ($ig.coins) { [int]$ig.coins } elseif ($ig.diamond_count) { [int]$ig.diamond_count } else { 1 }
                                icon = if ($ig.icon) { [string]$ig.icon } else { "" }
                                isCommunity = $true
                                source = "tiktok_live_room"
                                addedAt = [DateTime]::UtcNow.ToString("o")
                            }
                            [void]$commList.Add($item)
                            [void]$existingIds.Add([string]$ig.id)
                            $addedCount++
                        }
                    }
                    if ($addedCount -gt 0) {
                        $script:customCommunityGifts = @($commList)
                        Save-CustomCommunityGifts $script:customCommunityGifts
                    }
                    Send-JsonResponse $response @{ status = "ok"; message = "Community gifts synced"; added = $addedCount; total = $commList.Count }
                    continue
                }

                # Check if it is a gift event
                if ($payload.event -eq "gift") {
                    $giftName = $payload.giftName
                    $giftId = $payload.giftId
                    $repeatCount = if ($payload.repeatCount) { [int]$payload.repeatCount } else { 1 }
                    $user = if ($payload.username) { [string]$payload.username } elseif ($payload.nickname) { [string]$payload.nickname } elseif ($payload.uniqueId) { [string]$payload.uniqueId } else { "" }
                    # If this is a tester simulation event or missing username, use RENEarn. If live on TikTok, real gifter name is kept!
                    if (-not $user -or $user -in @("User", "TestViewer", "TestGifter", "Tester", "SocialTester", "StreamViewer", "Viewer", "Streamer", "")) {
                        $user = "RENEarn"
                    }
                    $avatar = if ($payload.profilePictureUrl) { $payload.profilePictureUrl } elseif ($payload.avatar) { $payload.avatar } elseif ($payload.avatarUrl) { $payload.avatarUrl } else { "images/default_avatar.svg" }
                    $icon = if ($payload.giftPictureUrl) { $payload.giftPictureUrl } else { "" }

                    # SECONDARY DEDUPLICATION SAFEGUARD:
                    # Filter out duplicate streak echoes and rapid socket retransmissions
                    $cleanUserKey = ($user.ToLower() -replace '[^a-z0-9]', '')
                    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    $totReps = if ($payload.totalRepeatCount) { [int]$payload.totalRepeatCount } else { [int]$repeatCount }
                    $giftStreakKey = "$cleanUserKey`_$giftId`_$totReps"
                    if ($cleanUserKey -and $script:recentGiftDeduplication.ContainsKey($giftStreakKey)) {
                        $lastGiftTime = [int64]$script:recentGiftDeduplication[$giftStreakKey]
                        if (($nowMs - $lastGiftTime) -lt 8000) {
                            Send-JsonResponse $response @{ status = "ok"; message = "Debounced duplicate streak packet ($user $giftName x$totReps)"; debounced = $true }
                            continue
                        }
                    }
                    if ($cleanUserKey) { $script:recentGiftDeduplication[$giftStreakKey] = $nowMs }

                    # Auto-correct incoming gift against verified catalog & aliases
                    $autoGift = Resolve-AutoCorrectGift $giftName $giftId
                    if ($autoGift) {
                        if (-not $giftId -or [string]$giftId.Trim() -eq "" -or [string]$giftId.Trim() -eq "0") {
                            $giftId = [string]$autoGift.id
                        }
                        if (-not $giftName -or [string]$giftName.Trim() -eq "" -or $giftName -eq "Gift") {
                            $giftName = [string]$autoGift.name
                        }
                        if (-not $icon -and $autoGift.icon) {
                            $icon = [string]$autoGift.icon
                        }
                    }

                    # LEADERBOARD: Track coins accurately for this gift
                    $giftCoinValue = 0
                    if ($payload.coins -ne $null -and [int]$payload.coins -gt 0) {
                        $giftCoinValue = [int]$payload.coins
                    } elseif ($payload.diamondCount -ne $null -and [int]$payload.diamondCount -gt 0) {
                        $giftCoinValue = [int]$payload.diamondCount * $repeatCount
                    } elseif ($autoGift -and $autoGift.coins -and [int]$autoGift.coins -gt 0) {
                        $giftCoinValue = [int]$autoGift.coins * $repeatCount
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

                    # INTERACTIVE GIFT JAR: Physically drop every incoming TikTok gift into the jar!
                    $dropCount = [Math]::Max(1, $repeatCount)
                    $jarIcon = if ($icon) { $icon } else { "" }
                    if (-not $jarIcon -and $script:verifiedGiftsCatalog) {
                        $autoGift = Resolve-AutoCorrectGift $giftName $giftId
                        if ($autoGift -and $autoGift.icon) { $jarIcon = [string]$autoGift.icon }
                        elseif ($autoGift -and $autoGift.cdnIcon) { $jarIcon = [string]$autoGift.cdnIcon }
                        else {
                            $vg = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq [string]$giftId -or [string]$_.name -eq [string]$giftName } | Select-Object -First 1
                            if ($vg -and $vg.icon) { $jarIcon = [string]$vg.icon }
                            elseif ($vg -and $vg.cdnIcon) { $jarIcon = [string]$vg.cdnIcon }
                        }
                    }
                    if (-not $jarIcon -or $jarIcon -eq "images/default_avatar.svg") {
                        if ($giftName -match '(?i)heart') { $jarIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                        elseif ($giftName -match '(?i)ice') { $jarIcon = "images/tiktok-gifts/5827_ice_cream_cone.webp" }
                        elseif ($giftName -match '(?i)tiktok') { $jarIcon = "images/tiktok-gifts/5269_tiktok.webp" }
                        elseif ($giftName -match '(?i)cap') { $jarIcon = "images/tiktok-gifts/6104_cap.webp" }
                        elseif ($giftName -match '(?i)gg') { $jarIcon = "images/tiktok-gifts/6064_gg.webp" }
                        elseif ($giftName -match '(?i)doughnut|donut') { $jarIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                        else { $jarIcon = "images/tiktok-gifts/5655_rose.webp" }
                    }
                    AddEventLog @{
                        type = "jar_drop"
                        giftName = if ($giftName) { $giftName } else { "Gift" }
                        giftId = if ($giftId) { [string]$giftId } else { "" }
                        icon = $jarIcon
                        count = $dropCount
                        coins = $giftCoinValue
                        username = $user
                        avatar = $avatar
                    }
                    if ($script:jarState) {
                        $script:jarState.currentCount += $dropCount
                        $script:jarState.totalCoins += $giftCoinValue
                        $script:jarState.lastDropTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                        Save-JarState $script:jarState
                    }

                    # HEART ME & GIFT DEDUPLICATION:
                    # TikTok allows only 1 Heart Me gift per person per day! Enforce strictly 1 spin per person per day!
                    $isHeartMeGift = ($giftId -eq '7934' -or $giftName -match '(?i)heart\s*me')
                    $cleanUserKey = ($user.ToLower() -replace '[^a-z0-9]', '')
                    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

                    $todayStr = [DateTime]::UtcNow.ToString("yyyyMMdd")
                    if ($script:heartMeUsersDate -ne $todayStr) {
                        $script:heartMeUsersDate = $todayStr
                        if ($script:heartMeUsersToday) { $script:heartMeUsersToday.Clear() }
                    }

                    if ($isHeartMeGift) {
                        if ($cleanUserKey -and $script:heartMeUsersToday.ContainsKey($cleanUserKey)) {
                            # Strictly 1 spin per person per day for Heart Me!
                            Send-JsonResponse $response @{ status = "ok"; message = "Heart Me already processed for $user today (strictly 1 spin per person per day)"; debounced = $true }
                            continue
                        }
                        if ($cleanUserKey) { $script:heartMeUsersToday[$cleanUserKey] = $nowMs }
                    }

                    # General duplicate debounce (1200ms to eliminate rapid duplicate webhooks)
                    if ($cleanUserKey -and $script:recentSpins.ContainsKey($cleanUserKey)) {
                        $lastTime = [int64]$script:recentSpins[$cleanUserKey]
                        if (($nowMs - $lastTime) -lt 400) {
                            Send-JsonResponse $response @{ status = "ok"; message = "Debounced rapid duplicate packet" }
                            continue
                        }
                    }
                    if ($cleanUserKey) { $script:recentSpins[$cleanUserKey] = $nowMs }

                    # 1. Check if gift matches a multi-spinner trigger
                    $matchedSpinner = $null

                    # Priority A: Check if a configured gift card matches this gift and has a bound spinner (e.g. Card 32 Heart Me -> spinner_1791698132034)
                    if ($config -and $config.gifts) {
                        foreach ($g in $config.gifts) {
                            if (-not $g.enabled) { continue }
                            $isCardMatch = $false
                            $gGId = if ($g.giftId) { [string]$g.giftId.Trim() } else { "" }
                            $reqGId = if ($giftId) { [string]$giftId.Trim() } else { "" }
                            $autoGId = if ($autoGift -and $autoGift.id) { [string]$autoGift.id.Trim() } else { "" }
                            if ($reqGId -and $gGId -and ($gGId -eq $reqGId -or ($autoGId -and $gGId -eq $autoGId))) {
                                $isCardMatch = $true
                            } elseif ($g.giftName -and $giftName) {
                                $cleanG = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                $cleanR = ($giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                if ($cleanG -and $cleanR -and ($cleanG -eq $cleanR -or $cleanR.Contains($cleanG) -or $cleanG.Contains($cleanR))) {
                                    $isCardMatch = $true
                                }
                            }
                            if ($isCardMatch) {
                                $bSpId = if ($g.spinnerId) { [string]$g.spinnerId } elseif ($g.command -match '^spinner_') { [string]$g.command } else { "" }
                                if ($bSpId -and $config.spinners) {
                                    $foundSp = $config.spinners | Where-Object { [string]$_.id -eq $bSpId } | Select-Object -First 1
                                    if ($foundSp) {
                                        $matchedSpinner = $foundSp
                                        break
                                    }
                                }
                            }
                        }
                    }

                    # Priority B: Match by spinner gift settings ONLY if gift is configured in active preset
                    if (-not $matchedSpinner -and $config -and $config.spinners) {
                        $isGiftInActivePreset = $false
                        if ($config.gifts) {
                            foreach ($cg in $config.gifts) {
                                if (-not $cg.enabled) { continue }
                                $cgId = if ($cg.giftId) { [string]$cg.giftId.Trim() } else { "" }
                                if ($reqGId -and $cgId -and ($cgId -eq $reqGId -or ($autoGId -and $cgId -eq $autoGId))) { $isGiftInActivePreset = $true; break }
                                if ($cg.giftName -and $giftName -and (($cg.giftName -replace '[^a-zA-Z0-9]','').ToLower() -eq ($giftName -replace '[^a-zA-Z0-9]','').ToLower())) { $isGiftInActivePreset = $true; break }
                            }
                        }
                        if ($isGiftInActivePreset) {
                            foreach ($sp in $config.spinners) {
                                if (-not $sp.enabled) { continue }
                                $spGId = if ($sp.giftId) { [string]$sp.giftId.Trim() } else { "" }
                                $reqGId = if ($giftId) { [string]$giftId.Trim() } else { "" }
                                $autoGId = if ($autoGift -and $autoGift.id) { [string]$autoGift.id.Trim() } else { "" }
                                if ($reqGId -and $spGId -and ($spGId -eq $reqGId -or ($autoGId -and $spGId -eq $autoGId))) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check clean alphanumeric ID match
                                $cleanSpGId = ($spGId -replace '[^a-zA-Z0-9]','').ToLower()
                                $cleanReqGId = ($reqGId -replace '[^a-zA-Z0-9]','').ToLower()
                                $cleanAutoGId = ($autoGId -replace '[^a-zA-Z0-9]','').ToLower()
                                if ($cleanSpGId -and (($cleanReqGId -and $cleanSpGId -eq $cleanReqGId) -or ($cleanAutoGId -and $cleanSpGId -eq $cleanAutoGId))) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check Heart Me aliases (Heart Me 7934, Heart 6247, Community Heart 17712)
                                $heartGIds = @('7934', '6247', '17712', 'heartme', 'heart', 'communityheart')
                                if (($heartGIds -contains $cleanSpGId) -and ($heartGIds -contains $cleanReqGId)) {
                                    $matchedSpinner = $sp; break
                                }
                                if ($sp.id -eq 'spinner_1791698132034' -and ($heartGIds -contains $cleanReqGId -or $cleanReqGId -match 'heart')) {
                                    $matchedSpinner = $sp; break
                                }
                                if ($sp.id -eq 'spinner_plusminus' -and ($heartGIds -contains $cleanReqGId -or $cleanReqGId -match 'heart')) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check Perfume aliases
                                if (($cleanSpGId -eq '5658' -or $cleanSpGId -eq '5585' -or $cleanSpGId -eq 'perfume') -and ($cleanReqGId -eq '5658' -or $cleanReqGId -eq '5585' -or $cleanReqGId -eq 'perfume')) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check Doughnut aliases
                                if (($cleanSpGId -eq '5879' -or $cleanSpGId -eq 'doughnut' -or $cleanSpGId -eq 'donut') -and ($cleanReqGId -eq '5879' -or $cleanReqGId -eq 'doughnut' -or $cleanReqGId -eq 'donut')) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check Rose aliases
                                if (($cleanSpGId -eq '5655' -or $cleanSpGId -eq 'rose') -and ($cleanReqGId -eq '5655' -or $cleanReqGId -eq 'rose')) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check Ice Cream Cone aliases
                                if (($cleanSpGId -eq '5827' -or $cleanSpGId -eq 'icecream' -or $cleanSpGId -eq 'icecreamcone') -and ($cleanReqGId -eq '5827' -or $cleanReqGId -eq 'icecream' -or $cleanReqGId -eq 'icecreamcone')) {
                                    $matchedSpinner = $sp; break
                                }
                                # Check giftName matching
                                if ($giftName -and $sp.giftName) {
                                    $cleanReq = ($giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    $cleanSp = ($sp.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    if ($cleanReq -and $cleanSp -and ($cleanReq -eq $cleanSp -or $cleanReq.Contains($cleanSp) -or $cleanSp.Contains($cleanReq))) {
                                        $matchedSpinner = $sp; break
                                    }
                                }
                                # Check verified catalog name
                                if ($script:verifiedGiftsCatalog -and $reqGId) {
                                    $vg = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq $reqGId } | Select-Object -First 1
                                    if ($vg -and $vg.name -and $sp.giftName) {
                                        $cleanVg = ($vg.name -replace '[^a-zA-Z0-9]','').ToLower()
                                        $cleanSp = ($sp.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                        if ($cleanVg -and $cleanSp -and ($cleanVg -eq $cleanSp -or $cleanVg.Contains($cleanSp) -or $cleanSp.Contains($cleanVg))) {
                                            $matchedSpinner = $sp; break
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if ($matchedSpinner) {
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
                                if ($g.enabled -and $g.giftId -and (($giftId -and [string]$g.giftId.Trim() -eq [string]$giftId.Trim()) -or ($autoGift -and $autoGift.id -and [string]$g.giftId.Trim() -eq [string]$autoGift.id.Trim()))) {
                                    $cardMatch = $true
                                } elseif ($g.enabled -and $g.giftName) {
                                    $cleanG = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                    $cleanR = if ($giftName) { ($giftName -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                                    $cleanA = if ($autoGift -and $autoGift.name) { ($autoGift.name -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                                    if ($cleanG -and (($cleanR -and $cleanG -eq $cleanR) -or ($cleanA -and $cleanG -eq $cleanA))) { $cardMatch = $true }
                                }

                                if ($cardMatch) {
                                    $cardIdStr = [string]$g.id
                                    if ($cardIdStr -and $counts.ContainsKey($cardIdStr)) {
                                        $counts[$cardIdStr] = [int]$counts[$cardIdStr] + $repeatCount
                                        SaveCounts
                                    }

                                    # TRIGGER IN-GAME ACTION (Plant, Zombie, Power) FOR THIS GIFT CARD!
                                    $cardGameCmds = @()
                                    if ($g.commands -and $g.commands.Count -gt 0) {
                                        foreach ($sc in $g.commands) {
                                            $scCmd = [string]$sc.command
                                            if ($scCmd -and $scCmd -ne "spin_wheel" -and -not ($scCmd -match '^spinner_') -and $sc.actionType -ne "spinner") {
                                                $cardGameCmds += $sc
                                            }
                                        }
                                    }

                                    $giftReps = if ($g.repetition) { [int]$g.repetition } else { 1 }
                                    $giftDelay = if ($g.delay) { [int]$g.delay } else { 0 }
                                    $giftInterval = if ($g.interval) { [int]$g.interval } else { 100 }
                                    $giftHide = ($g.hideInOverlay -eq $true -or $g.hideInOverlay -eq "true")

                                    if ($cardGameCmds.Count -gt 0) {
                                        foreach ($sc in $cardGameCmds) {
                                            $scAmt = if ($sc.amount) { [int]$sc.amount } else { 1 }
                                            $scRepCount = $giftReps
                                            if ($g.repetitionMultiplier -eq $true -or $g.repetitionMultiplier -eq "true") {
                                                $scRepCount = $scRepCount * $repeatCount
                                            } else {
                                                $scAmt = $scAmt * $repeatCount
                                            }
                                            $scAct = if ($sc.actionType) { $sc.actionType } else { "plant" }
                                            SendToPvZGame $scAct $sc.command $scAmt $user "" $scRepCount $giftDelay $giftInterval | Out-Null
                                            AddEventLog @{
                                                type = "gift"
                                                label = if ($sc.label) { [string]$sc.label } else { [string]$g.label }
                                                command = $sc.command
                                                actionType = $scAct
                                                amount = $scAmt
                                                username = $user
                                                icon = if ($sc.icon) { $sc.icon } elseif ($g.unitIcon) { $g.unitIcon } else { $icon }
                                                hideInOverlay = $giftHide
                                                noSpinnerTrigger = $true
                                                success = $true
                                            }
                                        }
                                    } elseif ($g.command -and $g.command -ne "spin_wheel" -and $g.actionType -ne "spinner" -and -not ($g.command -match '^spinner_')) {
                                        $totalAmt = [int]$g.amount
                                        if ($g.repetitionMultiplier -eq $true -or $g.repetitionMultiplier -eq "true") {
                                            $giftReps = $giftReps * $repeatCount
                                        } else {
                                            $totalAmt = $totalAmt * $repeatCount
                                        }
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
                            avatar = $avatar
                            giftName = if ($giftName) { $giftName } else { $matchedSpinner.giftName }
                            slice = $picked
                            spinnerId = [string]$matchedSpinner.id
                            spinnerName = $spName
                            groupId = [string]$matchedSpinner.groupId
                            mode = if ($matchedSpinner -and $matchedSpinner.mode) { $matchedSpinner.mode } else { "wheel" }
                            wheelTheme = if ($matchedSpinner -and $matchedSpinner.wheelTheme) { $matchedSpinner.wheelTheme } else { "casino_royale" }
                            centerFinial = if ($matchedSpinner -and $matchedSpinner.centerFinial) { $matchedSpinner.centerFinial } else { "turret_3d" }
                            pointerTheme = if ($matchedSpinner -and $matchedSpinner.pointerTheme) { $matchedSpinner.pointerTheme } else { "brass_chevron" }
                            wheelRarityStyle = if ($matchedSpinner -and $matchedSpinner.wheelRarityStyle) { $matchedSpinner.wheelRarityStyle } else { "rarity_enamel" }
                            reelTheme = if ($matchedSpinner -and $matchedSpinner.reelTheme) { $matchedSpinner.reelTheme } else { "casino_felt" }
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
                        # 1. Match by giftId (exact string comparison or alias)
                        $lookupIds = @()
                        if ($giftId) { $lookupIds += [string]$giftId.Trim() }
                        if ($autoGift -and $autoGift.id) { $lookupIds += [string]$autoGift.id.Trim() }

                        if ($lookupIds.Count -gt 0) {
                            foreach ($g in $config.gifts) {
                                if (-not $g.enabled) { continue }
                                $gGId = if ($g.giftId) { [string]$g.giftId.Trim() } else { "" }
                                if ($gGId -and ($lookupIds -contains $gGId)) {
                                    $matchedGift = $g; break
                                }
                                # Check clean alphanumeric
                                $cleanGGId = ($gGId -replace '[^a-zA-Z0-9]','').ToLower()
                                foreach ($curLId in $lookupIds) {
                                    $cleanReqGId = ($curLId -replace '[^a-zA-Z0-9]','').ToLower()
                                    if ($cleanGGId -and $cleanReqGId -and ($cleanGGId -eq $cleanReqGId)) {
                                        $matchedGift = $g; break
                                    }
                                    # Alias checks
                                    if (($cleanGGId -eq '5655' -or $cleanGGId -eq 'rose') -and ($cleanReqGId -eq '5655' -or $cleanReqGId -eq 'rose')) {
                                        $matchedGift = $g; break
                                    }
                                    if (($cleanGGId -eq '5827' -or $cleanGGId -eq 'icecream') -and ($cleanReqGId -eq '5827' -or $cleanReqGId -eq 'icecream')) {
                                        $matchedGift = $g; break
                                    }
                                    if (($cleanGGId -eq '7934' -or $cleanGGId -eq 'heartme') -and ($cleanReqGId -eq '7934' -or $cleanReqGId -eq 'heartme')) {
                                        $matchedGift = $g; break
                                    }
                                    if (($cleanGGId -eq '5658' -or $cleanGGId -eq '5585' -or $cleanGGId -eq 'perfume') -and ($cleanReqGId -eq '5658' -or $cleanReqGId -eq '5585' -or $cleanReqGId -eq 'perfume')) {
                                        $matchedGift = $g; break
                                    }
                                    if (($cleanGGId -eq '5879' -or $cleanGGId -eq 'doughnut' -or $cleanGGId -eq 'donut') -and ($cleanReqGId -eq '5879' -or $cleanReqGId -eq 'doughnut' -or $cleanReqGId -eq 'donut')) {
                                        $matchedGift = $g; break
                                    }
                                }
                                if ($matchedGift) { break }
                            }
                        }
                        # 2. Match by giftName
                        $checkNames = @()
                        if ($giftName -and $giftName -ne "Gift") { $checkNames += $giftName }
                        if ($autoGift -and $autoGift.name) { $checkNames += $autoGift.name }
                        if (-not $matchedGift -and $checkNames.Count -gt 0) {
                            foreach ($cn in $checkNames) {
                                $cleanReqName = ($cn -replace '[^a-zA-Z0-9]','').ToLower()
                                foreach ($g in $config.gifts) {
                                    if ($g.enabled -and $g.giftName) {
                                        $cleanCfgName = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                        if ($cleanCfgName -and ($cleanCfgName -eq $cleanReqName -or $cleanReqName.Contains($cleanCfgName) -or $cleanCfgName.Contains($cleanReqName))) {
                                            $matchedGift = $g; break
                                        }
                                    }
                                }
                                if ($matchedGift) { break }
                            }
                        }
                        # 3. Match via verified catalog name
                        if (-not $matchedGift -and $giftId -and $script:verifiedGiftsCatalog) {
                            $vg = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq [string]$giftId } | Select-Object -First 1
                            if ($vg -and $vg.name) {
                                $cleanCatName = ($vg.name -replace '[^a-zA-Z0-9]','').ToLower()
                                foreach ($g in $config.gifts) {
                                    if ($g.enabled -and $g.giftName) {
                                        $cleanCfgName = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                        if ($cleanCfgName -and ($cleanCfgName -eq $cleanCatName -or $cleanCatName.Contains($cleanCfgName) -or $cleanCfgName.Contains($cleanCatName))) {
                                            $matchedGift = $g; break
                                        }
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

                        if ($matchedGift.command -eq "spin_wheel" -or $matchedGift.actionType -eq "spinner" -or $matchedGift.command -match '^spinner_') {
                            $targetCardSp = $null
                            if ($config -and $config.spinners) {
                                if ($matchedGift.command -match '^spinner_') {
                                    $targetCardSp = $config.spinners | Where-Object { $_.id -eq $matchedGift.command } | Select-Object -First 1
                                }
                                if (-not $targetCardSp -and $matchedGift.spinnerId) {
                                    $targetCardSp = $config.spinners | Where-Object { $_.id -eq [string]$matchedGift.spinnerId } | Select-Object -First 1
                                }
                                if (-not $targetCardSp) {
                                    $targetCardSp = $config.spinners | Where-Object {
                                        ($_.giftId -and $matchedGift.giftId -and [string]$_.giftId.Trim() -eq [string]$matchedGift.giftId.Trim()) -or
                                        ($_.giftName -and $matchedGift.giftName -and ($_.giftName.Trim().ToLower() -eq $matchedGift.giftName.Trim().ToLower()))
                                    } | Select-Object -First 1
                                }
                                if (-not $targetCardSp -and $config.spinners.Count -gt 0) {
                                    $targetCardSp = $config.spinners[0]
                                }
                            }

                            $spCardSlices = if ($targetCardSp -and $targetCardSp.slices) { $targetCardSp.slices } elseif ($config.spinner -and $config.spinner.slices) { $config.spinner.slices } else { @() }
                            $picked = $null
                            if ($spCardSlices.Count -gt 0) {
                                $totalWeight = 0.0
                                foreach ($s in $spCardSlices) {
                                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                    $totalWeight += $w
                                }
                                if ($totalWeight -le 0) { $totalWeight = 100.0 }
                                $rnd = (Get-Random -Minimum 0.0 -Maximum $totalWeight)
                                $cur = 0.0
                                foreach ($s in $spCardSlices) {
                                    $w = if ($s.weight) { [double]$s.weight } elseif ($s.chance) { [double]$s.chance } else { 10.0 }
                                    $cur += $w
                                    if ($rnd -le $cur) {
                                        $picked = $s
                                        break
                                    }
                                }
                                if (-not $picked) { $picked = $spCardSlices[0] }
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

                                $cardSpName = if ($targetCardSp -and $targetCardSp.name) { $targetCardSp.name } else { "Lucky Wheel" }
                                $cardSpId = if ($targetCardSp -and $targetCardSp.id) { [string]$targetCardSp.id } else { "wheel" }
                                $cardSpDuration = if ($targetCardSp -and $targetCardSp.duration) { [int]$targetCardSp.duration } else { 2500 }
                                $cardSpTicks = if ($targetCardSp -and $targetCardSp.ticks) { [int]$targetCardSp.ticks } else { 100 }
                                $cardSpPointer = if ($targetCardSp) { $targetCardSp.pointerIcon } else { "" }
                                $cardSpGroup = if ($targetCardSp) { [string]$targetCardSp.groupId } else { "" }

                                AddEventLog @{
                                    type = "spin_result"
                                    label = "$($cardSpName): $($picked.label)"
                                    username = $user
                                    avatar = $avatar
                                    giftName = if ($giftName) { $giftName } elseif ($matchedGift.giftName) { $matchedGift.giftName } else { "Gift" }
                                    slice = $picked
                                    spinnerId = $cardSpId
                                    spinnerName = $cardSpName
                                    groupId = $cardSpGroup
                                    mode = if ($targetCardSp -and $targetCardSp.mode) { $targetCardSp.mode } else { "wheel" }
                                    wheelTheme = if ($targetCardSp -and $targetCardSp.wheelTheme) { $targetCardSp.wheelTheme } else { "casino_royale" }
                                    centerFinial = if ($targetCardSp -and $targetCardSp.centerFinial) { $targetCardSp.centerFinial } else { "turret_3d" }
                                    pointerTheme = if ($targetCardSp -and $targetCardSp.pointerTheme) { $targetCardSp.pointerTheme } else { "brass_chevron" }
                                    wheelRarityStyle = if ($targetCardSp -and $targetCardSp.wheelRarityStyle) { $targetCardSp.wheelRarityStyle } else { "rarity_enamel" }
                                    reelTheme = if ($targetCardSp -and $targetCardSp.reelTheme) { $targetCardSp.reelTheme } else { "casino_felt" }
                                    duration = $cardSpDuration
                                    ticks = $cardSpTicks
                                    pointerIcon = $cardSpPointer
                                    slices = $spCardSlices
                                    icon = if ($icon) { $icon } elseif ($matchedGift.icon) { $matchedGift.icon } else { "images/func_2.png" }
                                    hideInOverlay = $spHide
                                    success = $true
                                }
                                Add-SpinnerHistoryRecord $user $avatar $picked $cardSpName $cardSpId
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

                            $cardGameCmds = @()
                            if ($matchedGift.commands -and $matchedGift.commands.Count -gt 0) {
                                foreach ($sc in $matchedGift.commands) {
                                    if ($sc.command) { $cardGameCmds += $sc }
                                }
                            }
                            if ($cardGameCmds.Count -gt 0) {
                                foreach ($sc in $cardGameCmds) {
                                    $scAmt = if ($sc.amount) { [int]$sc.amount } else { 1 }
                                    $scAct = if ($sc.actionType) { $sc.actionType } else { $matchedGift.actionType }
                                    $scFinalAmt = $scAmt * $repeatCount
                                    SendToPvZGame $scAct $sc.command $scFinalAmt $user "" $giftReps $giftDelay $giftInterval | Out-Null
                                }
                                # Log EXACTLY 1 overlay gift event per gift send (no duplicate spins)
                                AddEventLog @{ type = "gift"; label = $matchedGift.label; giftName = $giftName; repeatCount = $repeatCount; command = $matchedGift.command; amount = $totalAmt; username = $user; icon = $icon; hideInOverlay = $giftHide; noSpinnerTrigger = $true }
                            } else {
                                SendToPvZGame $matchedGift.actionType $matchedGift.command $totalAmt $user "" $giftReps $giftDelay $giftInterval | Out-Null
                                AddEventLog @{ type = "gift"; label = $matchedGift.label; giftName = $giftName; repeatCount = $repeatCount; command = $matchedGift.command; amount = $totalAmt; username = $user; icon = $icon; hideInOverlay = $giftHide; noSpinnerTrigger = $true }
                            }

                            # ROUTE TRIGGER EVENT TO DEDICATED ON-SCREEN COUNTER!
                            $triggerLbl = if ($matchedGift.label) { [string]$matchedGift.label } elseif ($giftName) { [string]$giftName } else { "In-game Event" }
                            $triggerIcon = if ($matchedGift.unitIcon) { [string]$matchedGift.unitIcon } elseif ($icon) { [string]$icon } else { "images/trig_7.svg" }
                            Record-TriggerEvent $giftName $giftId $repeatCount $user $avatar $triggerIcon $triggerLbl
                        }
                    } else {
                        # Gift is not present in the active preset.
                        # Do NOT trigger unconfigured game commands (ensure ONLY the active preset's commands execute).
                        AddEventLog @{ type = "unconfigured_gift"; label = if ($giftName -and $giftName -ne "Gift") { "$giftName (Ignored - not in active preset)" } else { "Gift (Ignored)" }; giftName = $giftName; giftId = $giftId; username = $user; coins = $giftCoinValue; icon = $icon; success = $false; noSpinnerTrigger = $true }
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

                    # Likes handling for active preset
                    $likeCards = @()
                    if ($config -and $config.gifts) {
                        $likeCards = @($config.gifts | Where-Object { 
                            $_.enabled -ne $false -and (
                                $_.triggerType -eq "likes_person" -or 
                                $_.eventType -eq "team_plants_likes" -or 
                                $_.eventType -eq "team_zombies_likes" -or 
                                [string]$_.id -in @("1", "2")
                            )
                        })
                    }

                    $card1 = $likeCards | Where-Object { [string]$_.id -eq "1" -or $_.eventType -eq "team_plants_likes" -or ($_.giftName -match "team\s*plants") } | Select-Object -First 1
                    $card2 = $likeCards | Where-Object { [string]$_.id -eq "2" -or $_.eventType -eq "team_zombies_likes" -or ($_.giftName -match "team\s*zombies") } | Select-Object -First 1

                    $thresh1 = if ($card1 -and $card1.likeThreshold) { [int]$card1.likeThreshold } else { 50 }
                    $thresh2 = if ($card2 -and $card2.likeThreshold) { [int]$card2.likeThreshold } else { 50 }

                    if ($likeCards.Count -eq 1) {
                        # Single like card in active preset (e.g. Spawn Trident Jugger-nut Gargantuar 50 Likes)
                        # All incoming stream likes count towards this active card!
                        $singleCard = $likeCards[0]
                        $thresh = if ($singleCard.likeThreshold -and [int]$singleCard.likeThreshold -gt 0) { [int]$singleCard.likeThreshold } else { 50 }
                        $teamPlantsLikes += $likes
                        while ($teamPlantsLikes -ge $thresh) {
                            $teamPlantsLikes -= $thresh
                            if ($singleCard.enabled -ne $false) {
                                $cReps = if ($singleCard.repetition -and [int]$singleCard.repetition -gt 0) { [int]$singleCard.repetition } else { 1 }
                                $cAmt = if ($singleCard.amount -and [int]$singleCard.amount -gt 0) { [int]$singleCard.amount } else { 1 }
                                $cDelay = if ($singleCard.delay) { [int]$singleCard.delay } else { 0 }
                                $cInt = if ($singleCard.interval) { [int]$singleCard.interval } else { 100 }
                                SendToPvZGame $singleCard.actionType $singleCard.command $cAmt $user "" $cReps $cDelay $cInt | Out-Null
                                $sId = [string]$singleCard.id
                                if ($sId -and $counts.Contains($sId)) { $counts[$sId] = [int]$counts[$sId] + 1; SaveCounts }
                                AddEventLog @{
                                    type = "likes_spawn"
                                    label = "$($singleCard.label) ($thresh Likes)"
                                    command = $singleCard.command
                                    amount = $cAmt
                                    username = $user
                                    icon = $singleCard.unitIcon
                                    success = $true
                                }
                            }
                        }
                    } elseif ($likeCards.Count -gt 1) {
                        # Multi-team battle (Team Plants vs Team Zombies)
                        if (-not $userTeams.ContainsKey($user) -or [string]::IsNullOrWhiteSpace($userTeams[$user])) {
                            $userTeams[$user] = "plants"
                        }
                        $team = $userTeams[$user]

                        if ($team -eq "plants" -and $card1) {
                            $teamPlantsLikes += $likes
                            while ($teamPlantsLikes -ge $thresh1) {
                                $teamPlantsLikes -= $thresh1
                                if ($card1.enabled -ne $false) {
                                    $cReps = if ($card1.repetition -and [int]$card1.repetition -gt 0) { [int]$card1.repetition } else { 1 }
                                    $cAmt = if ($card1.amount -and [int]$card1.amount -gt 0) { [int]$card1.amount } else { 1 }
                                    $cDelay = if ($card1.delay) { [int]$card1.delay } else { 0 }
                                    $cInt = if ($card1.interval) { [int]$card1.interval } else { 100 }
                                    SendToPvZGame $card1.actionType $card1.command $cAmt $user "" $cReps $cDelay $cInt | Out-Null
                                    if ($counts.Contains("1")) { $counts["1"] = [int]$counts["1"] + 1; SaveCounts }
                                    AddEventLog @{
                                        type = "team_battle_spawn"
                                        label = "Team Plants ($thresh1 Likes) -> $($card1.label)"
                                        team = "plants"
                                        command = $card1.command
                                        amount = $cAmt
                                        username = $user
                                        icon = $card1.unitIcon
                                        success = $true
                                    }
                                }
                            }
                        } elseif ($team -eq "zombies" -and $card2) {
                            $teamZombiesLikes += $likes
                            while ($teamZombiesLikes -ge $thresh2) {
                                $teamZombiesLikes -= $thresh2
                                if ($card2.enabled -ne $false) {
                                    $cReps = if ($card2.repetition -and [int]$card2.repetition -gt 0) { [int]$card2.repetition } else { 1 }
                                    $cAmt = if ($card2.amount -and [int]$card2.amount -gt 0) { [int]$card2.amount } else { 1 }
                                    $cDelay = if ($card2.delay) { [int]$card2.delay } else { 0 }
                                    $cInt = if ($card2.interval) { [int]$card2.interval } else { 100 }
                                    SendToPvZGame $card2.actionType $card2.command $cAmt $user "" $cReps $cDelay $cInt | Out-Null
                                    if ($counts.Contains("2")) { $counts["2"] = [int]$counts["2"] + 1; SaveCounts }
                                    AddEventLog @{
                                        type = "team_battle_spawn"
                                        label = "Team Zombies ($thresh2 Likes) -> $($card2.label)"
                                        team = "zombies"
                                        command = $card2.command
                                        amount = $cAmt
                                        username = $user
                                        icon = $card2.unitIcon
                                        success = $true
                                    }
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

                $exec = SendToPvZGame $actType $cCmd $totalSpawns "RENEarn"

                AddEventLog @{
                    type = "card_donation"
                    cardId = $id
                    label = "$gLabel ($($targetCard.funcName))"
                    command = $cCmd
                    amount = $totalSpawns
                    username = "RENEarn"
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

        # 11. Reset API (All counts or single command count)
        if ($reqPath -eq '/api/reset' -or $reqPath -eq '/api/counts/reset') {
            $singleId = $request.QueryString['id']
            if (-not $singleId -and $request.HttpMethod -eq 'POST') {
                try {
                    $resetBody = Get-RequestBody $request
                    if ($resetBody -and $resetBody.id) { $singleId = [string]$resetBody.id }
                } catch {}
            }

            if ($singleId) {
                $sIdStr = [string]$singleId
                if ($counts.ContainsKey($sIdStr)) {
                    $counts[$sIdStr] = 0
                }
                SaveCounts
                AddEventLog @{ type = "counts_reset"; cardId = $sIdStr; message = "Command $sIdStr count reset to 0" }
                Send-JsonResponse $response @{ status = "ok"; cardId = $sIdStr; count = 0 }
            } else {
                foreach ($k in @($counts.Keys)) {
                    $counts[$k] = 0
                }
                SaveCounts
                if ($script:triggerCounterState) {
                    $script:triggerCounterState.totalTriggers = 0
                    $script:triggerCounterState.streak = 0
                    $script:triggerCounterState.gifts = [PSCustomObject]@{}
                    $script:triggerCounterState.recentTriggers = @()
                    Save-TriggerCounterState
                }
                AddEventLog @{ type = "counts_reset"; cardId = "all"; message = "All command counts reset to 0" }
                Send-JsonResponse $response @{ status = "ok"; message = "All counts reset to 0" }
            }
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
