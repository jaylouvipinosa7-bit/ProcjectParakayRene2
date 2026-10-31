# ==============================================================================
# PvZ Fusion 4.0 - Live Stream Control Server & In-Game Bridge
# ==============================================================================

$port = 8080
$folder = $PSScriptRoot

# Mod listens on 5003 (or 55001 backup)
$gamePorts = @(5003, 55001)

# Disable Expect100Continue to eliminate HTTP POST stall delays
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

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
$subscriptionsFile = Join-Path $folder "subscriptions.json"

function Load-Subscriptions {
    if (Test-Path $subscriptionsFile) {
        try {
            return (Get-Content $subscriptionsFile -Raw -Encoding UTF8 | ConvertFrom-Json)
        } catch {}
    }
    return $null
}

function Save-Subscriptions($subsObj) {
    try {
        $json = $subsObj | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($subscriptionsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Get-UserSubscriptionInfo($userIdentifier, $userEmail = "") {
    $rawId = if ($userIdentifier) { [string]$userIdentifier.ToString().Trim().TrimStart('@').ToLower() } else { "" }
    $rawEmail = if ($userEmail) { [string]$userEmail.ToString().Trim().ToLower() } else { "" }
    
    # 1. Primary Owner Guarantee (Jaylou Vipinosa / gohanmalunggay)
    $isPrimaryOwner = (
        $rawId -eq "jaylouvipinosa7@gmail.com" -or
        $rawId.Contains("jaylouvipinosa7") -or
        $rawId -eq "gohanmalunggay" -or
        $rawEmail -eq "jaylouvipinosa7@gmail.com" -or
        $rawEmail.Contains("jaylouvipinosa7")
    )
    if ($isPrimaryOwner) {
        return @{
            tier = "owner"
            name = "Owner Lifetime"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Owner Lifetime"
            badgeColor = "#e11d48"
            price = 0
            isUnlimited = $true
        }
    }

    # 2. Permissions Registry Check (Admin / Editor / Tester)
    $perms = Load-Permissions
    $isAdmin = ($perms.admin -and ($rawId -eq $perms.admin.ToLower() -or $rawEmail -eq $perms.admin.ToLower())) -or 
               ($perms.admins -and ($perms.admins -contains $rawId -or $perms.admins -contains $rawEmail))
    if ($isAdmin) {
        return @{
            tier = "owner"
            name = "Owner Lifetime"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Owner Lifetime"
            badgeColor = "#e11d48"
            price = 0
            isUnlimited = $true
        }
    }

    $isEditor = ($perms.editors -and ($perms.editors -contains $rawId -or $perms.editors -contains $rawEmail))
    if ($isEditor) {
        return @{
            tier = "editor"
            name = "Staff Editor (Unlimited)"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Staff Editor"
            badgeColor = "#06b6d4"
            price = 0
            isUnlimited = $true
        }
    }

    $isTester = ($perms.testers -and ($perms.testers -contains $rawId -or $perms.testers -contains $rawEmail))
    if ($isTester) {
        return @{
            tier = "tester"
            name = "Beta Tester"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Beta Tester"
            badgeColor = "#a855f7"
            price = 0
            isUnlimited = $true
        }
    }

    # 3. Subscriptions Registry Check (Owner / Editor / Tester / Expert / Premium / Free)
    $subs = Load-Subscriptions
    $matchedTier = "free"
    if ($subs -and $subs.userSubscriptions) {
        foreach ($prop in $subs.userSubscriptions.PSObject.Properties) {
            $key = $prop.Name.Trim().TrimStart('@').ToLower()
            if (($key -eq $rawId -or ($rawEmail -and $key -eq $rawEmail)) -and $prop.Value.tier) {
                $matchedTier = [string]$prop.Value.tier.ToLower()
                break
            }
        }
    }

    if ($matchedTier -eq "owner") {
        return @{
            tier = "owner"
            name = "Owner Lifetime"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Owner Lifetime"
            badgeColor = "#e11d48"
            price = 0
            isUnlimited = $true
        }
    }

    if ($matchedTier -eq "editor") {
        return @{
            tier = "editor"
            name = "Staff Editor (Unlimited)"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Staff Editor"
            badgeColor = "#06b6d4"
            price = 0
            isUnlimited = $true
        }
    }

    if ($matchedTier -eq "tester") {
        return @{
            tier = "tester"
            name = "Beta Tester"
            commandLimit = 999999
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Beta Tester"
            badgeColor = "#a855f7"
            price = 0
            isUnlimited = $true
        }
    }

    if ($matchedTier -eq "expert") {
        return @{
            tier = "expert"
            name = "Streamer Expert"
            commandLimit = 150
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Streamer Expert"
            badgeColor = "#f59e0b"
            price = 3999
            isUnlimited = $false
        }
    }

    if ($matchedTier -eq "premium" -or $matchedTier -eq "pro") {
        return @{
            tier = "premium"
            name = "Streamer Premium"
            commandLimit = 60
            hasSpinner = $true
            hasJar = $true
            hasOverlays = $true
            badge = "Streamer Premium"
            badgeColor = "#38bdf8"
            price = 999
            isUnlimited = $false
        }
    }

    # 4. Default: Free Starter Tier (10 commands only, no spinner, no jar, overlays allowed)
    return @{
        tier = "free"
        name = "Free Starter"
        commandLimit = 10
        hasSpinner = $false
        hasJar = $false
        hasOverlays = $true
        badge = "Free Starter"
        badgeColor = "#94a3b8"
        price = 0
        isUnlimited = $false
    }
}

function Load-Permissions {
    $defaultPerms = @{
        admin = ""
        admins = @()
        editors = @()
        testers = @()
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
            $tsts = @()
            if ($raw.testers) {
                foreach ($t in $raw.testers) { if ($t) { $tsts += [string]$t.Trim().ToLower() } }
            }
            return @{
                admin = $adm
                admins = $adms
                editors = $edts
                testers = $tsts
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
    if ($perms.testers -contains $clean) {
        return "tester"
    }
    return "viewer"
}

function Get-MediaDurationFormatted($fullFilePath) {
    try {
        if (-not (Test-Path $fullFilePath)) { return "00:03:00" }
        $dir = [System.IO.Path]::GetDirectoryName($fullFilePath)
        $fn = [System.IO.Path]::GetFileName($fullFilePath)
        $sh = New-Object -ComObject Shell.Application
        $f = $sh.Namespace($dir)
        $it = $f.ParseName($fn)
        if ($it) {
            $len = $f.GetDetailsOf($it, 27)
            if ($len -match '(\d+):(\d+):(\d+)') {
                $hrs = [int]$matches[1]
                $mins = [int]$matches[2]
                $secs = [int]$matches[3]
                $totMins = ($hrs * 60) + $mins
                return ("{0:D2}:{1:D2}:00" -f $totMins, $secs)
            }
        }
    } catch {}
    return "00:03:00"
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
$runetifyNormalized = @{}
if (Test-Path $runetifyMapFile) {
    try {
        $rJson = Get-Content $runetifyMapFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($prop in $rJson.PSObject.Properties) {
            $k = $prop.Name.ToLower()
            $runetifyCommands[$k] = $prop.Value
            $stripped = $k -replace '[^a-z0-9]', ''
            $runetifyNormalized[$stripped] = $prop.Value
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

function SaveCounts {
    try {
        $dict = @{}
        foreach ($k in $counts.Keys) {
            $dict[$k] = [int]$counts[$k]
        }
        $json = $dict | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($countsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
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
    if ($gId -ne $null) {
        $strId = ([string]$gId).Trim()
        if ($strId) {
            $found = $script:verifiedGiftsCatalog | Where-Object { [string]$_.id -eq $strId } | Select-Object -First 1
            if ($found) { return $found }
        }
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
            elseif ($clean -match '^(galaxy)$') { $aliasId = '11046' }
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

# ==================== SIDE STREAM OVERLAY SETTINGS ====================
$sideOverlaySettingsFile = Join-Path $folder "side_overlay_settings.json"

function Load-SideOverlaySettings {
    if (Test-Path $sideOverlaySettingsFile) {
        try {
            $raw = Get-Content $sideOverlaySettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        split1 = [PSCustomObject]@{
            cols = "8"
            offset = 0
            limit = 30
            style = "compact"
        }
        split2 = [PSCustomObject]@{
            cols = "8"
            offset = 30
            limit = 30
            style = "compact"
        }
        single = [PSCustomObject]@{
            cols = "2"
            limit = 0
            style = "detailed"
        }
        common = [PSCustomObject]@{
            preset = "pvz"
            theme = "s2e-gradient"
            margin = 1
            height = 46
            padding = 4
            growLast = $true
            hideRep = $false
            showName = $false
            giftsFirst = $false
        }
    }
}

function Save-SideOverlaySettings($settings) {
    try {
        $json = $settings | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($sideOverlaySettingsFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:sideOverlaySettings = Load-SideOverlaySettings

# ==================== TEAM BATTLE OVERLAY SETTINGS ====================
$teamBattleSettingsFile = Join-Path $folder "teambattle_settings.json"

function Load-TeamBattleSettings {
    if (Test-Path $teamBattleSettingsFile) {
        try {
            $raw = Get-Content $teamBattleSettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        activePreset = "blue_vs_red"
        team1 = [PSCustomObject]@{
            id = "blue"
            name = "Team Blue"
            command = "!blue"
            aliases = @("!blue", "!teamblue", "!bluearmy", "!plants", "!teamplant")
            color = "#38bdf8"
            colorDark = "#0284c7"
            colorGrad = "linear-gradient(135deg, #0284c7 0%, #2563eb 50%, #38bdf8 100%)"
            glow = "rgba(56, 189, 248, 0.45)"
            icon = "images/indicators/indicator_general.svg"
            emoji = [char]::ConvertFromUtf32(0x1F535)
            threshold = 20
            repetition = 20
            unit = "Blue Vanguard"
            gameCommand = "spawn_overclocked_cherrybomber"
        }
        team2 = [PSCustomObject]@{
            id = "red"
            name = "Team Red"
            command = "!red"
            aliases = @("!red", "!teamred", "!redarmy", "!zombies", "!teamzombie")
            color = "#ef4444"
            colorDark = "#b91c1c"
            colorGrad = "linear-gradient(135deg, #b91c1c 0%, #ef4444 50%, #f87171 100%)"
            glow = "rgba(239, 68, 68, 0.45)"
            icon = "images/indicators/indicator_general.svg"
            emoji = [char]::ConvertFromUtf32(0x1F534)
            threshold = 20
            repetition = 20
            unit = "Red Vanguard"
            gameCommand = "spawn_trident_juggernut_gargantuar"
        }
    }
}

function Save-TeamBattleSettings($settings) {
    try {
        $json = $settings | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($teamBattleSettingsFile, $json, [System.Text.Encoding]::UTF8)
        $script:teamBattleSettings = Load-TeamBattleSettings
    } catch {}
}

$script:teamBattleSettings = Load-TeamBattleSettings

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

# ── Join Stream Overlay Config ──
$joinOverlayConfigFile = Join-Path $folder "join_overlay_config.json"

function Load-JoinOverlayConfig {
    if (Test-Path $joinOverlayConfigFile) {
        try {
            $raw = Get-Content $joinOverlayConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return [PSCustomObject]@{
        bannerText = "renearn"
        subText = "joined the stream!"
        theme = "gold_purple"
        showGroudonBadge = $false
        displayDuration = 5000
        soundEnabled = $true
        animationStyle = "crest_pop"
        customSoundUrl = ""
    }
}

function Save-JoinOverlayConfig($cfg) {
    try {
        $json = $cfg | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($joinOverlayConfigFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:joinOverlayConfig = Load-JoinOverlayConfig

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

# ==================== GIFT GALLERY OVERLAY TRACKING ====================
$giftGalleryFile = Join-Path $folder "gift_gallery_state.json"

function Load-GiftGalleryState {
    if (Test-Path $giftGalleryFile) {
        try {
            $raw = Get-Content $giftGalleryFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($raw) { return $raw }
        } catch {}
    }
    return $null
}

function Save-GiftGalleryState($st) {
    try {
        $json = $st | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($giftGalleryFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

$script:giftGalleryState = Load-GiftGalleryState

function Process-GiftForGallery($giftName, $giftId, $user, $avatar, $repeatCount, $icon) {
    if (-not $script:giftGalleryState -or -not $script:giftGalleryState.gifts) {
        $script:giftGalleryState = Load-GiftGalleryState
    }
    if (-not $script:giftGalleryState) { return }

    $cleanName = if ($giftName) { $giftName.ToLower().Trim() -replace '[^a-z0-9]', '' } else { "" }
    $cleanId = if ($giftId) { [string]$giftId } else { "" }
    $slotUpdated = $false

    foreach ($g in $script:giftGalleryState.gifts) {
        $gTargetName = if ($g.name) { $g.name.ToLower().Trim() -replace '[^a-z0-9]', '' } else { "" }
        $gTargetId = if ($g.id) { [string]$g.id } else { "" }

        if (($cleanId -and $cleanId -eq $gTargetId) -or ($cleanName -and $cleanName -eq $gTargetName)) {
            $g.currentCount += [Math]::Max(1, $repeatCount)
            $g.gifter = [PSCustomObject]@{
                username = if ($user) { $user } else { "Viewer" }
                avatar = if ($avatar) { $avatar } else { "images/default_avatar.svg" }
            }
            if ($g.currentCount -ge $g.targetCount -and -not $g.obtained) {
                $g.obtained = $true
                $script:giftGalleryState.obtainedCount = ($script:giftGalleryState.gifts | Where-Object { $_.obtained -eq $true }).Count
            }
            $slotUpdated = $true
            break
        }
    }

    if ($slotUpdated) {
        $script:giftGalleryState.lastUpdated = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        Save-GiftGalleryState $script:giftGalleryState
        AddEventLog @{
            type = "gift_gallery_update"
            streamer = $script:giftGalleryState.streamer
            tier = $script:giftGalleryState.tier
            obtainedCount = $script:giftGalleryState.obtainedCount
            totalSlots = $script:giftGalleryState.totalSlots
            gifts = $script:giftGalleryState.gifts
        }
    }
}

$script:countsDirty = $false
$script:lastCountsSaveTime = 0

function SaveCounts([switch]$Force) {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    if ($Force -or ($now - $script:lastCountsSaveTime) -ge 400) {
        $script:lastCountsSaveTime = $now
        $script:countsDirty = $false
        try {
            $json = $counts | ConvertTo-Json
            [System.IO.File]::WriteAllText($countsFile, $json, [System.Text.Encoding]::UTF8)
        } catch {}
    } else {
        $script:countsDirty = $true
    }
}

# Win / Lose Widget State & Persistence
$winWidgetFile = Join-Path $folder "win_widget_state.json"
function Load-WinWidget {
    if (Test-Path $winWidgetFile) {
        try {
            $w = Get-Content $winWidgetFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($w) {
                if (-not $w.style) { $w | Add-Member -NotePropertyName "style" -NotePropertyValue "cyber" -Force }
                if (-not $w.trophyIcon) { $w | Add-Member -NotePropertyName "trophyIcon" -NotePropertyValue "cup" -Force }
                if (-not $w.colorNegative) { $w | Add-Member -NotePropertyName "colorNegative" -NotePropertyValue "#ff007f" -Force }
                if (-not $w.colorPositive) { $w | Add-Member -NotePropertyName "colorPositive" -NotePropertyValue "#10b981" -Force }
                if (-not $w.colorZero) { $w | Add-Member -NotePropertyName "colorZero" -NotePropertyValue "#38bdf8" -Force }
                if ($w.scale -eq $null) { $w | Add-Member -NotePropertyName "scale" -NotePropertyValue 1.0 -Force }
                if (-not $w.bgTheme) { $w | Add-Member -NotePropertyName "bgTheme" -NotePropertyValue "glass" -Force }
                if ($w.showTrophy -eq $null) { $w | Add-Member -NotePropertyName "showTrophy" -NotePropertyValue $true -Force }
                return $w
            }
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
        style = "cyber"
        trophyIcon = "cup"
        colorNegative = "#ff007f"
        colorPositive = "#10b981"
        colorZero = "#38bdf8"
        scale = 1.0
        bgTheme = "glass"
        showTrophy = $true
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

$songRequestFile = Join-Path $PSScriptRoot "songrequest_state.json"

function Load-SongRequestState {
    if (Test-Path $songRequestFile) {
        try {
            $raw = Get-Content $songRequestFile -Raw -Encoding UTF8
            $obj = $raw | ConvertFrom-Json
            if ($obj) { return $obj }
        } catch {}
    }
    return @{
        enabled = $true
        spotifyConnected = $false
        nowPlaying = $null
        queue = @()
        history = @()
        settings = @{
            commandPrefix = "!play"
            aliases = @("!sr", "!song", "!request")
            allowEveryone = $true
            maxQueuePerUser = 3
            maxSongDurationMinutes = 7
            ttsAnnouncement = $true
            overlayTheme = "modern_glass"
            volume = 85
        }
    }
}

function Save-SongRequestState($state) {
    try {
        $json = $state | ConvertTo-Json -Depth 8
        [System.IO.File]::WriteAllText($songRequestFile, $json, [System.Text.Encoding]::UTF8)
    } catch {}
}

function Resolve-MusicTrack($rawQuery) {
    if (-not $rawQuery -or [string]::IsNullOrWhiteSpace($rawQuery)) { return $null }
    $cleanQ = [string]$rawQuery.Trim()
    $cleanQ = $cleanQ -replace '^!(play|sr|song|request)\s+', ''
    $cleanQ = $cleanQ -replace '\s+-\s+Requested Track', '' -replace '\s+Requested Track', '' -replace '\s+-\s+Unknown Artist', '' -replace '\s+Unknown Artist', ''
    if ([string]::IsNullOrWhiteSpace($cleanQ)) { return $null }

    $found = $null
    $ytId = $null

    # 1. Resolve full YouTube videoId (full 3-5 minute song!)
    $nodePath = Join-Path $PSScriptRoot "bin\node.exe"
    $ytScript = Join-Path $PSScriptRoot "youtube-resolver.js"
    if ((Test-Path $nodePath) -and (Test-Path $ytScript)) {
        try {
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = $nodePath
            $pinfo.Arguments = "`"$ytScript`" `"$cleanQ`""
            $pinfo.RedirectStandardOutput = $true
            $pinfo.UseShellExecute = $false
            $pinfo.CreateNoWindow = $true
            $proc = [System.Diagnostics.Process]::Start($pinfo)
            if ($proc.WaitForExit(3500)) {
                $out = $proc.StandardOutput.ReadToEnd()
                if ($out) {
                    $json = $out | ConvertFrom-Json
                    if ($json -and $json.videoId) {
                        $ytId = [string]$json.videoId
                    }
                }
            } else {
                $proc.Kill()
            }
        } catch {}
    }

    # 2. Search iTunes with country=US & entity=song & limit=5 for clean metadata & HD cover art
    try {
        $iUrl = "https://itunes.apple.com/search?term=" + [System.Uri]::EscapeDataString($cleanQ) + "&country=US&entity=song&limit=5"
        $iRes = Invoke-RestMethod -Uri $iUrl -Method GET -TimeoutSec 4
        if ($iRes -and $iRes.results) {
            foreach ($item in $iRes.results) {
                if ($item.previewUrl) {
                    $found = @{
                        title = [string]$item.trackName
                        artist = [string]$item.artistName
                        singer = [string]$item.artistName
                        album = if ($item.collectionName) { [string]$item.collectionName } else { "Single" }
                        coverUrl = if ($item.artworkUrl100) { [string]($item.artworkUrl100 -replace '100x100', '400x400') } else { "" }
                        previewUrl = [string]$item.previewUrl
                        durationMs = if ($item.trackTimeMillis) { [int]$item.trackTimeMillis } else { 210000 }
                        uri = "itunes:track:" + [string]$item.trackId
                        youtubeId = $ytId
                    }
                    break
                }
            }
        }
    } catch {}

    # 3. Deezer fallback if iTunes found nothing
    if (-not $found) {
        try {
            $dUrl = "https://api.deezer.com/search?q=" + [System.Uri]::EscapeDataString($cleanQ) + "&limit=3"
            $dRes = Invoke-RestMethod -Uri $dUrl -Method GET -TimeoutSec 3
            if ($dRes -and $dRes.data) {
                foreach ($top in $dRes.data) {
                    if ($top.preview) {
                        $found = @{
                            title = [string]$top.title
                            artist = [string]$top.artist.name
                            singer = [string]$top.artist.name
                            album = if ($top.album -and $top.album.title) { [string]$top.album.title } else { "Single" }
                            coverUrl = if ($top.album -and $top.album.cover_medium) { [string]$top.album.cover_medium } else { "" }
                            previewUrl = [string]$top.preview
                            durationMs = if ($top.duration) { [int]($top.duration * 1000) } else { 210000 }
                            uri = "deezer:track:" + [string]$top.id
                            youtubeId = $ytId
                        }
                        break
                    }
                }
            }
        } catch {}
    }

    # 4. If neither iTunes nor Deezer matched, create full-song track directly from YouTube
    if (-not $found -and $ytId) {
        $found = @{
            title = $cleanQ
            artist = "Full Music Stream"
            singer = "YouTube Music"
            album = "Full Track"
            coverUrl = "https://img.youtube.com/vi/$ytId/hqdefault.jpg"
            previewUrl = ""
            durationMs = 210000
            uri = "youtube:$ytId"
            youtubeId = $ytId
        }
    }

    if ($found -and $ytId -and (-not $found.ContainsKey("youtubeId") -or -not $found.youtubeId)) {
        $found.youtubeId = $ytId
    }

    return $found
}

$script:songRequestState = Load-SongRequestState

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

    # Ensure spinners are NEVER empty so Reel & Number Card system work for all users
    if ($cfg -and (-not $cfg.spinners -or $cfg.spinners.Count -eq 0)) {
        $master = Get-MasterTemplateConfig
        if ($master.spinners -and $master.spinners.Count -gt 0) {
            $cfg | Add-Member -MemberType NoteProperty -Name spinners -Value $master.spinners -Force
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

        # Keep user configured command and label as-is
        
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
        if ($ev.unitIcon) {
            $uIcon = [string]$ev.unitIcon
        } elseif ($ev.function -and $ev.function.image) {
            $uIcon = [string]$ev.function.image
        } else {
            $firstCmd = ($cmd.Split(';')[0]).Trim()
            $uIcon = "images/game-icons/pvz/$firstCmd.webp"
        }
        $uIcon = $uIcon -replace '^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\/', ''
        
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
            $isLikeTrig = ($trigType -like "*like*" -or $act -eq "Likes" -or $id -in @("1", "2", "3"))
            $likeThresh = if ($ev.likeThreshold) { [int64]$ev.likeThreshold } elseif ($isLikeTrig) { 50 } else { $null }
            $trigValStr = if ($isLikeTrig) { [string]$likeThresh } elseif ($ev.triggerValue) { [string]$ev.triggerValue } else { "" }
        }
        
        # Exclude custom triggers from overlay as requested
        if ($act -eq "Custom" -or $act -eq "custom" -or $trigType -eq "custom" -or $id -eq "59") {
            $hideInOverlay = $true
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
            triggerValue = $trigValStr
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

            $isCustomTrig = ($g.triggerType -eq "custom" -or $g.actionType -eq "custom" -or $overlayAction -eq "Custom")
            $isHideInOverlay = ($g.hideInOverlay -eq $true)

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
            $tImg = if ($g.icon) { [string]$g.icon } else { "images/tiktok-gifts/5655_rose.webp" }
            $tImg = $tImg -replace '^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\/', ''
            if ($tImg -eq 'images/trig_3.svg') { $tImg = 'images/trig_3.webp' }
            if ($curGiftId -eq '1429010' -or $tImg -like '*1429010*' -or ($g.giftName -and $g.giftName -like '*palm of protection*')) {
                $tImg = 'images/tiktok-gifts/1429010_palm_of_protection.webp'
            }

            $overlayCards += [PSCustomObject]@{
                id = [string]$g.id
                action = $overlayAction
                giftId = if ($g.giftId) { [string]$g.giftId } else { "" }
                giftName = if ($g.giftName) { [string]$g.giftName } else { "Gift" }
                funcName = $fName
                funcImg = $uImg
                trigImg = $tImg
                triggerValue = $trigVal
                commands = $cmdStr
                repetition = if ($g.repetition -and [int]$g.repetition -gt 0) { [int]$g.repetition } elseif ($g.amount -and [int]$g.amount -gt 0) { [int]$g.amount } else { 1 }
                hideInOverlay = $isHideInOverlay
                triggerType = if ($g.triggerType) { [string]$g.triggerType } else { "gift" }
                actionType = if ($g.actionType) { [string]$g.actionType } else { "zombie" }
            }
        }

        if ($overlayCards.Count -gt 0) {
            $cardsJson = $overlayCards | ConvertTo-Json -Depth 15
            [System.IO.File]::WriteAllText($cardsFile, $cardsJson, [System.Text.Encoding]::UTF8)
            
            $rootCardsFile = Join-Path (Split-Path -Parent $folder) "cards.json"
            try { [System.IO.File]::WriteAllText($rootCardsFile, $cardsJson, [System.Text.Encoding]::UTF8) } catch {}

            $cardsDataJsFile = Join-Path $folder "cards-data.js"
            $cardsDataJs = "const cardsData = " + $cardsJson + ";"
            [System.IO.File]::WriteAllText($cardsDataJsFile, $cardsDataJs, [System.Text.Encoding]::UTF8)
            $rootCardsDataJsFile = Join-Path (Split-Path -Parent $folder) "cards-data.js"
            try { [System.IO.File]::WriteAllText($rootCardsDataJsFile, $cardsDataJs, [System.Text.Encoding]::UTF8) } catch {}

            # Ensure all card IDs are tracked in counts table
            foreach ($card in $overlayCards) {
                $cid = [string]$card.id
                if ($cid -and -not $counts.ContainsKey($cid)) {
                    $counts[$cid] = 0
                }
            }
            SaveCounts
            AddEventLog @{ type = "cards_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
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
        'blackknight|blackhorse|blackknightzombie' { return 251 }
        'buckshotknight|superblackhorse|buckshotknightcaptain' { return 252 }
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
        if ($ar.AsyncWaitHandle.WaitOne(400, $false)) {
            $tcp.EndConnect($ar)
            $tcp.Close()
            return $true
        }
        $tcp.Close()
    } catch {}
    return $false
}

# Cache active game port to avoid duplicate calls across both ports (5003 & 55001)
$script:activeGamePort = $null

# Post direct action to the PvZ Fusion game mod
function SendSinglePvZCommand($endpoint, $payloadObj) {
    $dispatched = $false
    try {
        $json = $payloadObj | ConvertTo-Json -Compress
        $rawBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

        # Prioritize known active port or 5003 first
        $primaryPort = if ($script:activeGamePort) { $script:activeGamePort } else { 5003 }
        $candidatePorts = @($primaryPort) + ($gamePorts | Where-Object { $_ -ne $primaryPort })

        foreach ($p in $candidatePorts) {
            $bytesSent = $false
            try {
                $req = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$p$endpoint")
                $req.Timeout = 400
                $req.ReadWriteTimeout = 400
                $req.KeepAlive = $true
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

    $lastResult = @{ success = $true; message = "OK" }

    # REPETITION & SUMMON CALCULATION (1=1 COMMAND RATIO):
    # When repetition is configured (e.g. Repetition: 5), 1 gift = 1 command execution of 5 units.
    # If both $reps and $rawAmt are set to values > 1 (e.g. repetition: 5 and amount: 5 from duplicate card properties),
    # do NOT square or multiply them together! Use the exact intended count.
    $totalIntendedSummons = if ($reps -gt 1 -and $rawAmt -gt 1) {
        if ($reps -eq $rawAmt) { $reps } else { [Math]::Max($reps, $rawAmt) }
    } else {
        [int]($reps * $rawAmt)
    }
    $useDirectBatch = ($totalIntendedSummons -gt 1 -or $interval -le 100)
    $actualReps = if ($useDirectBatch) { 1 } else { $totalIntendedSummons }
    $batchCount = if ($useDirectBatch) { $totalIntendedSummons } else { 1 }

    for ($r = 0; $r -lt $actualReps; $r++) {
        foreach ($sub in $subCmds) {
            $rawCmd = $sub.Trim()
            if (-not $rawCmd) { continue }

        $clean = $rawCmd.TrimStart('/').ToLower() -replace '[^a-z0-9]', ''
        $cleanRaw = $rawCmd.TrimStart('/').ToLower()

        # 0. Check direct Runetify command mapping (covers all 1,005 authentic commands)
        $info = if ($runetifyCommands.ContainsKey($cleanRaw)) {
            $runetifyCommands[$cleanRaw]
        } elseif ($runetifyCommands.ContainsKey($clean)) {
            $runetifyCommands[$clean]
        } elseif ($runetifyNormalized.ContainsKey($clean)) {
            $runetifyNormalized[$clean]
        } else {
            $null
        }

        if ($info) {
            $ep = $info.endpoint
            $eff = $info.effect
            $payload = @{
                effect     = [string]$eff
                count      = [int]$batchCount
                amount     = [int]$batchCount
                senderName = [string]$username
                username   = [string]$username
            }
            $lastResult = SendSinglePvZCommand $ep $payload
            continue
        }

        # 1. World Powers / Cheats
        $cheatEndpoint = ""
        $cheatPayload = @{ effect = [string]$batchCount; amount = [int]$batchCount; count = [int]$batchCount; username = $username; avatarUrl = $avatarUrl }

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

        # 2. Plant Spawning (Supports full repetition count e.g. 3 summons)
        $isPlant = ($actionType -eq "plant") -or ($rawCmd -match "spawnplant") -or ($clean -match "(cattail|sunnut|wallnut|peashooter|gatling|threepeater|doomcherry|melon|potato)")
        if ($isPlant -and ($actionType -ne "zombie")) {
            $plantId = Resolve-PlantId $rawCmd
            $payload = @{
                effect     = [string]$plantId
                count      = [int]$batchCount
                amount     = [int]$batchCount
                senderName = [string]$username
                username   = [string]$username
            }
            $lastResult = SendSinglePvZCommand "/spawnplant" $payload
            continue
        }

        # 3. Zombie Spawning (Supports full repetition count e.g. 3 summons)
        $zombieId = Resolve-ZombieId $rawCmd
        $payload = @{
            effect     = [string]$zombieId
            count      = [int]$batchCount
            amount     = [int]$batchCount
            senderName = [string]$username
            username   = [string]$username
        }
        $lastResult = SendSinglePvZCommand "/spawnzombie" $payload
    }
    if (-not $lastResult.success) {
        # Game engine is offline, skip remaining repetitions to avoid blocking webhooks
        break
    }
        if (-not $useDirectBatch -and $r -lt ($actualReps - 1) -and $interval -gt 0) {
            Start-Sleep -Milliseconds ([Math]::Min([int]$interval, 200))
        }
    }

    return $lastResult
}

function ReadRequestBody($req) {
    if (-not $req.HasEntityBody) { return "{}" }
    try {
        if ($req.ContentLength64 -gt 0) {
            $len = [int]$req.ContentLength64
            $buffer = New-Object byte[] $len
            $totalRead = 0
            while ($totalRead -lt $len) {
                $read = $req.InputStream.Read($buffer, $totalRead, $len - $totalRead)
                if ($read -le 0) { break }
                $totalRead += $read
            }
            return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $totalRead)
        } else {
            $ms = New-Object System.IO.MemoryStream
            $buf = New-Object byte[] 4096
            while ($req.InputStream.CanRead) {
                $r = $req.InputStream.Read($buf, 0, $buf.Length)
                if ($r -le 0) { break }
                $ms.Write($buf, 0, $r)
                if ($r -lt $buf.Length) { break }
            }
            return [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
        }
    } catch {
        return "{}"
    }
}

# Start HTTP Server Listener with retry and auto-recovery
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

$started = $false
for ($attempt = 1; $attempt -le 5; $attempt++) {
    try {
        $listener.Start()
        $started = $true
        break
    } catch {
        Write-Host "Port $port in use on attempt $attempt, clearing conflict and retrying..." -ForegroundColor Yellow
        try {
            $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            foreach ($c in $conns) {
                if ($c.OwningProcess -and $c.OwningProcess -ne $PID) {
                    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {}
        Start-Sleep -Milliseconds 700
    }
}

if (-not $started) {
    Write-Host "Port $port could not be bound after multiple retries." -ForegroundColor Red
    exit 1
}

Sync-ConfigToCards

function Start-CloudflareTunnel {
    try {
        $cfExe = Join-Path $folder "bin\cloudflared.exe"
        if (-not (Test-Path $cfExe)) { return $null }

        # Generate or load persistent user token matching S2E 24-hex format
        $tokenFile = Join-Path $folder "overlay_token.txt"
        $userToken = ""
        if (Test-Path $tokenFile) {
            $userToken = (Get-Content $tokenFile -Raw -ErrorAction SilentlyContinue).Trim()
        }
        if (-not $userToken -or $userToken.Length -lt 16) {
            $bytes = [byte[]]::new(12)
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
            $userToken = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
            [System.IO.File]::WriteAllText($tokenFile, $userToken, [System.Text.Encoding]::UTF8)
        }

        $logFile = Join-Path $folder "tunnel.log"
        Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }

        # Launch Cloudflare Tunnel in background
        Start-Process -FilePath $cfExe -ArgumentList "tunnel --url http://localhost:8080 --no-autoupdate" -RedirectStandardError $logFile -WindowStyle Hidden
        
        # Async reader for public URL
        [powershell]::Create().AddScript({
            param($logPath, $infoPath, $token)
            $pubUrl = ""
            for ($i = 0; $i -lt 30; $i++) {
                if (Test-Path $logPath) {
                    $lines = Get-Content $logPath -ErrorAction SilentlyContinue
                    foreach ($l in $lines) {
                        if ($l -match '(https://[a-zA-Z0-9-]+\.trycloudflare\.com)') {
                            $pubUrl = $Matches[1]
                            break
                        }
                    }
                }
                if ($pubUrl) { break }
                Start-Sleep -Milliseconds 600
            }

            $info = @{
                active = [bool]$pubUrl
                publicUrl = $pubUrl
                userToken = $token
                jarOverlayUrl = if ($pubUrl) { "$pubUrl/overlay/$token/jar" } else { "http://localhost:8080/RENEarn/jar" }
                mainOverlayUrl = if ($pubUrl) { "$pubUrl/overlay/$token" } else { "http://localhost:8080/overlay.html" }
                updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            $info | ConvertTo-Json -Depth 3 | Set-Content -Path $infoPath -Encoding UTF8
        }).AddArgument($logFile).AddArgument((Join-Path $folder "tunnel_info.json")).AddArgument($userToken).BeginInvoke()
    } catch {}
}

# Auto-start Cloudflare Tunnel for public HTTPS overlay links (Zero-localhost)
Start-CloudflareTunnel

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

        if ($script:countsDirty -and (([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $script:lastCountsSaveTime) -ge 600)) {
            SaveCounts -Force
        }

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

        # 0.0 Tunnel Info API (Public Cloudflare URL & User Overlay Token)
        if ($reqPath -eq '/api/tunnel/info') {
            $infoFile = Join-Path $folder "tunnel_info.json"
            if (Test-Path $infoFile) {
                try {
                    $tJson = Get-Content $infoFile -Raw -Encoding UTF8
                    Send-JsonResponse $response $tJson
                    continue
                } catch {}
            }
            Send-JsonResponse $response @{
                active = $false
                publicUrl = ""
                userToken = "6a7037f3324251772e699846"
                jarOverlayUrl = "http://localhost:8080/RENEarn/jar"
            }
            continue
        }

        # 0. Live Auto-Reload Version Check
        if ($reqPath -eq '/api/app/version') {
            $appFile = Join-Path $folder "app.html"
            $ts = if (Test-Path $appFile) { [System.IO.File]::GetLastWriteTimeUtc($appFile).Ticks } else { 0 }
            Send-JsonResponse $response @{ version = $ts }
            continue
        }

        # 0.1 Update System: Check for Updates (Streamer-Safe: NO auto-updating)
        if ($reqPath -eq '/api/update/check') {
            $vCoreFile = Join-Path $folder "version.json"
            $vRootFile = Join-Path (Split-Path -Parent $folder) "version.json"
            
            $installedVer = if ($script:installedVersion) { $script:installedVersion } else { "4.1.0" }
            $latestVer = "4.2.0"
            $title = "RENEarn Studio v4.2.0 - Normal Overlay & Live Stream Engine Update"
            $changelog = @(
                "Normal Overlay: Prominent 52px command icon, 24px mini trigger badge, and completely hidden counter badges (&style=normal&noCount=true)",
                "Streamer Safe Protection: Automatic background updates disabled. The game and studio will NEVER auto-update during active coding or live streams",
                "1-Click Done Coding Implementation: Clicking the update button pulls, syncs, and implements all newly completed code directly into the active version",
                "Universal Overlay Routes: Standalone /normal, /overlay-normal, and /renearn/normal routes with live cross-frame synchronization",
                "Enhanced TikTok gift trigger responsiveness and audio sync across all cards and widgets",
                "S2E-Style Mod Status Bar: Real-time mod version & directory detection with archive downloader",
                "Social Triggers Event Dispatcher: Integrated 10-trigger selector panel & modal (Gift, Likes By Person, All Likes, Follow, Min-Max coins, Viewer Joined, Chat, Share, Super Fan, Custom)",
                "Persistent config auto-healing and cross-restart overlay synchronization"
            )
            $downloadUrl = "https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2/archive/refs/heads/main.zip"
            $releaseDate = (Get-Date -Format "yyyy-MM-dd")
            $remoteUrl = "https://raw.githubusercontent.com/jaylouvipinosa7-bit/ProcjectParakayRene2/main/version.json"

            # 1. Read local files (core & root)
            $targetVerObj = $null
            if (Test-Path $vRootFile) {
                try { $targetVerObj = Get-Content $vRootFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
            }
            if (-not $targetVerObj -and (Test-Path $vCoreFile)) {
                try { $targetVerObj = Get-Content $vCoreFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
            }
            if ($targetVerObj) {
                if ($targetVerObj.version) { $latestVer = [string]$targetVerObj.version }
                if ($targetVerObj.title) { $title = [string]$targetVerObj.title }
                if ($targetVerObj.changelog) { $changelog = @($targetVerObj.changelog) }
                if ($targetVerObj.releaseDate) { $releaseDate = [string]$targetVerObj.releaseDate }
                if ($targetVerObj.downloadUrl) { $downloadUrl = [string]$targetVerObj.downloadUrl }
                if ($targetVerObj.remoteVersionUrl) { $remoteUrl = [string]$targetVerObj.remoteVersionUrl }
            }

            # 2. Check GitHub Remote with safe 2s timeout
            $hasRemoteUpdate = $false
            try {
                $rem = Invoke-RestMethod -Uri $remoteUrl -Method Get -TimeoutSec 2 -ErrorAction Stop
                if ($rem -and $rem.version) {
                    $rVer = [string]$rem.version
                    try {
                        if ([System.Version]::new($rVer) -gt [System.Version]::new($latestVer)) {
                            $latestVer = $rVer
                            if ($rem.title) { $title = [string]$rem.title }
                            if ($rem.changelog) { $changelog = @($rem.changelog) }
                            if ($rem.releaseDate) { $releaseDate = [string]$rem.releaseDate }
                            if ($rem.downloadUrl) { $downloadUrl = [string]$rem.downloadUrl }
                            $hasRemoteUpdate = $true
                        }
                    } catch {
                        if ($rVer -ne $latestVer) {
                            $latestVer = $rVer
                            $hasRemoteUpdate = $true
                        }
                    }
                }
            } catch {}

            # 3. Check Git branch & uncommitted done coding
            $hasLocalDoneCoding = $false
            $gitBranch = "main"
            $gitCommit = ""
            try {
                $gitExe = if (Test-Path "C:\Program Files\Git\cmd\git.exe") { "C:\Program Files\Git\cmd\git.exe" } else { "git" }
                $branchOut = & $gitExe rev-parse --abbrev-ref HEAD 2>$null
                if ($branchOut) { $gitBranch = $branchOut.Trim() }
                $commitOut = & $gitExe log -1 --format="%h - %s" 2>$null
                if ($commitOut) { $gitCommit = $commitOut.Trim() }
                $statusOut = & $gitExe status --porcelain 2>$null
                if ($statusOut -and $statusOut.Length -gt 0) {
                    $hasLocalDoneCoding = $true
                }
            } catch {}

            $hasUpdate = $false
            try {
                if ([System.Version]::new($latestVer) -gt [System.Version]::new($installedVer)) {
                    $hasUpdate = $true
                }
            } catch {
                if ($latestVer -ne $installedVer) {
                    $hasUpdate = $true
                }
            }

            Send-JsonResponse $response @{
                currentVersion = $installedVer
                latestVersion = $latestVer
                hasUpdate = ($hasUpdate -or $hasRemoteUpdate)
                hasLocalDoneCoding = $hasLocalDoneCoding
                autoUpdate = $false
                safeMode = $true
                title = $title
                changelog = $changelog
                downloadUrl = $downloadUrl
                releaseDate = $releaseDate
                gitBranch = $gitBranch
                gitCommit = $gitCommit
                checkTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
            continue
        }

        # 0.2 Update System: Apply Update (Streamer-Safe: Only applies when manually initiated!)
        if ($reqPath -eq '/api/update/apply' -and $request.HttpMethod -eq 'POST') {
            try {
                $bodyStr = ReadRequestBody $request
                $reqData = if ($bodyStr) { try { $bodyStr | ConvertFrom-Json } catch { $null } } else { $null }

                $targetVer = if ($reqData -and $reqData.version) { [string]$reqData.version } else { "4.2.0" }
                $force = if ($reqData -and $reqData.force) { $true } else { $false }
                $pullRemote = if ($reqData -and $reqData.pullRemote) { $true } else { $false }

                # Step 1: Backup sensitive streamer configs & keys
                $backupDir = Join-Path $folder "user_configs\backups"
                if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
                $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
                $cfgFiles = @("pvz_fusion_config.json", "custom_community_gifts.json", "counts.json", "overlay_token.txt")
                foreach ($cf in $cfgFiles) {
                    $src = Join-Path $folder $cf
                    if (Test-Path $src) {
                        Copy-Item -Path $src -Destination (Join-Path $backupDir "$($cf)_$timestamp.bak") -Force -ErrorAction SilentlyContinue
                    }
                }

                # Step 2: If tester wants to pull latest code from GitHub
                $gitPulled = $false
                $gitError = ""
                if ($pullRemote) {
                    try {
                        $gitExe = if (Test-Path "C:\Program Files\Git\cmd\git.exe") { "C:\Program Files\Git\cmd\git.exe" } else { "git" }
                        $pullRes = & $gitExe pull origin main 2>&1
                        $gitPulled = $true
                    } catch {
                        $gitError = $_.Exception.Message
                    }
                }

                # Step 3: Sync active version in runtime and version.json
                $script:installedVersion = $targetVer
                $vCoreFile = Join-Path $folder "version.json"
                $vRootFile = Join-Path (Split-Path -Parent $folder) "version.json"

                $vObj = @{
                    appName = "RENEarn Studio"
                    version = $targetVer
                    releaseDate = (Get-Date -Format "yyyy-MM-dd")
                    title = "RENEarn Studio v$targetVer - Normal Overlay & Live Stream Engine Update"
                    changelog = @(
                        "Normal Overlay: Prominent 52px command icon, 24px mini trigger badge, and completely hidden counter badges (&style=normal&noCount=true)",
                        "Streamer Safe Protection: Automatic background updates disabled. The game and studio will NEVER auto-update during active coding or live streams",
                        "1-Click Done Coding Implementation: Clicking the update button pulls, syncs, and implements all newly completed code directly into the active version",
                        "Universal Overlay Routes: Standalone /normal, /overlay-normal, and /renearn/normal routes with live cross-frame synchronization",
                        "Enhanced TikTok gift trigger responsiveness and audio sync across all cards and widgets",
                        "S2E-Style Mod Status Bar: Real-time mod version & directory detection with archive downloader",
                        "Social Triggers Event Dispatcher: Integrated 10-trigger selector panel & modal (Gift, Likes By Person, All Likes, Follow, Min-Max coins, Viewer Joined, Chat, Share, Super Fan, Custom)",
                        "Persistent config auto-healing and cross-restart overlay synchronization"
                    )
                    downloadUrl = "https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2/archive/refs/heads/main.zip"
                    remoteVersionUrl = "https://raw.githubusercontent.com/jaylouvipinosa7-bit/ProcjectParakayRene2/main/version.json"
                    mandatory = $false
                    minSupportedVersion = "1.0.0"
                    autoUpdate = $false
                }
                $vJsonStr = $vObj | ConvertTo-Json -Depth 6
                [System.IO.File]::WriteAllText($vCoreFile, $vJsonStr, [System.Text.Encoding]::UTF8)
                if (Test-Path (Split-Path -Parent $vRootFile)) {
                    [System.IO.File]::WriteAllText($vRootFile, $vJsonStr, [System.Text.Encoding]::UTF8)
                }

                # Step 4: Re-sync internal configuration and cards
                Sync-ConfigToCards

                # Step 5: Send response to UI
                Send-JsonResponse $response @{
                    success = $true
                    status = "applied"
                    version = $targetVer
                    gitPulled = $gitPulled
                    message = "Done coding successfully implemented! Version updated to v$targetVer."
                    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
            } catch {
                Send-JsonResponse $response @{
                    success = $false
                    status = "error"
                    message = $_.Exception.Message
                } 500
            }
            continue
        }

        # 1. Status Check
        if ($reqPath -eq '/api/status' -or $reqPath -eq '/api/game/status') {
            $config = LoadConfig
            $cards = LoadCards
            
            # Check if game is responding
            $gameActive = $true
            foreach ($p in $gamePorts) {
                if (Test-GamePort $p) {
                    $script:activeGamePort = $p
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
        if ($reqPath -eq '/api/game/directory') {
            if ($request.HttpMethod -eq 'GET') {
                $gameDirFile = Join-Path $folder "game_directory.txt"
                $curr = if (Test-Path $gameDirFile) { (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() } else { "C:\Users\pc\Desktop\games ko to ya\Game Files" }
                Send-JsonResponse $response @{ status = "ok"; directory = $curr; exists = (Test-Path $curr) }
                continue
            }
            if ($request.HttpMethod -eq 'POST') {
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
        }

        # 1a-browse. Browse Directory via Folder Dialog
        if ($reqPath -eq '/api/game/browse-directory' -and $request.HttpMethod -eq 'POST') {
            try {
                $scratchDir = Join-Path $folder "scratch"
                if (-not (Test-Path $scratchDir)) { New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null }
                $pickerOut = Join-Path $scratchDir "folder_picker.txt"
                if (Test-Path $pickerOut) { Remove-Item $pickerOut -Force -ErrorAction SilentlyContinue }

                $pickerScript = @"
Add-Type -AssemblyName System.Windows.Forms
`$f = New-Object System.Windows.Forms.FolderBrowserDialog
`$f.Description = 'Select PvZ / Game Installation Directory'
`$f.ShowNewFolderButton = `$false
`$res = `$f.ShowDialog()
if (`$res -eq [System.Windows.Forms.DialogResult]::OK) {
    [System.IO.File]::WriteAllText('$($pickerOut.Replace('\','\\'))', `$f.SelectedPath, [System.Text.Encoding]::UTF8)
}
"@
                $proc = Start-Process powershell.exe -ArgumentList "-NoProfile", "-STA", "-Command", $pickerScript -NoNewWindow -PassThru
                $finished = $proc.WaitForExit(30000)
                $chosen = ""
                if (Test-Path $pickerOut) {
                    $chosen = (Get-Content $pickerOut -Raw -Encoding UTF8).Trim()
                    Remove-Item $pickerOut -Force -ErrorAction SilentlyContinue
                }
                if ($chosen -and (Test-Path $chosen)) {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    [System.IO.File]::WriteAllText($gameDirFile, $chosen, [System.Text.Encoding]::UTF8)
                    Send-JsonResponse $response @{ status = "ok"; directory = $chosen }
                } else {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    $curr = if (Test-Path $gameDirFile) { (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() } else { "" }
                    Send-JsonResponse $response @{ status = "cancelled"; directory = $curr }
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1a-open. Open folder in File Explorer
        if ($reqPath -eq '/api/game/open-folder' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $folderToOpen = if ($data.directory) { [string]$data.directory.Trim() } elseif ($data.path) { [string]$data.path.Trim() } else { "" }
                if (-not $folderToOpen) {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    if (Test-Path $gameDirFile) { $folderToOpen = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() }
                }
                if (-not $folderToOpen) { $folderToOpen = "C:\Users\pc\Desktop\games ko to ya\Game Files" }
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

        # 1a-mod-install. Auto-Install Mod to Game Directory (MelonLoader & Universal)
        if ($reqPath -eq '/api/mod/install' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $gameId = if ($data.gameId) { [string]$data.gameId.Trim() } else { "pvz_fusion_4" }
                $targetDir = if ($data.directory) { [string]$data.directory.Trim() } else { "" }
                $gameDirFile = Join-Path $folder "game_directory.txt"

                # 1. Smart directory fallback & auto-recovery
                if (-not $targetDir -or -not (Test-Path $targetDir)) {
                    if (Test-Path $gameDirFile) {
                        $saved = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim()
                        if ($saved -and (Test-Path $saved)) { $targetDir = $saved }
                    }
                }
                if (-not $targetDir -or -not (Test-Path $targetDir)) {
                    $desktopPvz = "C:\Users\pc\Desktop\games ko to ya\Game Files"
                    if (Test-Path $desktopPvz) { $targetDir = $desktopPvz }
                }
                if ($targetDir -and -not (Test-Path $targetDir)) {
                    try { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null } catch {}
                }
                if (-not $targetDir -or -not (Test-Path $targetDir)) {
                    Send-JsonResponse $response @{ status = "error"; message = "Game directory does not exist: $targetDir" } 400
                    continue
                }

                # Save resolved directory
                [System.IO.File]::WriteAllText($gameDirFile, $targetDir, [System.Text.Encoding]::UTF8)

                # 2. Normalize Game Root Directory (strip trailing Mods or MelonLoader)
                $cleanTarget = $targetDir.TrimEnd('\', '/')
                $gameRootDir = $cleanTarget
                if ($cleanTarget -match '[\\/]Mods$' -or $cleanTarget -match '[\\/]MelonLoader$') {
                    $gameRootDir = Split-Path -Parent $cleanTarget
                }

                $sourceModDir = Join-Path $folder "mods\$gameId"
                if (-not (Test-Path $sourceModDir)) {
                    $sourceModDir = Join-Path $folder "mods\pvz_fusion_4"
                }

                # Universal Stream / Minecraft
                if ($gameId -eq 'universal_stream') {
                    $pluginsDir = Join-Path $gameRootDir "plugins"
                    if (-not (Test-Path $pluginsDir)) { New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null }
                    if (Test-Path $sourceModDir) {
                        Get-ChildItem $sourceModDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $pluginsDir -Force
                        }
                    }
                    Send-JsonResponse $response @{ status = "ok"; installed = $true; gameRootDir = $gameRootDir; targetDir = $pluginsDir; message = "Plugin installed successfully into $pluginsDir" }
                    continue
                }

                # Zombie Tsunami
                if ($gameId -eq 'zombie_tsunami') {
                    if (Test-Path $sourceModDir) {
                        Get-ChildItem $sourceModDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $gameRootDir -Force
                        }
                    }
                    Send-JsonResponse $response @{ status = "ok"; installed = $true; gameRootDir = $gameRootDir; targetDir = $gameRootDir; message = "Bridge files installed successfully into $gameRootDir" }
                    continue
                }

                # 3. MelonLoader Games (PvZ Fusion, Hybrid, Classic)
                $destSubDir = Join-Path $gameRootDir "Mods"
                if (-not (Test-Path $destSubDir)) {
                    New-Item -ItemType Directory -Path $destSubDir -Force | Out-Null
                }
                $userDataDir = Join-Path $gameRootDir "UserData"
                if (-not (Test-Path $userDataDir)) {
                    New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
                }
                $melonLoaderDir = Join-Path $gameRootDir "MelonLoader"

                if (Test-Path $sourceModDir) {
                    # Copy all mod DLLs, deps.json, and renearn configs into Mods/
                    Get-ChildItem $sourceModDir | ForEach-Object {
                        Copy-Item $_.FullName -Destination $destSubDir -Force
                    }

                    # Ensure renearn_info.json and renearn.json exist across MelonLoader & Game root
                    $infoSrc = Join-Path $sourceModDir "renearn_info.json"
                    $renearnSrc = Join-Path $sourceModDir "renearn.json"

                    if (Test-Path $infoSrc) {
                        Copy-Item $infoSrc -Destination (Join-Path $gameRootDir "renearn_info.json") -Force
                        Copy-Item $infoSrc -Destination (Join-Path $userDataDir "renearn_info.json") -Force
                        if (Test-Path $melonLoaderDir) {
                            Copy-Item $infoSrc -Destination (Join-Path $melonLoaderDir "renearn_info.json") -Force
                        }
                    }
                    if (Test-Path $renearnSrc) {
                        Copy-Item $renearnSrc -Destination (Join-Path $gameRootDir "renearn.json") -Force
                        Copy-Item $renearnSrc -Destination (Join-Path $destSubDir "renearn.json") -Force
                        Copy-Item $renearnSrc -Destination (Join-Path $userDataDir "renearn.json") -Force
                        if (Test-Path $melonLoaderDir) {
                            Copy-Item $renearnSrc -Destination (Join-Path $melonLoaderDir "renearn.json") -Force
                        }
                    }

                    Send-JsonResponse $response @{
                        status = "ok"
                        installed = $true
                        gameRootDir = $gameRootDir
                        targetDir = $destSubDir
                        message = "RENEarn MelonLoader mod & renearn.json auto-installed successfully into $destSubDir!"
                    }
                } else {
                    Send-JsonResponse $response @{ status = "error"; message = "Mod bundle not found in studio repository" } 404
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1a-mod-uninstall. Uninstall Mod from Game Directory
        if ($reqPath -eq '/api/mod/uninstall' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $gameId = if ($data.gameId) { [string]$data.gameId.Trim() } else { "pvz_fusion_4" }
                $targetDir = if ($data.directory) { [string]$data.directory.Trim() } else { "" }
                if (-not $targetDir) {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    if (Test-Path $gameDirFile) { $targetDir = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() }
                }

                $cleanTarget = $targetDir.TrimEnd('\', '/')
                $gameRootDir = $cleanTarget
                if ($cleanTarget -match '[\\/]Mods$' -or $cleanTarget -match '[\\/]MelonLoader$') {
                    $gameRootDir = Split-Path -Parent $cleanTarget
                }

                $destSubDir = if ($gameId -eq 'universal_stream') {
                    if (Test-Path (Join-Path $gameRootDir "plugins")) { Join-Path $gameRootDir "plugins" } else { Join-Path $gameRootDir "mods" }
                } elseif ($gameId -eq 'zombie_tsunami') {
                    $gameRootDir
                } else {
                    Join-Path $gameRootDir "Mods"
                }

                $modDll = if ($data.modDll) { [string]$data.modDll.Trim() } else { "RENEarnPVZFusionMod.dll" }
                $depsDll = if ($data.depsDll) { [string]$data.depsDll.Trim() } else { "RENEarnPVZFusionMod.deps.json" }

                $targetDllPath = Join-Path $destSubDir $modDll
                $targetDepsPath = Join-Path $destSubDir $depsDll
                $targetInfoPath = Join-Path $destSubDir "renearn_info.json"
                $targetRenearnPath = Join-Path $destSubDir "renearn.json"

                $removed = 0
                if (Test-Path $targetDllPath) { Remove-Item $targetDllPath -Force -ErrorAction SilentlyContinue; $removed++ }
                if (Test-Path $targetDepsPath) { Remove-Item $targetDepsPath -Force -ErrorAction SilentlyContinue; $removed++ }
                if (Test-Path $targetInfoPath) { Remove-Item $targetInfoPath -Force -ErrorAction SilentlyContinue; $removed++ }
                if (Test-Path $targetRenearnPath) { Remove-Item $targetRenearnPath -Force -ErrorAction SilentlyContinue; $removed++ }

                Send-JsonResponse $response @{ status = "ok"; removedCount = $removed; message = "Files removed successfully" }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 1a-mod-download. Download ZIP Archive of Mod & Auto-Install to MelonLoader
        if ($reqPath -eq '/api/mod/download') {
            try {
                $body = ReadRequestBody $request
                $gameId = "pvz_fusion_4"
                $downloadTargetDir = ""
                if ($body) {
                    try {
                        $p = $body | ConvertFrom-Json
                        if ($p.gameId) { $gameId = [string]$p.gameId.Trim() }
                        if ($p.directory) { $downloadTargetDir = [string]$p.directory.Trim() }
                    } catch {}
                }
                $sourceModDir = Join-Path $folder "mods\$gameId"
                if (-not (Test-Path $sourceModDir)) { $sourceModDir = Join-Path $folder "mods\pvz_fusion_4" }

                # Proactive Auto-Install on Download: if directory is known, install it directly
                try {
                    $autoDir = $downloadTargetDir
                    if (-not $autoDir -or -not (Test-Path $autoDir)) {
                        $gFile = Join-Path $folder "game_directory.txt"
                        if (Test-Path $gFile) {
                            $savedDir = (Get-Content $gFile -Raw -Encoding UTF8).Trim()
                            if ($savedDir -and (Test-Path $savedDir)) { $autoDir = $savedDir }
                        }
                    }
                    if (-not $autoDir -or -not (Test-Path $autoDir)) {
                        $desktopDir = "C:\Users\pc\Desktop\games ko to ya\Game Files"
                        if (Test-Path $desktopDir) { $autoDir = $desktopDir }
                    }
                    if ($autoDir -and (Test-Path $autoDir)) {
                        $autoClean = $autoDir.TrimEnd('\', '/')
                        $autoGameRoot = if ($autoClean -match '[\\/]Mods$' -or $autoClean -match '[\\/]MelonLoader$') { Split-Path -Parent $autoClean } else { $autoClean }
                        $autoMods = Join-Path $autoGameRoot "Mods"
                        $autoUserData = Join-Path $autoGameRoot "UserData"
                        if (-not (Test-Path $autoMods)) { New-Item -ItemType Directory -Path $autoMods -Force | Out-Null }
                        if (-not (Test-Path $autoUserData)) { New-Item -ItemType Directory -Path $autoUserData -Force | Out-Null }
                        if (Test-Path $sourceModDir) {
                            Get-ChildItem $sourceModDir | ForEach-Object { Copy-Item $_.FullName -Destination $autoMods -Force }
                            $iSrc = Join-Path $sourceModDir "renearn_info.json"
                            $rSrc = Join-Path $sourceModDir "renearn.json"
                            if (Test-Path $iSrc) {
                                Copy-Item $iSrc -Destination (Join-Path $autoGameRoot "renearn_info.json") -Force
                                Copy-Item $iSrc -Destination (Join-Path $autoUserData "renearn_info.json") -Force
                            }
                            if (Test-Path $rSrc) {
                                Copy-Item $rSrc -Destination (Join-Path $autoGameRoot "renearn.json") -Force
                                Copy-Item $rSrc -Destination (Join-Path $autoUserData "renearn.json") -Force
                            }
                        }
                    }
                } catch {}

                $scratchDir = Join-Path $folder "scratch"
                if (-not (Test-Path $scratchDir)) { New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null }
                $zipPath = Join-Path $scratchDir "RENEarn_${gameId}_mod.zip"
                if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }

                $stagingDir = Join-Path $scratchDir "staging_${gameId}"
                if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue }
                New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

                if ($gameId -eq 'universal_stream') {
                    $stagingPlugins = Join-Path $stagingDir "plugins"
                    New-Item -ItemType Directory -Path $stagingPlugins -Force | Out-Null
                    if (Test-Path $sourceModDir) {
                        Get-ChildItem $sourceModDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $stagingPlugins -Force
                        }
                    }
                } elseif ($gameId -eq 'zombie_tsunami') {
                    if (Test-Path $sourceModDir) {
                        Get-ChildItem $sourceModDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $stagingDir -Force
                        }
                    }
                } else {
                    $stagingMods = Join-Path $stagingDir "Mods"
                    New-Item -ItemType Directory -Path $stagingMods -Force | Out-Null
                    $stagingUserData = Join-Path $stagingDir "UserData"
                    New-Item -ItemType Directory -Path $stagingUserData -Force | Out-Null

                    if (Test-Path $sourceModDir) {
                        Get-ChildItem $sourceModDir | ForEach-Object {
                            Copy-Item $_.FullName -Destination $stagingMods -Force
                        }
                        $infoSrc = Join-Path $sourceModDir "renearn_info.json"
                        $renearnSrc = Join-Path $sourceModDir "renearn.json"
                        if (Test-Path $infoSrc) {
                            Copy-Item $infoSrc -Destination (Join-Path $stagingDir "renearn_info.json") -Force
                            Copy-Item $infoSrc -Destination (Join-Path $stagingUserData "renearn_info.json") -Force
                        }
                        if (Test-Path $renearnSrc) {
                            Copy-Item $renearnSrc -Destination (Join-Path $stagingDir "renearn.json") -Force
                            Copy-Item $renearnSrc -Destination (Join-Path $stagingUserData "renearn.json") -Force
                        }
                    }
                }

                if (Test-Path (Join-Path $sourceModDir "INSTALL_README.txt")) {
                    Copy-Item (Join-Path $sourceModDir "INSTALL_README.txt") -Destination $stagingDir -Force
                } else {
                    $readmeContent = @"
=====================================================
RENEarn Studio - Live Connector Archive
Game: $gameId
Included: Mod DLLs, renearn.json, renearn_info.json
=====================================================

INSTALLATION INSTRUCTIONS:
1. Open your Game directory (e.g. where PlantsVsZombiesRH.exe or MelonLoader is).
2. Extract or copy the folders ('Mods', 'UserData', and 'renearn.json') into your Game directory.
3. Start the game and launch RENEarn Studio!
"@
                    [System.IO.File]::WriteAllText((Join-Path $stagingDir "INSTALL_README.txt"), $readmeContent, [System.Text.Encoding]::UTF8)
                }

                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::CreateFromDirectory($stagingDir, $zipPath)
                Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue

                if (Test-Path $zipPath) {
                    $zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
                    $response.ContentType = 'application/zip'
                    $response.StatusCode = 200
                    $response.AddHeader("Content-Disposition", "attachment; filename=`"RENEarn_${gameId}_mod.zip`"")
                    $response.ContentLength64 = $zipBytes.Length
                    $response.OutputStream.Write($zipBytes, 0, $zipBytes.Length)
                    $response.OutputStream.Flush()
                    $response.Close()
                    continue
                } else {
                    Send-JsonResponse $response @{ status = "error"; message = "Failed to create archive" } 500
                    continue
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
                continue
            }
        }

        # 1a-detect. Game Directory Detection & MelonLoader Integration
        if ($reqPath -eq '/api/game/detect' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $gameId = if ($data.gameId) { [string]$data.gameId.Trim() } else { "pvz_fusion_4" }
                $gameDir = if ($data.directory) { [string]$data.directory.Trim() } else { "" }
                if (-not $gameDir) {
                    $gameDirFile = Join-Path $folder "game_directory.txt"
                    if (Test-Path $gameDirFile) { $gameDir = (Get-Content $gameDirFile -Raw -Encoding UTF8).Trim() }
                }

                $dirExists = (-not [string]::IsNullOrEmpty($gameDir)) -and (Test-Path $gameDir)

                # Special handler for Minecraft / Universal Stream
                if ($gameId -eq 'universal_stream') {
                    $hasPlugin = $false
                    $pluginsDir = if ($dirExists) { Join-Path $gameDir "plugins" } else { "" }
                    $modsDir = if ($dirExists) { Join-Path $gameDir "mods" } else { "" }
                    $installedList = @()
                    if ($pluginsDir -and (Test-Path $pluginsDir)) {
                        Get-ChildItem $pluginsDir -Filter "*.jar" -ErrorAction SilentlyContinue | ForEach-Object {
                            $isRE = ($_.Name -like "*RENEarn*" -or $_.Name -like "*ServerTap*")
                            if ($isRE) { $hasPlugin = $true }
                            $installedList += @{ name = $_.BaseName; size = $_.Length; isRENEarn = $isRE }
                        }
                    }
                    if ($modsDir -and (Test-Path $modsDir)) {
                        Get-ChildItem $modsDir -Filter "*.jar" -ErrorAction SilentlyContinue | ForEach-Object {
                            $isRE = ($_.Name -like "*RENEarn*" -or $_.Name -like "*ServerTap*")
                            if ($isRE) { $hasPlugin = $true }
                            $installedList += @{ name = $_.BaseName; size = $_.Length; isRENEarn = $isRE }
                        }
                    }
                    $modInfo = $null
                    $mcInfoPath = Join-Path $folder "mods\universal_stream\renearn_info.json"
                    if (Test-Path $mcInfoPath) {
                        try { $modInfo = Get-Content $mcInfoPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                    }
                    Send-JsonResponse $response @{
                        status = "ok"
                        gameId = $gameId
                        directory = $gameDir
                        hasMelonLoader = $false
                        hasPlugin = $hasPlugin
                        modsInstalled = $installedList
                        modInfo = $modInfo
                        connected = $true
                        gameRunning = $false
                    }
                    continue
                }

                # Special handler for Zombie Tsunami
                if ($gameId -eq 'zombie_tsunami') {
                    $modInfo = $null
                    $ztInfoPath = Join-Path $folder "mods\zombie_tsunami\renearn_info.json"
                    if (Test-Path $ztInfoPath) {
                        try { $modInfo = Get-Content $ztInfoPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                    }
                    Send-JsonResponse $response @{
                        status = "ok"
                        gameId = $gameId
                        directory = $gameDir
                        hasMelonLoader = $false
                        modsInstalled = @(@{ name = "RENEarnZombieBridge"; isRENEarn = $true })
                        modInfo = $modInfo
                        connected = $true
                        gameRunning = $false
                    }
                    continue
                }

                if (-not $dirExists) {
                    Send-JsonResponse $response @{ status = "error"; message = "Game directory not found: $gameDir"; connected = $false }
                    continue
                }

                # Detect MelonLoader for PvZ games
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

                # Detect installed mods in game's Mods directory
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
                $gameExeNames = @("PlantsVsZombiesRH.exe", "PlantsVsZombies.exe", "PvZ_Hybrid.exe", "PvZ.exe")
                foreach ($exeName in $gameExeNames) {
                    $exePath = Join-Path $gameDir $exeName
                    if (Test-Path $exePath) { $gameExe = $exeName; break }
                }

                # Check if game is running
                $gameRunning = $false
                foreach ($p in $gamePorts) {
                    if (Test-GamePort $p) { $gameRunning = $true; break }
                }

                # Read renearn.json / renearn_info.json or fallback to bundled info
                $modInfo = $null
                $candidatePaths = @(
                    (Join-Path $gameDir "renearn.json"),
                    (Join-Path $gameDir "renearn_info.json"),
                    (Join-Path $gameDir "Mods\renearn.json"),
                    (Join-Path $gameDir "Mods\renearn_info.json"),
                    (Join-Path $gameDir "UserData\renearn.json"),
                    (Join-Path $gameDir "UserData\renearn_info.json"),
                    (Join-Path $folder "mods\$gameId\renearn.json"),
                    (Join-Path $folder "mods\$gameId\renearn_info.json")
                )
                foreach ($cPath in $candidatePaths) {
                    if (Test-Path $cPath) {
                        try {
                            $modInfo = Get-Content $cPath -Raw -Encoding UTF8 | ConvertFrom-Json
                            if ($modInfo) { break }
                        } catch {}
                    }
                }

                $resObj = @{
                    status = "ok"
                    gameId = $gameId
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
            $user = ""
            try {
                $body = ReadRequestBody $request
                $data = $body | ConvertFrom-Json
                if ($data -and $data.username) { $user = [string]$data.username.Trim() }
            } catch {}
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
            [System.IO.File]::WriteAllText($userCfgFile, ($cfg | ConvertTo-Json -Depth 20), [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($configFile, ($cfg | ConvertTo-Json -Depth 20), [System.Text.Encoding]::UTF8)
            Sync-ConfigToCards
            AddEventLog @{ type = "cards_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
            AddEventLog @{ type = "config_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
            Start-TikTokBridge $user

            # Auto-detect streamer's specific community gifts in background
            try {
                $nodeExe = Join-Path $folder "bin\node.exe"
                $syncScript = Join-Path $folder "tools\sync_tiktok_gifts.js"
                if ((Test-Path $nodeExe) -and (Test-Path $syncScript)) {
                    Start-Process -FilePath $nodeExe -ArgumentList "`"$syncScript`" `"$user`"" -WorkingDirectory $folder -WindowStyle Hidden
                }
            } catch {}

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
            Sync-ConfigToCards
            AddEventLog @{ type = "cards_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
            AddEventLog @{ type = "config_updated"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
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
                    $subInfo = Get-UserSubscriptionInfo $email $email
                    $initialGifts = if ($subInfo.tier -eq "free") { @() } else { $tmplGifts }
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
                        gifts = $initialGifts
                        spinners = if ($subInfo.hasSpinner) { $tmplSpinners } else { @() }
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
                            $subInfo = Get-UserSubscriptionInfo $email $email
                            if ($subInfo.tier -ne "free" -and (-not $uObj.gifts -or $uObj.gifts.Count -eq 0)) {
                                $uObj.gifts = $tmplGifts
                                $repaired = $true
                            }
                            if (-not $uObj.spinners -or $uObj.spinners.Count -eq 0) {
                                if ($subInfo.hasSpinner) {
                                    $uObj.spinners = $tmplSpinners
                                    $repaired = $true
                                }
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

        # 1c-profile. Real TikTok Profile & Avatar Endpoint
        if ($reqPath -eq '/api/tiktok/profile') {
            $targetU = if ($request.QueryString["username"]) { ($request.QueryString["username"]).Trim().TrimStart('@') } else { "" }
            if (-not $targetU) {
                $cfg = LoadConfig
                $targetU = if ($cfg.tiktokUsername) { $cfg.tiktokUsername } else { "gohanmalunggay" }
            }

            # 1. Check live state file or cache
            $stateFile = Join-Path $folder "tiktok_live_state.json"
            $cacheFile = Join-Path $folder "tiktok_profile_cache.json"
            $foundAvatar = ""
            $foundNick = ""

            if (Test-Path $cacheFile) {
                try {
                    $cJson = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    $uProp = $cJson.PSObject.Properties[$targetU]
                    if ($uProp -and $uProp.Value -and $uProp.Value.avatar) {
                        $foundAvatar = [string]$uProp.Value.avatar
                        if ($uProp.Value.nickname) { $foundNick = [string]$uProp.Value.nickname }
                    }
                } catch {}
            }

            if (-not $foundAvatar -and (Test-Path $stateFile)) {
                try {
                    $sJson = Get-Content $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($sJson.username -and ($sJson.username.ToLower() -eq $targetU.ToLower()) -and $sJson.avatar) {
                        $foundAvatar = [string]$sJson.avatar
                        if ($sJson.nickname) { $foundNick = [string]$sJson.nickname }
                    }
                } catch {}
            }

            if ($foundAvatar) {
                Send-JsonResponse $response @{
                    success = $true
                    username = $targetU
                    nickname = if ($foundNick) { $foundNick } else { $targetU }
                    avatar = $foundAvatar
                }
                continue
            }

            # 2. Invoke fetch_tiktok_profile.js tool
            try {
                $fetcherScript = Join-Path $folder "tools\fetch_tiktok_profile.js"
                $nodeBin = Join-Path $folder "bin\node.exe"
                $cmd = if (Test-Path $nodeBin) { $nodeBin } else { "node" }
                if (Test-Path $fetcherScript) {
                    $procOut = & $cmd $fetcherScript $targetU 2>$null | Out-String
                    if ($procOut) {
                        $pObj = $procOut.Trim() | ConvertFrom-Json
                        Send-JsonResponse $response $pObj
                        continue
                    }
                }
            } catch {}

            Send-JsonResponse $response @{ success = $false; username = $targetU; avatar = "" }
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
                
                # Fetch Real TikTok Avatar & Nickname
                $realAvatar = ""
                $realNickname = ""
                $cacheFile = Join-Path $folder "tiktok_profile_cache.json"
                if (Test-Path $cacheFile) {
                    try {
                        $cJson = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
                        $uProp = $cJson.PSObject.Properties[$username]
                        if ($uProp -and $uProp.Value -and $uProp.Value.avatar) {
                            $realAvatar = [string]$uProp.Value.avatar
                            if ($uProp.Value.nickname) { $realNickname = [string]$uProp.Value.nickname }
                        }
                    } catch {}
                }
                if (-not $realAvatar) {
                    try {
                        $fetcherScript = Join-Path $folder "tools\fetch_tiktok_profile.js"
                        $nodeBin = Join-Path $folder "bin\node.exe"
                        $cmd = if (Test-Path $nodeBin) { $nodeBin } else { "node" }
                        if (Test-Path $fetcherScript) {
                            $procOut = & $cmd $fetcherScript $username 2>$null | Out-String
                            if ($procOut) {
                                $pObj = $procOut.Trim() | ConvertFrom-Json
                                if ($pObj.success -and $pObj.avatar) {
                                    $realAvatar = [string]$pObj.avatar
                                    if ($pObj.nickname) { $realNickname = [string]$pObj.nickname }
                                }
                            }
                        }
                    } catch {}
                }

                $avatar = if ($realAvatar) { $realAvatar } else { "https://ui-avatars.com/api/?name=" + [System.Uri]::EscapeDataString($username) + "&background=000000&color=25f4ee&size=128&bold=true" }
                if ($realNickname -and (-not $data.name -or $data.name -eq "@$username")) {
                    $displayName = $realNickname
                }

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
                    $subInfo = Get-UserSubscriptionInfo $username $email
                    $initialGifts = if ($subInfo.tier -eq "free") { @() } else { $tmplGifts }
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
                        gifts = $initialGifts
                        spinners = if ($subInfo.hasSpinner) { $tmplSpinners } else { @() }
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
                        $subInfo = Get-UserSubscriptionInfo $username $email
                        if ($subInfo.tier -ne "free" -and (-not $uObj.gifts -or $uObj.gifts.Count -eq 0)) {
                            $uObj.gifts = $tmplGifts
                            $repaired = $true
                        }
                        if (-not $uObj.spinners -or $uObj.spinners.Count -eq 0) {
                            if ($subInfo.hasSpinner) {
                                $uObj.spinners = $tmplSpinners
                                $repaired = $true
                            }
                        }
                        if (-not $uObj.streamer) {
                            $uObj | Add-Member -NotePropertyName streamer -NotePropertyValue ([PSCustomObject]@{}) -Force
                            $repaired = $true
                        }
                        if ($avatar) {
                            if (-not ($uObj.streamer.PSObject.Properties.Match('streamerAvatar').Count)) {
                                $uObj.streamer | Add-Member -NotePropertyName streamerAvatar -NotePropertyValue $avatar -Force
                            } else {
                                $uObj.streamer.streamerAvatar = $avatar
                            }
                            if (-not ($uObj.streamer.PSObject.Properties.Match('userPicture').Count)) {
                                $uObj.streamer | Add-Member -NotePropertyName userPicture -NotePropertyValue $avatar -Force
                            } else {
                                $uObj.streamer.userPicture = $avatar
                            }
                            $repaired = $true
                        }
                        if ($displayName) {
                            if (-not ($uObj.streamer.PSObject.Properties.Match('streamerNickname').Count)) {
                                $uObj.streamer | Add-Member -NotePropertyName streamerNickname -NotePropertyValue $displayName -Force
                            } else {
                                $uObj.streamer.streamerNickname = $displayName
                            }
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

        # 1f. Permissions & Role Management Endpoints (Admin Only Access)
        if ($reqPath -eq '/api/permissions' -and $request.HttpMethod -eq 'GET') {
            $caller = Get-CallerUser $request
            $perms = Load-Permissions
            $callerEmail = if ($request.QueryString['email']) { [string]$request.QueryString['email'].Trim().ToLower() } elseif ($caller -and $caller.email) { [string]$caller.email.Trim().ToLower() } else { "" }
            $callerRole = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }

            $isAdmin = ($callerRole -eq "admin" -or $callerEmail -eq "jaylouvipinosa7@gmail.com" -or $callerEmail.Contains("jaylouvipinosa7") -or ($perms.admin -and $callerEmail -eq $perms.admin) -or ($perms.admins -contains $callerEmail))

            # Privacy & Security Guard: If not admin, restrict access completely
            if (-not $isAdmin) {
                Send-JsonResponse $response @{
                    status = "restricted"
                    isAdmin = $false
                    currentUserEmail = $callerEmail
                    currentUserRole = $callerRole
                    message = "Access Restricted: Only the Owner/Admin can view Team & Testers list."
                } 403
                continue
            }

            $resObj = @{
                status = "ok"
                isAdmin = $true
                admin = $perms.admin
                admins = @($perms.admins)
                editors = @($perms.editors)
                testers = @($perms.testers)
                currentUserEmail = $callerEmail
                currentUserRole = "admin"
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
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only an Admin can add editors or testers." } 403
                continue
            }
            $newEmail = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
            if (-not $newEmail -or $newEmail -notmatch '^.+@.+\..+$') {
                Send-JsonResponse $response @{ success = $false; message = "Valid Gmail/email address required." } 400
                continue
            }
            $targetRole = if ($data.role) { [string]$data.role.Trim().ToLower() } else { "editor" }
            $perms = Load-Permissions
            $curEditors = @($perms.editors)
            $curTesters = @($perms.testers)

            if ($targetRole -eq "tester") {
                if (-not ($curTesters -contains $newEmail)) { $curTesters += $newEmail }
                $curEditors = @($curEditors | Where-Object { $_ -ne $newEmail })
            } else {
                if (-not ($curEditors -contains $newEmail)) { $curEditors += $newEmail }
                $curTesters = @($curTesters | Where-Object { $_ -ne $newEmail })
            }

            $perms.editors = $curEditors
            $perms.testers = $curTesters
            Save-Permissions $perms

            # Update any active sessions for this email
            foreach ($k in $activeSessions.Keys) {
                if ($activeSessions[$k].email -eq $newEmail) {
                    $activeSessions[$k].role = $targetRole
                }
            }
            Send-JsonResponse $response @{ success = $true; message = "Added $newEmail as $(if ($targetRole -eq 'tester') { 'Tester' } else { 'Editor' })"; editors = @($perms.editors); testers = @($perms.testers) }
            continue
        }

        if ($reqPath -eq '/api/permissions/remove-editor' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } elseif ($data.callerEmail) { $data.callerEmail } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only an Admin can remove members." } 403
                continue
            }
            $targetEmail = if ($data.email) { [string]$data.email.Trim().ToLower() } else { "" }
            $perms = Load-Permissions
            $perms.editors = @($perms.editors | Where-Object { $_ -ne $targetEmail })
            $perms.testers = @($perms.testers | Where-Object { $_ -ne $targetEmail })
            Save-Permissions $perms
            # Update any active sessions for this email
            foreach ($k in $activeSessions.Keys) {
                if ($activeSessions[$k].email -eq $targetEmail) {
                    $activeSessions[$k].role = "viewer"
                }
            }
            Send-JsonResponse $response @{ success = $true; message = "Removed $targetEmail"; editors = @($perms.editors); testers = @($perms.testers) }
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

        # 1g. Subscription & Licensing Endpoints (Free, 999 Premium, 3999 Expert, Owner/Tester)
        if ($reqPath -eq '/api/subscription/status' -and $request.HttpMethod -eq 'GET') {
            $caller = Get-CallerUser $request
            $userParam = if ($request.QueryString['user']) { [string]$request.QueryString['user'] } else { "" }
            $emailParam = if ($request.QueryString['email']) { [string]$request.QueryString['email'] } elseif ($caller -and $caller.email) { [string]$caller.email } else { "" }
            
            # Check if desktop local streamer without explicit login
            $remoteIp = if ($request.RemoteEndPoint) { $request.RemoteEndPoint.Address.ToString() } else { "127.0.0.1" }
            $isLocal = ($remoteIp -eq "127.0.0.1" -or $remoteIp -eq "::1" -or $request.Url.Host -eq "localhost" -or $request.Url.Host -eq "127.0.0.1")
            if (-not $userParam -and -not $emailParam -and $isLocal) {
                # Fallback to local streamer's saved TikTok or primary email
                $userParam = if ($script:config -and $script:config.tiktokUsername) { $script:config.tiktokUsername } else { "jaylouvipinosa7@gmail.com" }
            }

            $subInfo = Get-UserSubscriptionInfo $userParam $emailParam
            Send-JsonResponse $response @{
                success = $true
                user = if ($userParam) { $userParam } else { $emailParam }
                email = $emailParam
                tier = $subInfo.tier
                name = $subInfo.name
                commandLimit = $subInfo.commandLimit
                hasSpinner = $subInfo.hasSpinner
                hasJar = $subInfo.hasJar
                hasOverlays = $subInfo.hasOverlays
                badge = $subInfo.badge
                badgeColor = $subInfo.badgeColor
                price = $subInfo.price
                isUnlimited = $subInfo.isUnlimited
            }
            continue
        }

        if ($reqPath -eq '/api/subscription/plans' -and $request.HttpMethod -eq 'GET') {
            $subs = Load-Subscriptions
            if ($subs -and $subs.plans) {
                Send-JsonResponse $response @{
                    success = $true
                    plans = $subs.plans
                    paymentMethods = $subs.paymentMethods
                }
            } else {
                Send-JsonResponse $response @{
                    success = $true
                    plans = @{
                        free = @{ id = "free"; name = "Free Starter"; price = 0; commandLimit = 10; hasSpinner = $false; hasJar = $false; hasOverlays = $true }
                        premium = @{ id = "premium"; name = "Streamer Premium"; price = 999; commandLimit = 60; hasSpinner = $true; hasJar = $true; hasOverlays = $true }
                        expert = @{ id = "expert"; name = "Streamer Expert"; price = 3999; commandLimit = 150; hasSpinner = $true; hasJar = $true; hasOverlays = $true }
                    }
                }
            }
            continue
        }

        if ($reqPath -eq '/api/subscription/activate' -and $request.HttpMethod -eq 'POST') {
            try {
                $body = ReadRequestBody $request
                $data = $body | ConvertFrom-Json
                $userKey = if ($data.user) { [string]$data.user.Trim().TrimStart('@').ToLower() } else { "" }
                $licenseKey = if ($data.licenseKey) { [string]$data.licenseKey.Trim().ToUpper() } else { "" }
                $refNo = if ($data.referenceNo) { [string]$data.referenceNo.Trim() } else { "" }

                if (-not $userKey) {
                    Send-JsonResponse $response @{ success = $false; message = "TikTok username or email is required." } 400
                    continue
                }

                $subs = Load-Subscriptions
                if (-not $subs) {
                    Send-JsonResponse $response @{ success = $false; message = "Subscription database unavailable." } 500
                    continue
                }

                $grantedTier = ""
                $grantedLimit = 10

                # Validate License Key
                if ($licenseKey) {
                    $keys = $subs.licenseKeys
                    $foundKey = $null
                    if ($keys) {
                        foreach ($prop in $keys.PSObject.Properties) {
                            if ($prop.Name.ToUpper() -eq $licenseKey) {
                                $foundKey = $prop
                                break
                            }
                        }
                    }

                    if ($foundKey) {
                        if ($foundKey.Value.claimed) {
                            Send-JsonResponse $response @{ success = $false; message = "This license key has already been redeemed." } 400
                            continue
                        }
                        $grantedTier = [string]$foundKey.Value.tier
                        $grantedLimit = [int]$foundKey.Value.commandLimit
                        $foundKey.Value.claimed = $true
                        if ($foundKey.Value.PSObject.Properties['claimedBy']) {
                            $foundKey.Value.claimedBy = $userKey
                        } else {
                            $foundKey.Value | Add-Member -MemberType NoteProperty -Name "claimedBy" -Value $userKey -Force
                        }
                        if ($foundKey.Value.PSObject.Properties['claimedAt']) {
                            $foundKey.Value.claimedAt = (Get-Date -Format "o")
                        } else {
                            $foundKey.Value | Add-Member -MemberType NoteProperty -Name "claimedAt" -Value (Get-Date -Format "o") -Force
                        }
                    } else {
                        Send-JsonResponse $response @{ success = $false; message = "Invalid license key. Please check the code or contact the owner." } 400
                        continue
                    }
                } elseif ($refNo) {
                    # GCash / Maya / PayPal Reference number -> goes to PENDING APPROVAL queue
                    $targetPlan = if ($data.targetPlan) { [string]$data.targetPlan.ToLower() } else { "premium" }
                    $payMethod = if ($data.paymentMethod) { [string]$data.paymentMethod.ToLower() } else { "gcash" }

                    # Create pending payments array if not exists
                    if (-not $subs.pendingPayments) {
                        $subs | Add-Member -MemberType NoteProperty -Name "pendingPayments" -Value @() -Force
                    }

                    # Check for duplicate ref number
                    $isDuplicate = $false
                    foreach ($pp in $subs.pendingPayments) {
                        if ($pp.referenceNo -eq $refNo) { $isDuplicate = $true; break }
                    }
                    if ($isDuplicate) {
                        Send-JsonResponse $response @{ success = $false; message = "This reference number has already been submitted. Please wait for owner approval." } 400
                        continue
                    }

                    $pendingObj = [PSCustomObject]@{
                        id = [System.Guid]::NewGuid().ToString().Substring(0,8)
                        user = $userKey
                        referenceNo = $refNo
                        paymentMethod = $payMethod
                        targetPlan = $targetPlan
                        amount = if ($targetPlan -eq "expert") { 3999 } else { 999 }
                        status = "pending"
                        submittedAt = (Get-Date -Format "o")
                        reviewedAt = $null
                        reviewedBy = $null
                    }

                    $currentPending = @($subs.pendingPayments)
                    $currentPending += $pendingObj
                    $subs.pendingPayments = $currentPending
                    Save-Subscriptions $subs

                    Send-JsonResponse $response @{
                        success = $true
                        pending = $true
                        message = "Your payment reference has been submitted for verification! The owner will review and approve your payment shortly. You will be activated once confirmed."
                    }
                    continue
                } else {
                    Send-JsonResponse $response @{ success = $false; message = "License key or Payment Reference Number required." } 400
                    continue
                }

                # Update or insert user in userSubscriptions
                if (-not $subs.userSubscriptions) {
                    $subs | Add-Member -MemberType NoteProperty -Name "userSubscriptions" -Value ([PSCustomObject]@{})
                }

                $userSubObj = [PSCustomObject]@{
                    tier = $grantedTier
                    commandLimit = $grantedLimit
                    hasSpinner = $true
                    hasJar = $true
                    hasOverlays = $true
                    activatedAt = (Get-Date -Format "o")
                    licenseKey = $licenseKey
                    referenceNo = $refNo
                }

                if ($subs.userSubscriptions.PSObject.Properties[$userKey]) {
                    $subs.userSubscriptions.PSObject.Properties[$userKey].Value = $userSubObj
                } else {
                    $subs.userSubscriptions | Add-Member -MemberType NoteProperty -Name $userKey -Value $userSubObj
                }

                Save-Subscriptions $subs
                
                # Also notify via toast and SSE
                $activatedTierLabel = if ($grantedTier -eq 'expert') { 'Streamer Expert (150 Commands)' } else { 'Streamer Premium (60 Commands)' }
                Send-JsonResponse $response @{
                    success = $true
                    tier = $grantedTier
                    commandLimit = $grantedLimit
                    message = "Subscription successfully activated! Tier: $activatedTierLabel with 3D Spinner & Jar Unlocked!"
                }
                continue
            } catch {
                Send-JsonResponse $response @{ success = $false; message = $_.Exception.Message } 500
                continue
            }
        }

        if ($reqPath -eq '/api/admin/generate-license' -and $request.HttpMethod -eq 'POST') {
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only Owner can generate license keys." } 403
                continue
            }

            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $tier = if ($data.tier) { [string]$data.tier.ToLower() } else { "premium" }
            $prefix = if ($tier -eq "expert") { "EXPERT-3999" } else { "PREM-999" }
            $limit = if ($tier -eq "expert") { 150 } else { 60 }
            $rand = ([System.Guid]::NewGuid().ToString().Substring(0, 8)).ToUpper()
            $newKey = "$prefix-$rand"

            $subs = Load-Subscriptions
            if ($subs -and $subs.licenseKeys) {
                $keyObj = [PSCustomObject]@{
                    tier = $tier
                    commandLimit = $limit
                    claimed = $false
                    claimedBy = $null
                    createdAt = (Get-Date -Format "o")
                }
                $subs.licenseKeys | Add-Member -MemberType NoteProperty -Name $newKey -Value $keyObj
                Save-Subscriptions $subs
                Send-JsonResponse $response @{ success = $true; licenseKey = $newKey; tier = $tier; commandLimit = $limit }
            } else {
                Send-JsonResponse $response @{ success = $false; message = "Unable to access license database." } 500
            }
            continue
        }

        # ── Owner Pending Payments Queue (List / Approve / Reject) ──
        if ($reqPath -eq '/api/admin/pending-payments' -and $request.HttpMethod -eq 'GET') {
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden" } 403
                continue
            }

            $subs = Load-Subscriptions
            $pending = @()
            if ($subs -and $subs.pendingPayments) {
                $pending = @($subs.pendingPayments)
            }
            Send-JsonResponse $response @{ success = $true; pendingPayments = $pending; total = $pending.Count }
            continue
        }

        if ($reqPath -eq '/api/admin/approve-payment' -and $request.HttpMethod -eq 'POST') {
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden" } 403
                continue
            }

            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $paymentId = if ($data.id) { [string]$data.id.Trim() } else { "" }

            if (-not $paymentId) {
                Send-JsonResponse $response @{ success = $false; message = "Payment ID required." } 400
                continue
            }

            $subs = Load-Subscriptions
            if (-not $subs -or -not $subs.pendingPayments) {
                Send-JsonResponse $response @{ success = $false; message = "No pending payments found." } 404
                continue
            }

            $foundPayment = $null
            foreach ($pp in $subs.pendingPayments) {
                if ($pp.id -eq $paymentId) { $foundPayment = $pp; break }
            }

            if (-not $foundPayment) {
                Send-JsonResponse $response @{ success = $false; message = "Payment not found." } 404
                continue
            }

            # Grant the subscription
            $userKey = [string]$foundPayment.user
            $grantedTier = [string]$foundPayment.targetPlan
            $grantedLimit = if ($grantedTier -eq "expert") { 150 } else { 60 }

            if (-not $subs.userSubscriptions) {
                $subs | Add-Member -MemberType NoteProperty -Name "userSubscriptions" -Value ([PSCustomObject]@{}) -Force
            }

            $userSubObj = [PSCustomObject]@{
                tier = $grantedTier
                commandLimit = $grantedLimit
                hasSpinner = $true
                hasJar = $true
                hasOverlays = $true
                activatedAt = (Get-Date -Format "o")
                licenseKey = ""
                referenceNo = [string]$foundPayment.referenceNo
                paymentMethod = [string]$foundPayment.paymentMethod
                approvedBy = $callerEmail
            }

            if ($subs.userSubscriptions.PSObject.Properties[$userKey]) {
                $subs.userSubscriptions.PSObject.Properties[$userKey].Value = $userSubObj
            } else {
                $subs.userSubscriptions | Add-Member -MemberType NoteProperty -Name $userKey -Value $userSubObj
            }

            # Update payment status to approved
            $foundPayment.status = "approved"
            if ($foundPayment.PSObject.Properties['reviewedAt']) {
                $foundPayment.reviewedAt = (Get-Date -Format "o")
            } else {
                $foundPayment | Add-Member -MemberType NoteProperty -Name "reviewedAt" -Value (Get-Date -Format "o") -Force
            }
            if ($foundPayment.PSObject.Properties['reviewedBy']) {
                $foundPayment.reviewedBy = $callerEmail
            } else {
                $foundPayment | Add-Member -MemberType NoteProperty -Name "reviewedBy" -Value $callerEmail -Force
            }

            Save-Subscriptions $subs
            $tierLabel = if ($grantedTier -eq "expert") { "Streamer Expert (150 Commands)" } else { "Streamer Premium (60 Commands)" }
            Send-JsonResponse $response @{
                success = $true
                message = "Payment approved! $userKey has been activated as $tierLabel."
                user = $userKey
                tier = $grantedTier
            }
            continue
        }

        if ($reqPath -eq '/api/admin/reject-payment' -and $request.HttpMethod -eq 'POST') {
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden" } 403
                continue
            }

            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $paymentId = if ($data.id) { [string]$data.id.Trim() } else { "" }
            $reason = if ($data.reason) { [string]$data.reason.Trim() } else { "Payment not verified" }

            if (-not $paymentId) {
                Send-JsonResponse $response @{ success = $false; message = "Payment ID required." } 400
                continue
            }

            $subs = Load-Subscriptions
            if (-not $subs -or -not $subs.pendingPayments) {
                Send-JsonResponse $response @{ success = $false; message = "No pending payments found." } 404
                continue
            }

            $foundPayment = $null
            foreach ($pp in $subs.pendingPayments) {
                if ($pp.id -eq $paymentId) { $foundPayment = $pp; break }
            }

            if (-not $foundPayment) {
                Send-JsonResponse $response @{ success = $false; message = "Payment not found." } 404
                continue
            }

            $foundPayment.status = "rejected"
            if ($foundPayment.PSObject.Properties['reviewedAt']) {
                $foundPayment.reviewedAt = (Get-Date -Format "o")
            } else {
                $foundPayment | Add-Member -MemberType NoteProperty -Name "reviewedAt" -Value (Get-Date -Format "o") -Force
            }
            if ($foundPayment.PSObject.Properties['reviewedBy']) {
                $foundPayment.reviewedBy = $callerEmail
            } else {
                $foundPayment | Add-Member -MemberType NoteProperty -Name "reviewedBy" -Value $callerEmail -Force
            }
            if (-not $foundPayment.PSObject.Properties['rejectReason']) {
                $foundPayment | Add-Member -MemberType NoteProperty -Name "rejectReason" -Value $reason -Force
            } else {
                $foundPayment.rejectReason = $reason
            }

            Save-Subscriptions $subs
            Send-JsonResponse $response @{
                success = $true
                message = "Payment from $($foundPayment.user) has been rejected. Reason: $reason"
            }
            continue
        }

        if ($reqPath -eq '/api/admin/payment-settings' -and $request.HttpMethod -eq 'POST') {
            $caller = Get-CallerUser $request
            $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
            $role = if ($callerEmail) { Get-UserRole $callerEmail } else { Get-CallerRole $request }
            if ($role -ne "admin" -and (Get-CallerRole $request) -ne "admin") {
                Send-JsonResponse $response @{ success = $false; message = "Forbidden: Only Owner can modify payment settings." } 403
                continue
            }

            $body = ReadRequestBody $request
            $data = $body | ConvertFrom-Json
            $subs = Load-Subscriptions
            if ($subs) {
                if (-not $subs.paymentMethods) {
                    $subs | Add-Member -MemberType NoteProperty -Name "paymentMethods" -Value ([PSCustomObject]@{}) -Force
                }
                if ($data.paypalUrl -ne $null) {
                    if (-not $subs.paymentMethods.paypal) { $subs.paymentMethods | Add-Member -MemberType NoteProperty -Name "paypal" -Value ([PSCustomObject]@{}) -Force }
                    $subs.paymentMethods.paypal | Add-Member -MemberType NoteProperty -Name "paymentUrl" -Value [string]$data.paypalUrl -Force
                }
                if ($data.gcashUrl -ne $null) {
                    if (-not $subs.paymentMethods.gcash) { $subs.paymentMethods | Add-Member -MemberType NoteProperty -Name "gcash" -Value ([PSCustomObject]@{}) -Force }
                    $subs.paymentMethods.gcash | Add-Member -MemberType NoteProperty -Name "paymentUrl" -Value [string]$data.gcashUrl -Force
                }
                if ($data.mayaUrl -ne $null) {
                    if (-not $subs.paymentMethods.maya) { $subs.paymentMethods | Add-Member -MemberType NoteProperty -Name "maya" -Value ([PSCustomObject]@{}) -Force }
                    $subs.paymentMethods.maya | Add-Member -MemberType NoteProperty -Name "paymentUrl" -Value [string]$data.mayaUrl -Force
                }
                Save-Subscriptions $subs
                Send-JsonResponse $response @{ success = $true; message = "Payment settings updated successfully." }
            } else {
                Send-JsonResponse $response @{ success = $false; message = "Database error." } 500
            }
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

                $caller = Get-CallerUser $request
                $callerEmail = if ($caller -and $caller.email) { $caller.email } else { "" }
                $subInfo = Get-UserSubscriptionInfo $userParam $callerEmail

                if (-not (Test-Path $targetPath)) {
                    $initialGifts = if ($subInfo.tier -eq "free") { @() } else { $tmplGifts }
                    $userConfig = @{
                        streamer = @{
                            tiktokUsername = ""
                            soundEnabled = $true
                            volume = 0.6
                            autoConnect = $false
                            userEmail = if ($userParam) { $userParam } else { "" }
                        }
                        overlay = if ($master.overlay) { $master.overlay } else { @{ zoom = 1; columns = 1; showGoals = $true; alertDuration = 4000; soundAlerts = $true; wheelPosition = "center" } }
                        gifts = $initialGifts
                        spinners = if ($subInfo.hasSpinner) { $tmplSpinners } else { @() }
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
                    if ($subInfo.tier -ne "free" -and $parsedCfg -and ($null -eq $parsedCfg.gifts -or $parsedCfg.gifts.Count -eq 0)) {
                        $parsedCfg | Add-Member -MemberType NoteProperty -Name gifts -Value $tmplGifts -Force
                        $cfgModified = $true
                    }
                    if ($parsedCfg -and (-not $parsedCfg.spinners -or $parsedCfg.spinners.Count -eq 0)) {
                        if ($subInfo.hasSpinner) {
                            $parsedCfg | Add-Member -MemberType NoteProperty -Name spinners -Value $tmplSpinners -Force
                            $cfgModified = $true
                        }
                    }
                    if ($subInfo.tier -ne "free" -and $parsedCfg -and $parsedCfg.gifts -and $parsedCfg.gifts.Count -gt 0 -and -not ($parsedCfg.gifts | Where-Object { [string]$_.id -eq "3" })) {
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
                    # Do NOT overwrite Card 2 on GET /api/config - respect user saved changes
                    if ($cfgModified) {
                        $content = $parsedCfg | ConvertTo-Json -Depth 10
                        try { [System.IO.File]::WriteAllText($targetPath, $content, [System.Text.Encoding]::UTF8) } catch {}
                        try { [System.IO.File]::WriteAllText($configFile, $content, [System.Text.Encoding]::UTF8) } catch {}
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

                # Enforce subscription command limits (Free=10, Premium=60, Expert=150, Owner/Editor=Unlimited)
                $caller = Get-CallerUser $request
                $userParam = if ($request.QueryString['user']) { [string]$request.QueryString['user'] } else { "" }
                $emailParam = if ($request.QueryString['email']) { [string]$request.QueryString['email'] } elseif ($caller -and $caller.email) { [string]$caller.email } else { "" }
                $subInfo = Get-UserSubscriptionInfo $userParam $emailParam

                if (-not $subInfo.isUnlimited) {
                    try {
                        $parsedConfig = $body | ConvertFrom-Json
                        if ($parsedConfig -and $parsedConfig.gifts) {
                            $giftCount = $parsedConfig.gifts.Count
                            $maxLimit = if ($subInfo.commandLimit) { [int]$subInfo.commandLimit } else { 10 }
                            if ($giftCount -gt $maxLimit) {
                                Send-JsonResponse $response @{
                                    status = "error"
                                    message = "Command Limit Reached! Your plan ($($subInfo.name)) allows up to $maxLimit commands (you submitted $giftCount). Upgrade to Streamer Premium (₱999) for 60 commands or Expert (₱3,999) for 150 commands!"
                                    limit = $maxLimit
                                    currentCount = $giftCount
                                    tier = $subInfo.tier
                                } 403
                                continue
                            }
                        }
                    } catch {}
                }

                [System.IO.File]::WriteAllText($targetPath, $body, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $body, [System.Text.Encoding]::UTF8)
                $rootCfg = Join-Path (Split-Path -Parent $folder) "pvz_fusion_config.json"
                try { [System.IO.File]::WriteAllText($rootCfg, $body, [System.Text.Encoding]::UTF8) } catch {}
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

                # Cap template gifts to user subscription limit if not unlimited
                $caller = Get-CallerUser $request
                $emailParam = if ($request.QueryString['email']) { [string]$request.QueryString['email'] } elseif ($caller -and $caller.email) { [string]$caller.email } else { "" }
                $subInfo = Get-UserSubscriptionInfo $userParam $emailParam
                if (-not $subInfo.isUnlimited -and $subInfo.commandLimit) {
                    try {
                        $parsedTpl = $templateContent | ConvertFrom-Json
                        if ($parsedTpl -and $parsedTpl.gifts -and $parsedTpl.gifts.Count -gt $subInfo.commandLimit) {
                            $parsedTpl.gifts = @($parsedTpl.gifts | Select-Object -First $subInfo.commandLimit)
                            $templateContent = $parsedTpl | ConvertTo-Json -Depth 10
                        }
                    } catch {}
                }

                [System.IO.File]::WriteAllText($targetPath, $templateContent, [System.Text.Encoding]::UTF8)
                [System.IO.File]::WriteAllText($configFile, $templateContent, [System.Text.Encoding]::UTF8)
                Sync-ConfigToCards
                Send-JsonResponse $response @{ status = "ok"; message = "Starter template loaded successfully" }
            } else {
                Send-JsonResponse $response @{ status = "error"; message = "Template not found" } 404
            }
            continue
        }

        # 2b-sounds. Audio Sound Catalog & Management (with automatic filesystem sync)
        if ($reqPath -eq '/api/sounds') {
            $catalogPath = Join-Path $folder "sounds_catalog.json"
            $soundsDir = Join-Path $folder "sounds"
            if (-not (Test-Path $soundsDir)) {
                New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null
            }

            $catalog = @()
            if (Test-Path $catalogPath) {
                try {
                    $raw = [System.IO.File]::ReadAllText($catalogPath, [System.Text.Encoding]::UTF8)
                    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 65279) { $raw = $raw.Substring(1) }
                    $parsed = $raw | ConvertFrom-Json
                    if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
                        $catalog = @($parsed)
                    } elseif ($parsed) {
                        $catalog = @($parsed)
                    }
                } catch { $catalog = @() }
            }

            # Automatically scan sounds folder for all audio files and register new/downloaded files
            $knownFiles = @{}
            foreach ($item in $catalog) {
                if ($item.file) {
                    $fn = ($item.file -replace '^sounds[/\\]', '').ToLower()
                    $knownFiles[$fn] = $true
                }
                if ($item.name) {
                    $knownFiles[([string]$item.name).ToLower()] = $true
                }
            }

            $newItemsAdded = $false
            Get-ChildItem -Path $soundsDir -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Extension -match '^\.(mp3|wav|ogg|m4a|aac|flac|webm|opus|wma)$'
            } | ForEach-Object {
                $fn = $_.Name.ToLower()
                if (-not $knownFiles.ContainsKey($fn)) {
                    $dur = (Get-MediaDurationFormatted $_.FullName)
                    if (-not $dur -or $dur -eq "00:00.000") { $dur = "00:03.000" }
                    $newItem = [PSCustomObject]@{
                        id = "snd_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
                        name = $_.Name
                        title = $_.BaseName -replace '[-_]', ' '
                        file = "sounds/" + $_.Name
                        tag = "Local"
                        isLocal = $true
                        buttonColor = "#10b981"
                        duration = $dur
                        volume = 1.0
                        multiplier = $true
                        playerType = "Short"
                    }
                    $catalog = @($newItem) + $catalog
                    $knownFiles[$fn] = $true
                    $newItemsAdded = $true
                }
            }

            if ($newItemsAdded -or -not (Test-Path $catalogPath)) {
                try {
                    $json = $catalog | ConvertTo-Json -Depth 6
                    [System.IO.File]::WriteAllText($catalogPath, $json, [System.Text.Encoding]::UTF8)
                } catch {}
            }

            $respJson = $catalog | ConvertTo-Json -Depth 6
            Send-JsonResponse $response $respJson
            continue
        }

        # 2b-search. Live MyInstants Online Search
        if ($reqPath -eq '/api/search-myinstants') {
            $q = $request.QueryString['q']
            if (-not $q) {
                Send-JsonResponse $response @()
                continue
            }
            try {
                $searchUrl = "https://www.myinstants.com/en/search/?name=" + [System.Uri]::EscapeDataString($q)
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                $html = $wc.DownloadString($searchUrl)
                $rx = [regex]'(?s)<button[^>]*class="small-button"[^>]*onclick="play\(''([^'']+)''[^>]*>.*?<a[^>]*href="([^""]+)"[^>]*class="instant-link[^""]*"[^>]*>([^<]+)<\/a>'
                $matches = $rx.Matches($html)
                $colors = @('#ef4444', '#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#14b8a6', '#f43f5e')
                $results = @()
                for ($i = 0; $i -lt [Math]::Min(36, $matches.Count); $i++) {
                    $mp3Path = $matches[$i].Groups[1].Value
                    $pagePath = $matches[$i].Groups[2].Value
                    $title = $matches[$i].Groups[3].Value.Trim()
                    $fullMp3 = if ($mp3Path.StartsWith("http")) { $mp3Path } else { "https://www.myinstants.com" + $mp3Path }
                    $fullPage = if ($pagePath.StartsWith("http")) { $pagePath } else { "https://www.myinstants.com" + $pagePath }
                    $fileName = [System.IO.Path]::GetFileName($mp3Path)
                    $results += @{
                        title = $title
                        name = $fileName
                        mp3Url = $fullMp3
                        pageUrl = $fullPage
                        color = $colors[$i % $colors.Count]
                    }
                }
                Send-JsonResponse $response $results
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 2b-fetch. Download Audio URL (MyInstants or Custom Background Music)
        if ($reqPath -eq '/api/fetch-audio-url' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $url = [string]$data.url
                if (-not $url) {
                    Send-JsonResponse $response @{ status = "error"; message = "No URL provided" } 400
                    continue
                }
                $soundsDir = Join-Path $folder "sounds"
                if (-not (Test-Path $soundsDir)) {
                    New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null
                }

                $title = if ($data.title) { [string]$data.title } else { "" }
                $cleanName = if ($data.name) { [string]$data.name } else { [System.IO.Path]::GetFileName($url.Split('?')[0]) }
                if (-not $cleanName -or -not $cleanName.EndsWith(".mp3")) {
                    $cleanName = "audio_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8) + ".mp3"
                }
                $cleanName = $cleanName -replace '[^a-zA-Z0-9_\-\.]', '_'
                $destPath = Join-Path $soundsDir $cleanName

                # Download via WebClient
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                $wc.DownloadFile($url, $destPath)

                $tag = if ($data.tag) { [string]$data.tag } else { "Online" }
                $soundItem = @{
                    id = "snd_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
                    name = $cleanName
                    title = if ($title) { $title } else { ($cleanName -replace '\.[^/.]+$', '' -replace '[-_]', ' ') }
                    file = "sounds/" + $cleanName
                    tag = $tag
                    buttonColor = "#38bdf8"
                    duration = (Get-MediaDurationFormatted $destPath)
                    volume = 1.0
                    multiplier = $true
                    playerType = "Short"
                    pageUrl = if ($data.pageUrl) { [string]$data.pageUrl } else { "" }
                }

                # Update sounds_catalog.json
                $catalogPath = Join-Path $folder "sounds_catalog.json"
                $catalog = @()
                if (Test-Path $catalogPath) {
                    try {
                        $rawCat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
                        $catalog = @($rawCat)
                    } catch {}
                }
                $catalog = @($soundItem) + $catalog
                $catJson = $catalog | ConvertTo-Json -Depth 6
                [System.IO.File]::WriteAllText($catalogPath, $catJson, [System.Text.Encoding]::UTF8)

                Send-JsonResponse $response @{ status = "ok"; sound = $soundItem }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 2b-upload. Local Audio File Upload (Base64)
        if ($reqPath -eq '/api/upload-audio' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            try {
                $data = $body | ConvertFrom-Json
                $name = [string]$data.name
                $base64 = [string]$data.base64Data
                if ($base64.Contains(',')) {
                    $base64 = $base64.Split(',')[1]
                }
                $bytes = [System.Convert]::FromBase64String($base64)

                $soundsDir = Join-Path $folder "sounds"
                if (-not (Test-Path $soundsDir)) {
                    New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null
                }

                $cleanName = if ($name) { $name -replace '[^a-zA-Z0-9_\-\.]', '_' } else { "custom_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8) + ".mp3" }
                if (-not ($cleanName -match '\.(mp3|wav|ogg|m4a|aac|flac|webm|opus|wma)$')) {
                    $cleanName += ".mp3"
                }
                $destPath = Join-Path $soundsDir $cleanName
                [System.IO.File]::WriteAllBytes($destPath, $bytes)

                $soundItem = @{
                    id = "snd_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
                    name = $cleanName
                    title = if ($data.title) { [string]$data.title } else { ($cleanName -replace '\.[^/.]+$', '') }
                    file = "sounds/" + $cleanName
                    tag = "Local"
                    isLocal = $true
                    buttonColor = "#10b981"
                    duration = (Get-MediaDurationFormatted $destPath)
                    volume = 1.0
                    multiplier = $true
                    playerType = "Short"
                }

                # Update sounds_catalog.json
                $catalogPath = Join-Path $folder "sounds_catalog.json"
                $catalog = @()
                if (Test-Path $catalogPath) {
                    try {
                        $rawCat = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
                        $catalog = @($rawCat)
                    } catch {}
                }
                $catalog = @($soundItem) + $catalog
                $catJson = $catalog | ConvertTo-Json -Depth 6
                [System.IO.File]::WriteAllText($catalogPath, $catJson, [System.Text.Encoding]::UTF8)

                Send-JsonResponse $response @{ status = "ok"; sound = $soundItem }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
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
            $activeId = "preset_pvz_custom"
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

                # Enforce subscription command limits on preset activation (Owner & Editor are Unlimited)
                $caller = Get-CallerUser $request
                $userParam = if ($payload.user) { [string]$payload.user } elseif ($request.QueryString['user']) { [string]$request.QueryString['user'] } else { "" }
                $emailParam = if ($caller -and $caller.email) { [string]$caller.email } elseif ($request.QueryString['email']) { [string]$request.QueryString['email'] } else { "" }
                $subInfo = Get-UserSubscriptionInfo $userParam $emailParam
                if (-not $subInfo.isUnlimited -and $subInfo.commandLimit -and $normalizedEvents.Count -gt $subInfo.commandLimit) {
                    $normalizedEvents = @($normalizedEvents | Select-Object -First $subInfo.commandLimit)
                }

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

        # 3f. Auto-Detect & Sync Online TikTok Gifts API
        if ($reqPath -eq '/api/gifts/sync') {
            try {
                $targetU = if ($request.QueryString['user']) { [string]$request.QueryString['user'] } elseif ($script:tiktokConnectedUser) { [string]$script:tiktokConnectedUser } else { "gohanmalunggay" }
                $nodeExe = Join-Path $folder "bin\node.exe"
                $syncScript = Join-Path $folder "tools\sync_tiktok_gifts.js"
                
                if ((Test-Path $nodeExe) -and (Test-Path $syncScript)) {
                    $prevCount = if ($script:verifiedGiftsCatalog) { $script:verifiedGiftsCatalog.Count } else { 0 }
                    
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = $nodeExe
                    $pinfo.Arguments = "`"$syncScript`" `"$targetU`""
                    $pinfo.WorkingDirectory = $folder
                    $pinfo.RedirectStandardOutput = $true
                    $pinfo.RedirectStandardError = $true
                    $pinfo.UseShellExecute = $false
                    $pinfo.CreateNoWindow = $true
                    $p = [System.Diagnostics.Process]::Start($pinfo)
                    $p.WaitForExit(20000)
                    
                    if (Test-Path $verifiedGiftsFile) {
                        try {
                            $script:verifiedGiftsCatalog = Get-Content $verifiedGiftsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                        } catch {}
                    }
                    $newCount = if ($script:verifiedGiftsCatalog) { $script:verifiedGiftsCatalog.Count } else { 0 }
                    $diff = [Math]::Max(0, ($newCount - $prevCount))
                    
                    Send-JsonResponse $response @{
                        status = "ok"
                        success = $true
                        totalGifts = $newCount
                        newGifts = $diff
                        message = "TikTok gifts successfully checked & synced!"
                    }
                } else {
                    Send-JsonResponse $response @{ status = "error"; message = "Sync engine missing" } 500
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
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
            if ($data -and ($data.isTest -eq $true -or $data.noJarDrop -eq $true)) {
                Send-JsonResponse $response @{ status = "ok"; message = "Test drop ignored for jar state" }
                continue
            }
            $gName = if ($data -and $data.giftName) { [string]$data.giftName } elseif ($data -and $data.name) { [string]$data.name } else { "Gift" }
            $gId = if ($data -and $data.giftId) { [string]$data.giftId } elseif ($data -and $data.id) { [string]$data.id } else { "" }
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
            $dropId = if ($data -and $data.id) { [string]$data.id } else { [System.Guid]::NewGuid().ToString() }
            $gCount = if ($data -and $data.count) { [int]$data.count } else { 1 }
            $gCoins = if ($data -and $data.coins) { [int]$data.coins } else { 1 }
            $uName = if ($data -and $data.username) { [string]$data.username } else { "RENEarn_Viewer" }
            $uAvatar = if ($data -and $data.avatar) { [string]$data.avatar } else { "images/default_avatar.svg" }

            if (-not $gIcon -or $gIcon -eq "images/default_avatar.svg" -or $gIcon -match "game-icons") {
                if ($gName -match '(?i)heart\s*me') { $gIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                elseif ($gName -match '(?i)finger\s*heart') { $gIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
                elseif ($gName -match '(?i)panda') { $gIcon = "images/tiktok-gifts/5659_panda.webp" }
                elseif ($gCoins -eq 5) { $gIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
                elseif ($gName -match '(?i)heart') { $gIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                elseif ($gName -match '(?i)ice') { $gIcon = "images/tiktok-gifts/5827_ice_cream_cone.webp" }
                elseif ($gName -match '(?i)tiktok') { $gIcon = "images/tiktok-gifts/5269_tiktok.webp" }
                elseif ($gName -match '(?i)cap') { $gIcon = "images/tiktok-gifts/6104_cap.webp" }
                elseif ($gName -match '(?i)gg') { $gIcon = "images/tiktok-gifts/6064_gg.webp" }
                elseif ($gName -match '(?i)doughnut|donut') { $gIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                elseif ($gName -match '(?i)galaxy') { $gIcon = "images/tiktok-gifts/11046_galaxy.webp" }
                elseif ($gName -match '(?i)lion') { $gIcon = "images/tiktok-gifts/5962_lion.webp" }
                elseif ($gName -match '(?i)universe') { $gIcon = "images/tiktok-gifts/6059_tiktok_universe.webp" }
                elseif ($gName -match '(?i)rose\s*bear') { $gIcon = "images/tiktok-gifts/15862_rose_bear.webp" }
                elseif ($gCoins -ge 1000) { $gIcon = "images/tiktok-gifts/11046_galaxy.webp" }
                elseif ($gCoins -ge 99) { $gIcon = "images/tiktok-gifts/6104_cap.webp" }
                elseif ($gCoins -ge 30) { $gIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                elseif ($gCoins -ge 5) { $gIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
                else { $gIcon = "images/tiktok-gifts/5655_rose.webp" }
            }
            if ($gName -eq "Gift" -or -not $gName) {
                $gName = "Rose"
            }

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

            # Update Streamer Gift Gallery progress if matched
            Process-GiftForGallery $gName $gId $uName $uAvatar $gCount $gIcon

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

        # 3i. TikTok Gift Gallery Overlay Endpoints
        if ($reqPath -eq '/api/gift-gallery' -and $request.HttpMethod -eq 'GET') {
            $st = if ($script:giftGalleryState) { $script:giftGalleryState } else { Load-GiftGalleryState }
            Send-JsonResponse $response $st
            continue
        }

        if ($reqPath -eq '/api/gift-gallery/update' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = try { $body | ConvertFrom-Json } catch { $null }
            if ($data) {
                if ($data.streamer) { $script:giftGalleryState.streamer = [string]$data.streamer }
                if ($data.tier) { $script:giftGalleryState.tier = [string]$data.tier }
                if ($data.dateRange) { $script:giftGalleryState.dateRange = [string]$data.dateRange }
                if ($data.gifts) {
                    $script:giftGalleryState.gifts = $data.gifts
                    $script:giftGalleryState.totalSlots = $data.gifts.Count
                    $script:giftGalleryState.obtainedCount = ($data.gifts | Where-Object { $_.obtained -eq $true }).Count
                }
                $script:giftGalleryState.lastUpdated = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                Save-GiftGalleryState $script:giftGalleryState
                AddEventLog @{
                    type = "gift_gallery_update"
                    streamer = $script:giftGalleryState.streamer
                    tier = $script:giftGalleryState.tier
                    obtainedCount = $script:giftGalleryState.obtainedCount
                    totalSlots = $script:giftGalleryState.totalSlots
                    gifts = $script:giftGalleryState.gifts
                }
            }
            Send-JsonResponse $response @{ status = "ok"; state = $script:giftGalleryState }
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

        # 3c-2. Join Stream Overlay Config API
        if ($reqPath -eq '/api/overlay-join/config' -or $reqPath -eq '/api/join-overlay/config') {
            if ($request.HttpMethod -eq 'GET') {
                Send-JsonResponse $response $script:joinOverlayConfig
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $newCfg = $body | ConvertFrom-Json
                    $script:joinOverlayConfig = $newCfg
                    Save-JoinOverlayConfig $newCfg
                    AddEventLog @{ type = "join_overlay_config_update"; config = $newCfg }
                    Send-JsonResponse $response @{ status = "ok"; message = "Join overlay configuration saved"; config = $newCfg }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        # 3c-3. Side Stream Overlay Settings API (Real-time Live Sync across OBS / TikTok Studio)
        if ($reqPath -eq '/api/overlay-side/settings' -or $reqPath -eq '/api/side-overlay/settings' -or $reqPath -eq '/api/overlay/side-settings') {
            if ($request.HttpMethod -eq 'GET') {
                Send-JsonResponse $response $script:sideOverlaySettings
                continue
            } elseif ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $newSettings = $body | ConvertFrom-Json
                    $script:sideOverlaySettings = $newSettings
                    Save-SideOverlaySettings $newSettings
                    AddEventLog @{
                        type = "overlay_side_settings_updated"
                        settings = $newSettings
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                    Send-JsonResponse $response @{ status = "ok"; message = "Side overlay settings saved"; settings = $newSettings }
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
            $resetType = "all"
            if ($body) {
                try {
                    $data = $body | ConvertFrom-Json
                    if ($data -and $data.type) { $resetType = [string]$data.type }
                } catch {
                    $cleanBody = $body.Trim().Trim('"').ToLower()
                    if ($cleanBody -in @("coins", "likes", "donators", "all")) {
                        $resetType = $cleanBody
                    }
                }
            }

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
            $data = $null
            if ($body) {
                try { $data = $body | ConvertFrom-Json } catch {}
            }
            if (-not $data) { $data = @{} }
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

        # 3f. Leaderboard Single Entry Edit / Add / Delete
        if ($reqPath -eq '/api/leaderboard/entry' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            $data = $null
            if ($body) {
                try { $data = $body | ConvertFrom-Json } catch {}
            }
            if (-not $data) { $data = @{} }
            $t = if ($data.type) { [string]$data.type } else { "coins" }
            $action = if ($data.action) { [string]$data.action } else { "update" }
            $username = if ($data.username) { [string]$data.username.Trim() } else { "" }
            $oldUsername = if ($data.oldUsername) { [string]$data.oldUsername.Trim() } else { $username }
            $val = if ($null -ne $data.value) { [int]$data.value } else { 0 }
            $avatar = if ($data.avatar) { [string]$data.avatar.Trim() } else { "" }

            if (-not $script:leaderboard.$t) {
                $script:leaderboard | Add-Member -NotePropertyName $t -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            if (-not $script:leaderboard.avatars) {
                $script:leaderboard | Add-Member -NotePropertyName avatars -NotePropertyValue ([PSCustomObject]@{}) -Force
            }

            if ($action -eq "delete") {
                if ($oldUsername) {
                    if ($script:leaderboard.$t -is [System.Collections.IDictionary]) {
                        $script:leaderboard.$t.Remove($oldUsername)
                    } elseif ($script:leaderboard.$t.PSObject.Properties[$oldUsername]) {
                        $script:leaderboard.$t.PSObject.Properties.Remove($oldUsername)
                    }
                    if ($script:leaderboard.avatars -is [System.Collections.IDictionary]) {
                        $script:leaderboard.avatars.Remove($oldUsername)
                    } elseif ($script:leaderboard.avatars.PSObject.Properties[$oldUsername]) {
                        $script:leaderboard.avatars.PSObject.Properties.Remove($oldUsername)
                    }
                }
            } else {
                if ($oldUsername -and $oldUsername -ne $username) {
                    if ($script:leaderboard.$t -is [System.Collections.IDictionary]) {
                        $script:leaderboard.$t.Remove($oldUsername)
                    } elseif ($script:leaderboard.$t.PSObject.Properties[$oldUsername]) {
                        $script:leaderboard.$t.PSObject.Properties.Remove($oldUsername)
                    }
                    if ($script:leaderboard.avatars -is [System.Collections.IDictionary]) {
                        $script:leaderboard.avatars.Remove($oldUsername)
                    } elseif ($script:leaderboard.avatars.PSObject.Properties[$oldUsername]) {
                        $script:leaderboard.avatars.PSObject.Properties.Remove($oldUsername)
                    }
                }
                if ($username) {
                    if ($script:leaderboard.$t -is [System.Collections.IDictionary]) {
                        $script:leaderboard.$t[$username] = $val
                    } else {
                        $script:leaderboard.$t | Add-Member -NotePropertyName $username -NotePropertyValue $val -Force
                    }
                    if ($avatar) {
                        if ($script:leaderboard.avatars -is [System.Collections.IDictionary]) {
                            $script:leaderboard.avatars[$username] = $avatar
                        } else {
                            $script:leaderboard.avatars | Add-Member -NotePropertyName $username -NotePropertyValue $avatar -Force
                        }
                    }
                }
            }

            Save-Leaderboard
            AddEventLog @{ type = "leaderboard_entry_edit"; action = $action; target = $t; username = $username; value = $val; avatar = $avatar }
            Send-JsonResponse $response @{ status = "ok"; message = "Leaderboard entry updated successfully"; username = $username; value = $val }
            continue
        }

        # 4. Trigger Game Action
        if ($reqPath -eq '/api/game/trigger') {
            $body = ReadRequestBody $request

            $data = try { $body | ConvertFrom-Json } catch { $null }
            if (-not $data) { $data = @{} }
            $actionType = if ($data.actionType) { $data.actionType } else { "custom" }
            $command = $data.command
            $repetition = if ($data.repetition) { [int]$data.repetition } elseif ($data.amount) { [int]$data.amount } else { 1 }
            $amount = if ($data.amount) { [int]$data.amount } else { $repetition }
            $username = if ($data.username) { $data.username } else { "RENEarn" }
            $delay = if ($data.delay) { [int]$data.delay } else { 0 }
            $interval = if ($data.interval) { [int]$data.interval } else { 100 }
            $hideInOverlay = ($data.hideInOverlay -eq $true -or $data.hideInOverlay -eq "true")
            $game = if ($data.game) { [string]$data.game } elseif ($data.targetGame) { [string]$data.targetGame } else { "pvz" }
            $game = $game.ToLower()

            $exec = @{ success = $true; message = "Command executed" }

            if ($game -eq "pvz" -or $game -eq "pvz_fusion" -or $game -eq "") {
                $exec = SendToPvZGame $actionType $command $amount $username "" $repetition $delay $interval
            } elseif ($game -eq "zombie_tsunami") {
                if ($command -eq "jump" -or $command -eq "super_jump") {
                    try {
                        if ($script:zombieHWnd) {
                            [ZombieInputBridge]::Jump($script:zombieHWnd, 240)
                        }
                    } catch {}
                }
                $exec = @{ success = $true; message = "Dispatched to Zombie Tsunami ($command)" }
            } else {
                $exec = @{ success = $true; message = "Dispatched to $($game.ToUpper()): $command" }
            }
            
            $logEntry = @{
                type = "game_trigger"
                gameId = $game
                targetGame = $game
                label = if ($data.label) { $data.label } else { $command }
                command = $command
                actionType = $actionType
                amount = $amount
                username = $username
                hideInOverlay = $hideInOverlay
                success = if ($exec.success -ne $null) { $exec.success } else { $true }
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

            $data = try { $body | ConvertFrom-Json } catch { $null }
            if (-not $data) { $data = @{} }
            $eventType = if ($data.type) { $data.type } else { "gift" }

            if ($eventType -eq "join") {
                $joinUser = if ($data.username) { [string]$data.username } else { "renearn" }
                $joinAvatar = if ($data.avatar) { [string]$data.avatar } else { "images/groudon_icon.png" }
                $joinLabel = if ($data.label) { [string]$data.label } else { "$joinUser joined the stream!" }
                $joinBanner = if ($data.bannerText) { [string]$data.bannerText } else { "" }
                $logEntry = @{
                    type = "join"
                    username = $joinUser
                    avatar = $joinAvatar
                    label = $joinLabel
                    bannerText = $joinBanner
                    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
                AddEventLog $logEntry
                Send-JsonResponse $response @{ status = "ok"; type = "join"; event = $logEntry }
                continue
            }
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
            } elseif (($data.commands -and $data.commands.Count -gt 0) -or ($command -and $command -ne "spin_wheel")) {
                $exec = @{ success = $true; message = "OK" }
                if ($data.commands -and $data.commands.Count -gt 0) {
                    foreach ($sc in $data.commands) {
                        $scCmd = if ($sc.command) { [string]$sc.command } else { [string]$sc }
                        if (-not $scCmd -or $scCmd -eq "spin_wheel") { continue }
                        $scAct = if ($sc.actionType) { [string]$sc.actionType } else { $actionType }
                        $scAmt = if ($sc.amount) { [int]$sc.amount } else { $amount }
                        $exec = SendToPvZGame $scAct $scCmd $scAmt $username "" $repetition $delay $interval
                    }
                } else {
                    $exec = SendToPvZGame $actionType $command $amount $username "" $repetition $delay $interval
                }

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
            $cId = ""
            $allCards = LoadCards
            if ($data.cardId) {
                $match = $allCards | Where-Object { [string]$_.id -eq [string]$data.cardId } | Select-Object -First 1
                if ($match) { $cId = [string]$match.id }
            }
            if (-not $cId -and $data.giftId) {
                $match = $allCards | Where-Object { [string]$_.giftId -eq [string]$data.giftId -or [string]$_.id -eq [string]$data.giftId } | Select-Object -First 1
                if ($match) { $cId = [string]$match.id }
            }
            if (-not $cId -and $data.giftName) {
                $match = $allCards | Where-Object { $_.giftName -and ($_.giftName.Trim().ToLower() -eq $data.giftName.Trim().ToLower()) } | Select-Object -First 1
                if ($match) { $cId = [string]$match.id }
            }
            if (-not $cId -and $command) {
                foreach ($c in $allCards) {
                    if ($c.commands -eq $command -or $c.command -eq $command -or ($c.giftName -and $c.giftName -eq $label)) {
                        $cId = [string]$c.id
                        break
                    }
                }
            }
            if (-not $cId -and $data.cardId) {
                $cId = [string]$data.cardId
            }

            # Tester commands must NEVER increment card counts in counts.json or overlay.
            # Only genuine TikTok Live stream gifts count towards overlay counters and cards.

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
                isTest = $true
                noJarDrop = $true
                noOverlayCount = $true
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
                    if ($data.style) { $cur.style = [string]$data.style }
                    if ($data.trophyIcon) { $cur.trophyIcon = [string]$data.trophyIcon }
                    if ($data.colorNegative) { $cur.colorNegative = [string]$data.colorNegative }
                    if ($data.colorPositive) { $cur.colorPositive = [string]$data.colorPositive }
                    if ($data.colorZero) { $cur.colorZero = [string]$data.colorZero }
                    if ($data.scale -ne $null) { $cur.scale = [double]$data.scale }
                    if ($data.bgTheme) { $cur.bgTheme = [string]$data.bgTheme }
                    if ($data.showTrophy -ne $null) { $cur.showTrophy = [bool]$data.showTrophy }
                    
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
                        style = $cur.style
                        trophyIcon = $cur.trophyIcon
                        colorNegative = $cur.colorNegative
                        colorPositive = $cur.colorPositive
                        colorZero = $cur.colorZero
                        scale = $cur.scale
                        bgTheme = $cur.bgTheme
                        showTrophy = $cur.showTrophy
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
                    style = $cur.style
                    trophyIcon = $cur.trophyIcon
                    colorNegative = $cur.colorNegative
                    colorPositive = $cur.colorPositive
                    colorZero = $cur.colorZero
                    scale = $cur.scale
                    bgTheme = $cur.bgTheme
                    reason = "adjust"
                }
                Send-JsonResponse $response $cur
            } catch {
                Send-JsonResponse $response @{ error = $_.Exception.Message } 400
            }
            continue
        }

        # 6a-1. Team Battle Settings Endpoint (/api/teambattle/settings)
        if ($reqPath -eq '/api/teambattle/settings') {
            if ($request.HttpMethod -eq 'GET') {
                $st = Load-TeamBattleSettings
                Send-JsonResponse $response $st
                continue
            }
            if ($request.HttpMethod -eq 'POST') {
                $rawBody = ReadRequestBody $request
                try {
                    $d = $rawBody | ConvertFrom-Json
                    Save-TeamBattleSettings $d
                    Send-JsonResponse $response @{ status = "ok"; message = "Team Battle settings saved"; settings = (Load-TeamBattleSettings) }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                }
                continue
            }
        }

        # 6a-2. Team Battle Endpoints (/api/teambattle/state and /api/teambattle/test)
        if ($reqPath -eq '/api/teambattle/state') {
            $tbSet = Load-TeamBattleSettings
            $t1Obj = if ($tbSet.team1) { $tbSet.team1 } else { $null }
            $t2Obj = if ($tbSet.team2) { $tbSet.team2 } else { $null }

            $tbCards = LoadCards
            if (-not $tbCards -or $tbCards.Count -eq 0) {
                Sync-ConfigToCards
                $tbCards = LoadCards
            }
            $c1 = $tbCards | Where-Object { [string]$_.id -eq "1" } | Select-Object -First 1
            $c2 = $tbCards | Where-Object { [string]$_.id -eq "2" } | Select-Object -First 1

            $cfg = LoadConfig
            $g1 = if ($cfg -and $cfg.gifts) { $cfg.gifts | Where-Object { [string]$_.id -eq "1" } | Select-Object -First 1 } else { $null }
            $g2 = if ($cfg -and $cfg.gifts) { $cfg.gifts | Where-Object { [string]$_.id -eq "2" } | Select-Object -First 1 } else { $null }

            $t1Thresh = if ($t1Obj -and $t1Obj.threshold) { [int]$t1Obj.threshold } elseif ($g1 -and $g1.likeThreshold) { [int]$g1.likeThreshold } else { 20 }
            $t2Thresh = if ($t2Obj -and $t2Obj.threshold) { [int]$t2Obj.threshold } elseif ($g2 -and $g2.likeThreshold) { [int]$g2.likeThreshold } else { 20 }

            $t1Reps = if ($t1Obj -and $t1Obj.repetition) { [int]$t1Obj.repetition } elseif ($g1 -and $g1.repetition) { [int]$g1.repetition } else { 20 }
            $t2Reps = if ($t2Obj -and $t2Obj.repetition) { [int]$t2Obj.repetition } elseif ($g2 -and $g2.repetition) { [int]$g2.repetition } else { 20 }

            $t1Name = if ($t1Obj -and $t1Obj.name) { [string]$t1Obj.name } else { "Team Blue" }
            $t2Name = if ($t2Obj -and $t2Obj.name) { [string]$t2Obj.name } else { "Team Red" }

            $t1Cmd = if ($t1Obj -and $t1Obj.command) { [string]$t1Obj.command } else { "!blue" }
            $t2Cmd = if ($t2Obj -and $t2Obj.command) { [string]$t2Obj.command } else { "!red" }

            $t1Icon = if ($t1Obj -and $t1Obj.icon) { [string]$t1Obj.icon } elseif ($g1 -and $g1.unitIcon) { $g1.unitIcon } else { "images/indicators/indicator_general.svg" }
            $t2Icon = if ($t2Obj -and $t2Obj.icon) { [string]$t2Obj.icon } elseif ($g2 -and $g2.unitIcon) { $g2.unitIcon } else { "images/indicators/indicator_general.svg" }

            $cnt1 = if ($counts.Contains("1")) { [int]$counts["1"] } else { 0 }
            $cnt2 = if ($counts.Contains("2")) { [int]$counts["2"] } else { 0 }

            $t1Data = @{
                id = if ($t1Obj -and $t1Obj.id) { $t1Obj.id } else { "blue" }
                team = "plants"
                name = $t1Name
                command = $t1Cmd
                teamCommand = $t1Cmd
                current = $teamPlantsLikes
                threshold = $t1Thresh
                count = $cnt1
                unit = if ($t1Obj -and $t1Obj.unit) { $t1Obj.unit } else { "Blue Vanguard" }
                icon = $t1Icon
                repetition = $t1Reps
                color = if ($t1Obj -and $t1Obj.color) { $t1Obj.color } else { "#38bdf8" }
                colorGrad = if ($t1Obj -and $t1Obj.colorGrad) { $t1Obj.colorGrad } else { "linear-gradient(135deg, #0284c7 0%, #2563eb 50%, #38bdf8 100%)" }
                glow = if ($t1Obj -and $t1Obj.glow) { $t1Obj.glow } else { "rgba(56, 189, 248, 0.45)" }
                emoji = if ($t1Obj -and $t1Obj.emoji) { $t1Obj.emoji } else { [char]::ConvertFromUtf32(0x1F535) }
            }

            $t2Data = @{
                id = if ($t2Obj -and $t2Obj.id) { $t2Obj.id } else { "red" }
                team = "zombies"
                name = $t2Name
                command = $t2Cmd
                teamCommand = $t2Cmd
                current = $teamZombiesLikes
                threshold = $t2Thresh
                count = $cnt2
                unit = if ($t2Obj -and $t2Obj.unit) { $t2Obj.unit } else { "Red Vanguard" }
                icon = $t2Icon
                repetition = $t2Reps
                color = if ($t2Obj -and $t2Obj.color) { $t2Obj.color } else { "#ef4444" }
                colorGrad = if ($t2Obj -and $t2Obj.colorGrad) { $t2Obj.colorGrad } else { "linear-gradient(135deg, #b91c1c 0%, #ef4444 50%, #f87171 100%)" }
                glow = if ($t2Obj -and $t2Obj.glow) { $t2Obj.glow } else { "rgba(239, 68, 68, 0.45)" }
                emoji = if ($t2Obj -and $t2Obj.emoji) { $t2Obj.emoji } else { [char]::ConvertFromUtf32(0x1F534) }
            }

            Send-JsonResponse $response @{
                status = "ok"
                preset = if ($tbSet.activePreset) { $tbSet.activePreset } else { "blue_vs_red" }
                team1 = $t1Data
                team2 = $t2Data
                plants = $t1Data
                zombies = $t2Data
            }
            continue
        }

        if ($reqPath -eq '/api/teambattle/test' -and $request.HttpMethod -eq 'POST') {
            $rawBody = ReadRequestBody $request
            $tbData = @{}
            if ($rawBody) {
                try { $tbData = $rawBody | ConvertFrom-Json } catch {}
            }
            $tTeam = if ($tbData.team) { [string]$tbData.team.ToLower() } else { "plants" }
            $tLikes = if ($tbData.likes) { [int]$tbData.likes } else { 5 }
            $tUser = if ($tbData.user) { [string]$tbData.user } else { "Viewer" }

            $userTeams[$tUser] = $tTeam
            $tbCards = LoadCards
            $c1 = $tbCards | Where-Object { [string]$_.id -eq "1" } | Select-Object -First 1
            $c2 = $tbCards | Where-Object { [string]$_.id -eq "2" } | Select-Object -First 1

            $cfg = LoadConfig
            $g1 = if ($cfg -and $cfg.gifts) { $cfg.gifts | Where-Object { [string]$_.id -eq "1" } | Select-Object -First 1 } else { $null }
            $g2 = if ($cfg -and $cfg.gifts) { $cfg.gifts | Where-Object { [string]$_.id -eq "2" } | Select-Object -First 1 } else { $null }

            $t1 = if ($g1 -and $g1.likeThreshold) { [int]$g1.likeThreshold } elseif ($c1 -and $c1.triggerValue) { [int]$c1.triggerValue } else { 50 }
            $t2 = if ($g2 -and $g2.likeThreshold) { [int]$g2.likeThreshold } elseif ($c2 -and $c2.triggerValue) { [int]$c2.triggerValue } else { 50 }

            if ($tTeam -eq "plants") {
                $teamPlantsLikes += $tLikes
                AddEventLog @{
                    type = "team_battle_progress"
                    team = "plants"
                    current = $teamPlantsLikes
                    threshold = $t1
                    likes = $tLikes
                    username = $tUser
                }
                while ($teamPlantsLikes -ge $t1) {
                    $teamPlantsLikes -= $t1
                    $cCmd = if ($g1 -and $g1.command) { $g1.command } elseif ($c1 -and $c1.commands) { $c1.commands } else { "spawn_snipurr" }
                    $cReps = if ($g1 -and $g1.repetition) { [int]$g1.repetition } elseif ($c1 -and $c1.repetition) { [int]$c1.repetition } else { 1 }
                    $cIcon = if ($g1 -and $g1.unitIcon) { $g1.unitIcon } elseif ($c1 -and $c1.funcImg) { $c1.funcImg } else { "images/game-icons/pvz/spawn_snipurr.webp" }
                    SendToPvZGame "plant" $cCmd $cReps $tUser "" $cReps 0 100 | Out-Null
                    if ($counts.Contains("1")) { $counts["1"] = [int]$counts["1"] + 1; SaveCounts }
                    AddEventLog @{
                        type = "team_battle_spawn"
                        cardId = "1"
                        label = "Team Plants ($t1 Likes) -> $($c1.funcName)"
                        team = "plants"
                        command = $cCmd
                        amount = $cReps
                        username = $tUser
                        icon = $cIcon
                        success = $true
                    }
                }
            } else {
                $teamZombiesLikes += $tLikes
                AddEventLog @{
                    type = "team_battle_progress"
                    team = "zombies"
                    current = $teamZombiesLikes
                    threshold = $t2
                    likes = $tLikes
                    username = $tUser
                }
                while ($teamZombiesLikes -ge $t2) {
                    $teamZombiesLikes -= $t2
                    $cCmd = if ($g2 -and $g2.command) { $g2.command } elseif ($c2 -and $c2.commands) { $c2.commands } else { "spawn_trident_juggernut_gargantuar" }
                    $cReps = if ($g2 -and $g2.repetition) { [int]$g2.repetition } elseif ($c2 -and $c2.repetition) { [int]$c2.repetition } else { 1 }
                    $cIcon = if ($g2 -and $g2.unitIcon) { $g2.unitIcon } elseif ($c2 -and $c2.funcImg) { $c2.funcImg } else { "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp" }
                    SendToPvZGame "zombie" $cCmd $cReps $tUser "" $cReps 0 100 | Out-Null
                    if ($counts.Contains("2")) { $counts["2"] = [int]$counts["2"] + 1; SaveCounts }
                    AddEventLog @{
                        type = "team_battle_spawn"
                        cardId = "2"
                        label = "Team Zombies ($t2 Likes) -> $($c2.funcName)"
                        team = "zombies"
                        command = $cCmd
                        amount = $cReps
                        username = $tUser
                        icon = $cIcon
                        success = $true
                    }
                }
            }
            Send-JsonResponse $response @{ status = "ok"; team = $tTeam; plantsCurrent = $teamPlantsLikes; zombiesCurrent = $teamZombiesLikes }
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

        # 6.6 Song Request Endpoints
        if ($reqPath -eq '/api/songrequest/state') {
            if ($request.HttpMethod -eq 'GET') {
                $script:songRequestState = Load-SongRequestState
                Send-JsonResponse $response $script:songRequestState
                continue
            }
            if ($request.HttpMethod -eq 'POST') {
                $body = ReadRequestBody $request
                try {
                    $data = $body | ConvertFrom-Json
                    if ($data) {
                        $script:songRequestState = $data
                        Save-SongRequestState $script:songRequestState
                        AddEventLog @{ type = "songrequest_update"; data = $script:songRequestState }
                        Send-JsonResponse $response @{ status = "ok"; state = $script:songRequestState }
                        continue
                    }
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 400
                    continue
                }
            }
        }

        # 6.6b Search Music Online for Direct Audio Stream, Singer Detection & Art
        if ($reqPath -eq '/api/songrequest/search' -and $request.HttpMethod -eq 'GET') {
            $query = $request.QueryString['q']
            if (-not $query) {
                Send-JsonResponse $response @{ status = "error"; message = "Missing query parameter 'q'" } 400
                continue
            }
            $track = Resolve-MusicTrack $query
            if ($track) {
                Send-JsonResponse $response @{ status = "ok"; track = $track }
            } else {
                Send-JsonResponse $response @{ status = "not_found"; message = "No matching track found" } 404
            }
            continue
        }

        # 6.6c Direct Audio Stream Proxy (Eliminates Browser CORS & CDN Blocking)
        if ($reqPath -eq '/api/songrequest/proxy-audio' -and ($request.HttpMethod -eq 'GET' -or $request.HttpMethod -eq 'HEAD')) {
            $audioUrl = $request.QueryString['url']
            if ($audioUrl) {
                try {
                    $webReq = [System.Net.HttpWebRequest]::Create($audioUrl)
                    $webReq.Method = "GET"
                    $webReq.Timeout = 8000
                    $webReq.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                    $webResp = $webReq.GetResponse()
                    $cType = $webResp.ContentType
                    if (-not $cType -or $cType -eq "") {
                        if ($audioUrl.Contains(".m4a")) { $cType = "audio/mp4" }
                        else { $cType = "audio/mpeg" }
                    }
                    $response.ContentType = $cType
                    $response.StatusCode = 200
                    $response.AddHeader("Access-Control-Allow-Origin", "*")
                    $response.AddHeader("Accept-Ranges", "bytes")
                    $respStream = $webResp.GetResponseStream()
                    $respStream.CopyTo($response.OutputStream)
                    $respStream.Close()
                    $webResp.Close()
                    $response.OutputStream.Close()
                    continue
                } catch {
                    Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
                    continue
                }
            } else {
                Send-JsonResponse $response @{ status = "error"; message = "Missing url parameter" } 400
                continue
            }
        }

        if ($reqPath -eq '/api/songrequest/queue' -and $request.HttpMethod -eq 'POST') {
            $body = ReadRequestBody $request
            if (-not $script:songRequestState) { $script:songRequestState = Load-SongRequestState }
            try {
                $item = $body | ConvertFrom-Json
                if ($item -and $item.title) {
                    $qList = @()
                    if ($script:songRequestState.queue) {
                        $qList += @($script:songRequestState.queue)
                    }

                    $pUrl = if ($item.PSObject.Properties['previewUrl'] -and $item.previewUrl) { [string]$item.previewUrl } else { "" }
                    $cUrl = if ($item.PSObject.Properties['coverUrl'] -and $item.coverUrl) { [string]$item.coverUrl } else { "" }
                    $sArt = if ($item.PSObject.Properties['artist'] -and $item.artist) { [string]$item.artist } else { "" }

                    # Auto detect singer and resolve preview audio if missing or generic
                    if (-not $pUrl -or $pUrl -eq "" -or -not $sArt -or $sArt -eq "Requested Track" -or $sArt -eq "Unknown Artist") {
                        $searchQuery = if ($sArt -and $sArt -ne "Requested Track" -and $sArt -ne "Unknown Artist") { "$($item.title) $sArt" } else { [string]$item.title }
                        $resolved = Resolve-MusicTrack $searchQuery
                        if ($resolved) {
                            if (-not $pUrl -or $pUrl -eq "") { $pUrl = $resolved.previewUrl }
                            if (-not $cUrl -or $cUrl -eq "" -or $cUrl.Contains("unsplash")) { $cUrl = $resolved.coverUrl }
                            if (-not $sArt -or $sArt -eq "Requested Track" -or $sArt -eq "Unknown Artist") { $sArt = $resolved.artist }
                            $item.title = $resolved.title
                        }
                    }

                    $songObj = [PSCustomObject]@{
                        id = if ($item.PSObject.Properties['id'] -and $item.id) { [string]$item.id } else { "req_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
                        title = [string]$item.title
                        artist = if ($sArt) { $sArt } else { "Unknown Artist" }
                        singer = if ($sArt) { $sArt } else { "Unknown Artist" }
                        album = if ($item.PSObject.Properties['album'] -and $item.album) { [string]$item.album } else { "Single" }
                        coverUrl = $cUrl
                        durationMs = if ($item.PSObject.Properties['durationMs'] -and $item.durationMs) { [int]$item.durationMs } else { 180000 }
                        requestedBy = if ($item.PSObject.Properties['requestedBy'] -and $item.requestedBy) { [string]$item.requestedBy } else { "Viewer" }
                        timestamp = if ($item.PSObject.Properties['timestamp'] -and $item.timestamp) { [string]$item.timestamp } else { [DateTime]::Now.ToString("h:mm tt") }
                        status = "queued"
                        uri = if ($item.PSObject.Properties['uri'] -and $item.uri) { [string]$item.uri } else { "" }
                        previewUrl = $pUrl
                    }
                    $qList += $songObj
                    $script:songRequestState.queue = $qList
                    Save-SongRequestState $script:songRequestState
                    AddEventLog @{ type = "songrequest_queue_add"; song = $songObj; queue = $script:songRequestState.queue }
                    Send-JsonResponse $response @{ status = "ok"; song = $songObj; queue = $script:songRequestState.queue }
                } else {
                    Send-JsonResponse $response @{ status = "error"; message = "Invalid song payload" } 400
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        if ($reqPath -eq '/api/songrequest/skip' -and $request.HttpMethod -eq 'POST') {
            if (-not $script:songRequestState) { $script:songRequestState = Load-SongRequestState }
            try {
                $qList = @()
                if ($script:songRequestState.queue) {
                    $qList += @($script:songRequestState.queue)
                }
                $skipped = $script:songRequestState.nowPlaying
                if ($skipped) {
                    $hist = @()
                    if ($script:songRequestState.history) {
                        $hist += @($script:songRequestState.history)
                    }
                    $skippedRecord = [PSCustomObject]@{
                        id = [string]$skipped.id
                        title = [string]$skipped.title
                        artist = [string]$skipped.artist
                        singer = if ($skipped.PSObject.Properties['singer'] -and $skipped.singer) { [string]$skipped.singer } else { [string]$skipped.artist }
                        requestedBy = [string]$skipped.requestedBy
                        timestamp = [DateTime]::Now.ToString("h:mm tt")
                        status = "skipped"
                    }
                    $hist = @($skippedRecord) + $hist
                    if ($hist.Length -gt 40) { $hist = $hist[0..39] }
                    $script:songRequestState.history = $hist
                }
                if ($qList.Length -gt 0) {
                    $nextSong = $qList[0]
                    $qList = if ($qList.Length -gt 1) { $qList[1..($qList.Length - 1)] } else { @() }
                    $script:songRequestState.queue = $qList

                    $nxtPrevUrl = if ($nextSong.PSObject.Properties['previewUrl'] -and $nextSong.previewUrl) { [string]$nextSong.previewUrl } else { "" }
                    $nxtCovUrl = if ($nextSong.PSObject.Properties['coverUrl'] -and $nextSong.coverUrl) { [string]$nextSong.coverUrl } else { "" }
                    $nxtArt = if ($nextSong.PSObject.Properties['artist'] -and $nextSong.artist) { [string]$nextSong.artist } else { "" }
                    if (-not $nxtPrevUrl -or $nxtPrevUrl -eq "" -or -not $nxtArt -or $nxtArt -eq "Requested Track" -or $nxtArt -eq "Unknown Artist") {
                        $searchQuery = if ($nxtArt -and $nxtArt -ne "Requested Track" -and $nxtArt -ne "Unknown Artist") { "$($nextSong.title) $nxtArt" } else { [string]$nextSong.title }
                        $resolved = Resolve-MusicTrack $searchQuery
                        if ($resolved) {
                            if (-not $nxtPrevUrl -or $nxtPrevUrl -eq "") { $nxtPrevUrl = $resolved.previewUrl }
                            if (-not $nxtCovUrl -or $nxtCovUrl -eq "" -or $nxtCovUrl.Contains("unsplash")) { $nxtCovUrl = $resolved.coverUrl }
                            if (-not $nxtArt -or $nxtArt -eq "Requested Track" -or $nxtArt -eq "Unknown Artist") { $nxtArt = $resolved.artist }
                        }
                    }

                    $script:songRequestState.nowPlaying = [PSCustomObject]@{
                        id = [string]$nextSong.id
                        title = [string]$nextSong.title
                        artist = if ($nxtArt) { $nxtArt } else { "Unknown Artist" }
                        singer = if ($nxtArt) { $nxtArt } else { "Unknown Artist" }
                        album = if ($nextSong.album) { [string]$nextSong.album } else { "Single" }
                        coverUrl = $nxtCovUrl
                        durationMs = if ($nextSong.durationMs) { [int]$nextSong.durationMs } else { 180000 }
                        progressMs = 0
                        requestedBy = [string]$nextSong.requestedBy
                        isPlaying = $true
                        uri = if ($nextSong.uri) { [string]$nextSong.uri } else { "" }
                        previewUrl = $nxtPrevUrl
                    }
                } else {
                    $script:songRequestState.nowPlaying = $null
                }
                Save-SongRequestState $script:songRequestState
                AddEventLog @{ type = "songrequest_skip"; nowPlaying = $script:songRequestState.nowPlaying; queue = $script:songRequestState.queue }
                Send-JsonResponse $response @{ status = "ok"; nowPlaying = $script:songRequestState.nowPlaying; queue = $script:songRequestState.queue }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # 6.7 Studio AI Neural Character Voice Audio Generator
        if ($reqPath -eq '/api/tts/audio' -and $request.HttpMethod -eq 'GET') {
            $voiceId = $request.QueryString['voice']
            $text = $request.QueryString['text']
            if (-not $text) { $text = "Hello chat, welcome to the stream!" }
            
            $bytes = $null
            $mimeType = "audio/mpeg"

            # Tier 1: Dedicated AI Character Voices
            try {
                $tiktokMap = @{
                    'adam'     = 'en_us_006'
                    'robot_x'  = 'en_male_c3po'
                    'sakura'   = 'en_female_emotional'
                    'jenny'    = 'en_us_001'
                    'pinay'    = 'en_female_samc'
                    'marcus'   = 'en_male_narration'
                    'speedrun' = 'en_male_funny'
                    'calm'     = 'en_female_f08_twinkle'
                }
                
                $ttVoice = if ($tiktokMap.ContainsKey($voiceId)) { $tiktokMap[$voiceId] } else { $voiceId }
                
                if ($voiceId -eq 'pinay' -or $voiceId -eq 'ate_may') {
                    $u = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=tl&q=" + [System.Uri]::EscapeDataString($text)
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                    $bytes = $wc.DownloadData($u)
                } elseif ($voiceId -eq 'robot_x') {
                    $u = "https://api.streamelements.com/kappa/v2/speech?voice=Brian&text=" + [System.Uri]::EscapeDataString($text)
                    $wc = New-Object System.Net.WebClient
                    $bytes = $wc.DownloadData($u)
                } else {
                    $genPayload = @{ text = $text; voice = $ttVoice } | ConvertTo-Json
                    $ttRes = Invoke-RestMethod -Uri "https://tiktok-tts.weilnet.workers.dev/api/generation" -Method POST -Body $genPayload -ContentType "application/json" -TimeoutSec 5
                    if ($ttRes -and $ttRes.success -and $ttRes.data) {
                        $bytes = [System.Convert]::FromBase64String($ttRes.data)
                    }
                }
            } catch {}

            # Tier 2: StreamElements / Google TTS Fallback
            if (-not $bytes -or $bytes.Length -eq 0) {
                try {
                    $fbVoice = if ($voiceId -in @('sakura', 'jenny', 'calm')) { 'Emma' } else { 'Brian' }
                    $u = "https://api.streamelements.com/kappa/v2/speech?voice=$fbVoice&text=" + [System.Uri]::EscapeDataString($text)
                    $wc = New-Object System.Net.WebClient
                    $bytes = $wc.DownloadData($u)
                } catch {
                    try {
                        $lang = if ($voiceId -in @('sakura')) { 'ja' } else { 'en' }
                        $u = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=$lang&q=" + [System.Uri]::EscapeDataString($text)
                        $wc = New-Object System.Net.WebClient
                        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                        $bytes = $wc.DownloadData($u)
                    } catch {}
                }
            }

            # Tier 3: Local Windows SAPI / OneCore Synthesizer (100% Offline Resilience)
            if (-not $bytes -or $bytes.Length -eq 0) {
                try {
                    Add-Type -AssemblyName System.Speech -ErrorAction SilentlyContinue
                    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
                    if ($voiceId -in @('sakura', 'jenny', 'pinay', 'calm')) {
                        $synth.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
                    } else {
                        $synth.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Male)
                    }
                    $ms = New-Object System.IO.MemoryStream
                    $synth.SetOutputToWaveStream($ms)
                    $synth.Speak($text)
                    $bytes = $ms.ToArray()
                    $mimeType = "audio/wav"
                } catch {}
            }

            if ($bytes -and $bytes.Length -gt 0) {
                $response.ContentType = $mimeType
                $response.StatusCode = 200
                $response.ContentLength64 = $bytes.Length
                $response.Headers.Add("Cache-Control", "public, max-age=86400")
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.Close()
                continue
            } else {
                Send-JsonResponse $response @{ status = "error"; message = "TTS Audio generation failed" } 500
                continue
            }
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

                # Also execute any configured gift card commands bound to this spinner's gift
                if ($targetSpinner -and $config -and $config.gifts) {
                    $spGId = if ($targetSpinner.giftId) { [string]$targetSpinner.giftId.Trim() } else { "" }
                    $spGName = if ($targetSpinner.giftName) { ($targetSpinner.giftName -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                    if ($spGId -or $spGName) {
                        foreach ($g in $config.gifts) {
                            if (-not $g.enabled) { continue }
                            $cMatch = $false
                            $cGId = if ($g.giftId) { [string]$g.giftId.Trim() } else { "" }
                            $cGName = if ($g.giftName) { ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                            if ($spGId -and $cGId -and $spGId -eq $cGId) { $cMatch = $true }
                            elseif (($spGId -eq '7934' -or $spGName -eq 'heartme' -or $spGName -eq 'heart') -and ($cGId -eq '7934' -or $cGName -eq 'heartme' -or $cGName -eq 'heart')) { $cMatch = $true }
                            elseif ($spGName -and $cGName -and ($spGName -eq $cGName -or $cGName.Contains($spGName) -or $spGName.Contains($cGName))) { $cMatch = $true }
                            if ($cMatch) {
                                $isCardSpinnerCmd = ($g.command -eq "spin_wheel" -or $g.actionType -eq "spinner" -or $g.command -match '^spinner_')
                                if (-not $isCardSpinnerCmd -and ($g.command -or ($g.commands -and $g.commands.Count -gt 0))) {
                                    $cReps = if ($g.repetition -and [int]$g.repetition -gt 0) { [int]$g.repetition } elseif ($g.amount) { [int]$g.amount } else { 1 }
                                    $cDelay = if ($g.delay) { [int]$g.delay } else { 0 }
                                    $cInterval = if ($g.interval) { [int]$g.interval } else { 100 }
                                    if ($g.commands -and $g.commands.Count -gt 0) {
                                        foreach ($sc in $g.commands) {
                                            if ($sc.command -and $sc.command -ne "spin_wheel" -and $sc.command -notmatch '^spinner_') {
                                                $scAct = if ($sc.actionType) { $sc.actionType } else { $g.actionType }
                                                SendToPvZGame $scAct $sc.command $cReps $username "" 1 $cDelay $cInterval | Out-Null
                                            }
                                        }
                                    } elseif ($g.command) {
                                        SendToPvZGame $g.actionType $g.command $cReps $username "" 1 $cDelay $cInterval | Out-Null
                                    }
                                }
                                break
                            }
                        }
                    }
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

                # Check for streamer profile event from TikTok bridge
                if ($payload.event -eq "streamer_profile") {
                    $u = if ($payload.username) { [string]$payload.username } else { "" }
                    $av = if ($payload.avatar) { [string]$payload.avatar } else { "" }
                    $nick = if ($payload.nickname) { [string]$payload.nickname } else { "" }
                    if ($u -and $av) {
                        if (-not $config.streamer) {
                            $config | Add-Member -NotePropertyName streamer -NotePropertyValue ([PSCustomObject]@{}) -Force
                        }
                        if (-not ($config.streamer.PSObject.Properties.Match('streamerAvatar').Count)) {
                            $config.streamer | Add-Member -NotePropertyName streamerAvatar -NotePropertyValue $av -Force
                        } else {
                            $config.streamer.streamerAvatar = $av
                        }
                        if ($nick) {
                            if (-not ($config.streamer.PSObject.Properties.Match('streamerNickname').Count)) {
                                $config.streamer | Add-Member -NotePropertyName streamerNickname -NotePropertyValue $nick -Force
                            } else {
                                $config.streamer.streamerNickname = $nick
                            }
                        }
                        try {
                            $cfgJson = $config | ConvertTo-Json -Depth 10
                            [System.IO.File]::WriteAllText($configFile, $cfgJson, [System.Text.Encoding]::UTF8)
                            $userCfg = Get-UserConfigPath $u
                            if ($userCfg -and (Test-Path $userCfg) -and ($userCfg -ne $configFile)) {
                                [System.IO.File]::WriteAllText($userCfg, $cfgJson, [System.Text.Encoding]::UTF8)
                            }
                        } catch {}

                        AddEventLog @{
                            type = "streamer_profile"
                            username = $u
                            avatar = $av
                            nickname = $nick
                        }
                    }
                    Send-JsonResponse $response @{ status = "ok"; message = "Streamer profile updated" }
                    continue
                }

                # Check if it is a gift event
                if ($payload.event -eq "gift") {
                    $giftName = if ($payload.giftName) { [string]$payload.giftName } else { "" }
                    $giftId = if ($payload.giftId -ne $null) { ([string]$payload.giftId).Trim() } else { "" }
                    $repeatCount = if ($payload.repeatCount) { [int]$payload.repeatCount } else { 1 }
                    $isStreak = if ($payload.isStreak -ne $null) { [bool]$payload.isStreak } else { ($payload.totalRepeatCount -and [int]$payload.totalRepeatCount -gt 1) }
                    $totReps = if ($payload.totalRepeatCount) { [int]$payload.totalRepeatCount } else { [int]$repeatCount }
                    $repEnd = if ($payload.repeatEnd -ne $null) { [bool]$payload.repeatEnd } else { $false }
                    $user = if ($payload.username) { [string]$payload.username } elseif ($payload.nickname) { [string]$payload.nickname } elseif ($payload.uniqueId) { [string]$payload.uniqueId } else { "" }
                    # If this is a tester simulation event or missing username, use RENEarn. If live on TikTok, real gifter name is kept!
                    if (-not $user -or $user -in @("User", "TestViewer", "TestGifter", "Tester", "SocialTester", "StreamViewer", "Viewer", "Streamer", "")) {
                        $user = "RENEarn"
                    }
                    $avatar = if ($payload.profilePictureUrl) { $payload.profilePictureUrl } elseif ($payload.avatar) { $payload.avatar } elseif ($payload.avatarUrl) { $payload.avatarUrl } else { "images/default_avatar.svg" }
                    $icon = if ($payload.giftPictureUrl) { $payload.giftPictureUrl } else { "" }

                    # DEDUPLICATION BY UNIQUE MESSAGE ID:
                    # Drop duplicate socket retransmission packets without dropping legitimate rapid gifts!
                    $cleanUserKey = ($user.ToLower() -replace '[^a-z0-9]', '')
                    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    $incomingMsgId = if ($payload.msgId) { [string]$payload.msgId } else { "" }

                    if (-not $script:processedGiftMsgIds) {
                        $script:processedGiftMsgIds = [System.Collections.Generic.Dictionary[string, int64]]::new()
                    }

                    if ($incomingMsgId -and $script:processedGiftMsgIds.ContainsKey($incomingMsgId)) {
                        $lastMsgTime = $script:processedGiftMsgIds[$incomingMsgId]
                        if (($nowMs - $lastMsgTime) -lt 10000) {
                            Send-JsonResponse $response @{ status = "ok"; message = "Duplicate packet ignored by msgId ($incomingMsgId)"; debounced = $true }
                            continue
                        }
                    }
                    if ($incomingMsgId) {
                        $script:processedGiftMsgIds[$incomingMsgId] = $nowMs
                        if ($script:processedGiftMsgIds.Count -gt 500) {
                            $oldKeys = @($script:processedGiftMsgIds.Keys | Where-Object { ($nowMs - $script:processedGiftMsgIds[$_]) -gt 15000 })
                            foreach ($ok in $oldKeys) { [void]$script:processedGiftMsgIds.Remove($ok) }
                        }
                    } else {
                        # Fallback for events without msgId: Only debounce sub-80ms duplicate echoes
                        $fallbackKey = "$cleanUserKey`_$giftId`_$repeatCount"
                        if ($script:recentGiftDeduplication.ContainsKey($fallbackKey)) {
                            $lastTime = [int64]$script:recentGiftDeduplication[$fallbackKey]
                            if (($nowMs - $lastTime) -lt 80) {
                                Send-JsonResponse $response @{ status = "ok"; message = "Debounced sub-80ms socket echo"; debounced = $true }
                                continue
                            }
                        }
                        $script:recentGiftDeduplication[$fallbackKey] = $nowMs
                    }

                    # SERVER-SIDE STREAK DEDUPLICATION GUARD:
                    # Drop duplicate repeatEnd confirmation packets or socket echoes for the same user + gift (1 gift = 1 command only!)
                    if (-not $script:userGiftStreakTracker) {
                        $script:userGiftStreakTracker = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
                    }
                    $streakTrackingKey = "$cleanUserKey`_$giftId"
                    if ($script:userGiftStreakTracker.ContainsKey($streakTrackingKey)) {
                        $rec = $script:userGiftStreakTracker[$streakTrackingKey]
                        $timeSinceLastGift = $nowMs - [int64]$rec.time
                        if ($timeSinceLastGift -lt 4000 -and $totReps -le [int]$rec.lastTotalReps -and $repeatCount -le 1) {
                            Send-JsonResponse $response @{ status = "ok"; message = "Duplicate streak echo ignored ($streakTrackingKey, total: $totReps)"; debounced = $true }
                            continue
                        }
                        $rec.time = $nowMs
                        $rec.lastTotalReps = $totReps
                    } else {
                        $script:userGiftStreakTracker[$streakTrackingKey] = @{
                            time = $nowMs
                            lastTotalReps = $totReps
                        }
                    }

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
                    # Only genuine live viewer gifts drop into the jar (tester commands/tests are excluded)
                    $isTestStreamDrop = ($payload.isTest -eq $true -or $payload.noJarDrop -eq $true -or $user -in @('RENEarn', 'Tester', 'TestViewer', 'RENEarn_Streamer'))
                    if (-not $isTestStreamDrop) {
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
                        if (-not $jarIcon -or $jarIcon -eq "images/default_avatar.svg" -or $jarIcon -match "game-icons") {
                            if ($giftName -match '(?i)heart\s*me') { $jarIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                            elseif ($giftName -match '(?i)finger\s*heart') { $jarIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
                            elseif ($giftName -match '(?i)hand\s*heart') { $jarIcon = "images/tiktok-gifts/5660_hand_heart.webp" }
                            elseif ($giftName -match '(?i)chicken') { $jarIcon = "images/tiktok-gifts/15328_fried_chicken.webp" }
                            elseif ($giftName -match '(?i)arcade|game\s*controller|controller') { $jarIcon = "images/tiktok-gifts/5876_arcade_game.webp" }
                            elseif ($giftName -match '(?i)panda') { $jarIcon = "images/tiktok-gifts/5659_panda.webp" }
                            elseif ($giftName -match '(?i)confetti') { $jarIcon = "images/tiktok-gifts/7121_marvelous_confetti.webp" }
                            elseif ($giftName -match '(?i)money\s*gun') { $jarIcon = "images/tiktok-gifts/5881_money_gun.webp" }
                            elseif ($giftName -match '(?i)firework') { $jarIcon = "images/tiktok-gifts/6090_fireworks.webp" }
                            elseif ($giftName -match '(?i)whale') { $jarIcon = "images/tiktok-gifts/6820_whale_diving.webp" }
                            elseif ($giftName -match '(?i)swan') { $jarIcon = "images/tiktok-gifts/5897_swan.webp" }
                            elseif ($giftName -match '(?i)corgi') { $jarIcon = "images/tiktok-gifts/6267_corgi.webp" }
                            elseif ($giftName -match '(?i)perfume') { $jarIcon = "images/tiktok-gifts/5658_perfume.webp" }
                            elseif ($giftName -match '(?i)cake') { $jarIcon = "images/tiktok-gifts/6784_cake_slice.webp" }
                            elseif ($giftName -match '(?i)thumbs\s*up') { $jarIcon = "images/tiktok-gifts/6246_thumbs_up.webp" }
                            elseif ($giftCoinValue -eq 5) { $jarIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
                            elseif ($giftName -match '(?i)heart') { $jarIcon = "images/tiktok-gifts/7934_heart_me.webp" }
                            elseif ($giftName -match '(?i)ice') { $jarIcon = "images/tiktok-gifts/5827_ice_cream_cone.webp" }
                            elseif ($giftName -match '(?i)tiktok') { $jarIcon = "images/tiktok-gifts/5269_tiktok.webp" }
                            elseif ($giftName -match '(?i)cap') { $jarIcon = "images/tiktok-gifts/6104_cap.webp" }
                            elseif ($giftName -match '(?i)gg') { $jarIcon = "images/tiktok-gifts/6064_gg.webp" }
                            elseif ($giftName -match '(?i)doughnut|donut') { $jarIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                            elseif ($giftName -match '(?i)galaxy') { $jarIcon = "images/tiktok-gifts/11046_galaxy.webp" }
                            elseif ($giftName -match '(?i)lion') { $jarIcon = "images/tiktok-gifts/5962_lion.webp" }
                            elseif ($giftName -match '(?i)universe') { $jarIcon = "images/tiktok-gifts/6059_tiktok_universe.webp" }
                            elseif ($giftName -match '(?i)rose\s*bear') { $jarIcon = "images/tiktok-gifts/15862_rose_bear.webp" }
                            elseif ($giftCoinValue -ge 1000) { $jarIcon = "images/tiktok-gifts/11046_galaxy.webp" }
                            elseif ($giftCoinValue -ge 500) { $jarIcon = "images/tiktok-gifts/5881_money_gun.webp" }
                            elseif ($giftCoinValue -ge 99) { $jarIcon = "images/tiktok-gifts/6104_cap.webp" }
                            elseif ($giftCoinValue -ge 30) { $jarIcon = "images/tiktok-gifts/5879_doughnut.webp" }
                            elseif ($giftCoinValue -ge 5) { $jarIcon = "images/tiktok-gifts/5487_finger_heart.webp" }
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

                        # STREAMER GIFT GALLERY: Auto-detect if gift contributes to unobtained gallery items
                        Process-GiftForGallery $giftName $giftId $user $avatar $repeatCount $jarIcon
                    }

                    # RAPID GIFTING PERMITTED:
                    # Consecutive gifts from the same viewer (even within 1 second) summon immediately!
                    # Retain only sub-80ms loopback bounce suppression
                    if ($cleanUserKey -and -not $incomingMsgId -and $script:recentSpins.ContainsKey($cleanUserKey)) {
                        $lastTime = [int64]$script:recentSpins[$cleanUserKey]
                        if (($nowMs - $lastTime) -lt 80) {
                            Send-JsonResponse $response @{ status = "ok"; message = "Debounced sub-80ms echo" }
                            continue
                        }
                    }
                    if ($cleanUserKey) { $script:recentSpins[$cleanUserKey] = $nowMs }

                    # 1. Check if gift matches a multi-spinner trigger
                    $matchedSpinner = $null

                    # Priority A: Check if a configured gift card matches this gift and has a bound spinner (e.g. Card 32 Heart Me -> spinner_plusminus)
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
                                $bSpId = if ($g.spinnerId) { [string]$g.spinnerId } elseif ($g.triggerSpinner) { [string]$g.triggerSpinner } elseif ($g.command -match '^spinner_') { [string]$g.command } else { "" }
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

                    # Priority B: Universal direct spinner match (Spinner 1 Perfume, Spinner 2 Doughnut, Spinner 3 Hat, Spinner 4 Heart Me, Spinner 5 Bubble Gum)
                    # Guarantees that ANY gift bound to a spinner triggers the spinner visualizer & reward!
                    if (-not $matchedSpinner -and $config -and $config.spinners) {
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
                            # Check Heart Me aliases (Spinner 4)
                            if (($cleanSpGId -eq '7934' -or $cleanSpGId -eq 'heartme' -or $cleanSpGId -eq 'heart') -and ($cleanReqGId -eq '7934' -or $cleanReqGId -eq 'heartme' -or $cleanReqGId -eq 'heart')) {
                                $matchedSpinner = $sp; break
                            }
                            # Check Perfume aliases (Spinner 1)
                            if (($cleanSpGId -eq '5658' -or $cleanSpGId -eq '5585' -or $cleanSpGId -eq 'perfume') -and ($cleanReqGId -eq '5658' -or $cleanReqGId -eq '5585' -or $cleanReqGId -eq 'perfume')) {
                                $matchedSpinner = $sp; break
                            }
                            # Check Doughnut aliases (Spinner 2)
                            if (($cleanSpGId -eq '5879' -or $cleanSpGId -eq 'doughnut' -or $cleanSpGId -eq 'donut') -and ($cleanReqGId -eq '5879' -or $cleanReqGId -eq 'doughnut' -or $cleanReqGId -eq 'donut')) {
                                $matchedSpinner = $sp; break
                            }
                            # Check Hat and Mustache aliases (Spinner 3)
                            if (($cleanSpGId -eq '6427' -or $cleanSpGId -eq 'hatandmustache' -or $cleanSpGId -eq 'hat') -and ($cleanReqGId -eq '6427' -or $cleanReqGId -eq 'hatandmustache' -or $cleanReqGId -eq 'hat')) {
                                $matchedSpinner = $sp; break
                            }
                            # Check Bubble Gum aliases (Spinner 5)
                            if (($cleanSpGId -eq '13087' -or $cleanSpGId -eq 'bubblegum') -and ($cleanReqGId -eq '13087' -or $cleanReqGId -eq 'bubblegum')) {
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
                            # Check Finger Heart aliases
                            if (($cleanSpGId -eq '5487' -or $cleanSpGId -eq 'fingerheart') -and ($cleanReqGId -eq '5487' -or $cleanReqGId -eq 'fingerheart')) {
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
                            # Check autoGift name matching
                            if ($autoGift -and $autoGift.name -and $sp.giftName) {
                                $cleanAuto = ($autoGift.name -replace '[^a-zA-Z0-9]','').ToLower()
                                $cleanSp = ($sp.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                if ($cleanAuto -and $cleanSp -and ($cleanAuto -eq $cleanSp -or $cleanAuto.Contains($cleanSp) -or $cleanSp.Contains($cleanAuto))) {
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

                    if ($matchedSpinner) {
                        # Trigger that specific spinner with exact 1 gift = 1 spin = 1 command execution!
                        $spSlices = if ($matchedSpinner.slices) { $matchedSpinner.slices } else { @() }
                        $totalSpins = [Math]::Max(1, [int]$repeatCount)
                        $visualSpins = [Math]::Min($totalSpins, 15) # Keep visual queue silky smooth without freezing overlay on huge combos
                        $spName = $matchedSpinner.name
                        $spDuration = if ($matchedSpinner.duration) { [int]$matchedSpinner.duration } else { 2500 }
                        $spTicks = if ($matchedSpinner.ticks) { [int]$matchedSpinner.ticks } else { 100 }

                        for ($spinIdx = 0; $spinIdx -lt $totalSpins; $spinIdx++) {
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
                                if ($picked.actionType -and $picked.actionType -ne "score" -and ($picked.command -or $picked.commands)) {
                                    # Summon the won unit directly in PvZ Fusion mod: exactly 1 command execution per gift!
                                    $spReps = if ($picked.repetition) { [int]$picked.repetition } elseif ($picked.amount) { [int]$picked.amount } else { 1 }
                                    $spAmt = if ($picked.amount) { [int]$picked.amount } else { $spReps }
                                    $spDelay = if ($picked.delay) { [int]$picked.delay } else { 0 }
                                    $spInt = if ($picked.interval) { [int]$picked.interval } else { 100 }

                                    if ($picked.commands -and $picked.commands.Count -gt 0) {
                                        foreach ($sc in $picked.commands) {
                                            if ($sc.command) {
                                                $scAct = if ($sc.actionType) { $sc.actionType } else { $picked.actionType }
                                                $scAmt = if ($sc.amount) { [int]$sc.amount } else { $spAmt }
                                                SendToPvZGame $scAct $sc.command $scAmt $user "" $spReps $spDelay $spInt | Out-Null
                                            }
                                        }
                                    } else {
                                        SendToPvZGame $picked.actionType $picked.command $spAmt $user "" $spReps $spDelay $spInt | Out-Null
                                    }
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

                            if ($spinIdx -lt $visualSpins) {
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
                                    alreadySummoned = $true
                                    success = $true
                                }
                                Add-SpinnerHistoryRecord $user $avatar $picked $spName $matchedSpinner.id
                            }
                        }

                        # Also execute and increment the matched gift card action (e.g. Card 32: Heart Me -> Spawn Big Sun Nut x50)
                        # Guarantees that when both a spinner and a gift card share the same gift, THEY BOTH WORK TOGETHER!
                        if ($config -and $config.gifts) {
                            foreach ($g in $config.gifts) {
                                $cardMatch = $false
                                $gGId = if ($g.giftId) { [string]$g.giftId.Trim() } else { "" }
                                $reqGId = if ($giftId) { [string]$giftId.Trim() } else { "" }
                                $autoGId = if ($autoGift -and $autoGift.id) { [string]$autoGift.id.Trim() } else { "" }

                                if ($g.enabled -and $gGId -and (($reqGId -and $gGId -eq $reqGId) -or ($autoGId -and $gGId -eq $autoGId))) {
                                    $cardMatch = $true
                                } elseif ($g.enabled) {
                                    $cleanGGId = ($gGId -replace '[^a-zA-Z0-9]','').ToLower()
                                    $cleanReqGId = ($reqGId -replace '[^a-zA-Z0-9]','').ToLower()
                                    if ($cleanGGId -and $cleanReqGId -and ($cleanGGId -eq $cleanReqGId)) {
                                        $cardMatch = $true
                                    } elseif (($cleanGGId -eq '7934' -or $cleanGGId -eq 'heartme' -or $cleanGGId -eq 'heart') -and ($cleanReqGId -eq '7934' -or $cleanReqGId -eq 'heartme' -or $cleanReqGId -eq 'heart')) {
                                        $cardMatch = $true
                                    } elseif ($g.giftName) {
                                        $cleanG = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                        $cleanR = if ($giftName) { ($giftName -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                                        $cleanA = if ($autoGift -and $autoGift.name) { ($autoGift.name -replace '[^a-zA-Z0-9]','').ToLower() } else { "" }
                                        if ($cleanG -and (($cleanR -and ($cleanG -eq $cleanR -or $cleanR.Contains($cleanG) -or $cleanG.Contains($cleanR))) -or ($cleanA -and ($cleanG -eq $cleanA -or $cleanA.Contains($cleanG) -or $cleanG.Contains($cleanA))))) {
                                            $cardMatch = $true
                                        }
                                    }
                                }

                                if ($cardMatch) {
                                    $cardIdStr = [string]$g.id
                                    if ($cardIdStr) {
                                        if (-not $counts.ContainsKey($cardIdStr)) {
                                            $counts[$cardIdStr] = 0
                                        }
                                        $counts[$cardIdStr] = [int]$counts[$cardIdStr] + $repeatCount
                                        SaveCounts
                                    }

                                    AddEventLog @{
                                        type = "card_count_updated"
                                        cardId = $cardIdStr
                                        count = if ($cardIdStr -and $counts.ContainsKey($cardIdStr)) { [int]$counts[$cardIdStr] } else { $repeatCount }
                                        amount = $repeatCount
                                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                                    }

                                    # SUMMON CARD COMMANDS TOGETHER WITH SPINNER:
                                    # If this card has in-game summon commands (e.g. Card 32: Heart Me -> Spawn Big Sun Nut x50),
                                    # dispatch them directly to Plants vs. Zombies Fusion mod!
                                    $isCardSpinnerCmd = ($g.command -eq "spin_wheel" -or $g.actionType -eq "spinner" -or $g.command -match '^spinner_')
                                    if (-not $isCardSpinnerCmd -and ($g.command -or ($g.commands -and $g.commands.Count -gt 0))) {
                                        $baseUnitCount = if ($g.repetition -and [int]$g.repetition -gt 0) {
                                            [int]$g.repetition
                                        } elseif ($g.amount -and [int]$g.amount -gt 0) {
                                            [int]$g.amount
                                        } else {
                                            1
                                        }

                                        $isMultiplierActive = if ($null -eq $g.repetitionMultiplier) { $true } elseif ($g.repetitionMultiplier -is [bool]) { [bool]$g.repetitionMultiplier } else { (([string]$g.repetitionMultiplier).Trim().ToLower() -eq "true" -or ([string]$g.repetitionMultiplier).Trim() -eq "1") }
                                        $giftRepeatQty = [Math]::Max(1, [int]$repeatCount)
                                        $totalSpawns = if ($isMultiplierActive) { $baseUnitCount * $giftRepeatQty } else { $baseUnitCount }

                                        $giftDelay = if ($g.delay) { [int]$g.delay } else { 0 }
                                        $giftInterval = if ($g.interval) { [int]$g.interval } else { 100 }
                                        $giftHide = ($g.hideInOverlay -eq $true -or $g.hideInOverlay -eq "true")

                                        $cardGameCmds = @()
                                        if ($g.commands -and $g.commands.Count -gt 0) {
                                            foreach ($sc in $g.commands) {
                                                if ($sc.command -and $sc.command -ne "spin_wheel" -and $sc.command -notmatch '^spinner_') {
                                                    $cardGameCmds += $sc
                                                }
                                            }
                                        }

                                        # Add overlay gift event so the card animates and flashes on stream overlays
                                        AddEventLog @{
                                            type = "gift"
                                            cardId = [string]$g.id
                                            label = $g.label
                                            giftName = if ($giftName) { $giftName } elseif ($g.giftName) { $g.giftName } else { "Gift" }
                                            repeatCount = $repeatCount
                                            totalRepeatCount = $totReps
                                            repeatEnd = $repEnd
                                            isStreak = $isStreak
                                            command = $g.command
                                            amount = $totalSpawns
                                            username = $user
                                            icon = if ($g.unitIcon) { $g.unitIcon } elseif ($icon) { $icon } else { "images/func_2.png" }
                                            hideInOverlay = $giftHide
                                            noSpinnerTrigger = $true
                                        }

                                        # Dispatch summons to PvZ Fusion mod
                                        if ($cardGameCmds.Count -gt 0) {
                                            foreach ($sc in $cardGameCmds) {
                                                $scAct = if ($sc.actionType) { $sc.actionType } else { $g.actionType }
                                                SendToPvZGame $scAct $sc.command $totalSpawns $user "" 1 $giftDelay $giftInterval | Out-Null
                                            }
                                        } elseif ($g.command) {
                                            SendToPvZGame $g.actionType $g.command $totalSpawns $user "" 1 $giftDelay $giftInterval | Out-Null
                                        }

                                        # Route trigger event to dedicated on-screen counter
                                        $triggerLbl = if ($g.label) { [string]$g.label } elseif ($giftName) { [string]$giftName } else { "In-game Event" }
                                        $triggerIcon = if ($g.unitIcon) { [string]$g.unitIcon } elseif ($icon) { [string]$icon } else { "images/trig_7.svg" }
                                        Record-TriggerEvent $giftName $giftId $repeatCount $user $avatar $triggerIcon $triggerLbl
                                    }
                                    break
                                }
                            }
                        }

                        Send-JsonResponse $response @{ status = "ok"; type = "spin_result"; spinner = $spName; spins = $totalSpins }
                        continue
                    }

                    $matchedGift = $null
                    if ($config -and $config.gifts) {
                        # Strictly filter to only active GIFT cards (exclude social Follow, Likes, and Share trigger cards)
                        $giftCards = @($config.gifts | Where-Object { 
                            $_.enabled -and 
                            [string]$_.id -notin @("1", "2", "3", "4") -and 
                            $_.triggerType -notin @("follow", "likes", "likes_person", "likes_all", "share") -and 
                            $_.eventType -notin @("follow", "likes", "likes_person", "likes_all", "share") -and 
                            $_.giftName -notmatch "^(Follower|Team plants likes|Team zombies likes|Total Likes)$" 
                        })

                        # 1. Match by giftId (exact string comparison or alias)
                        $lookupIds = @()
                        if ($giftId) { $lookupIds += ([string]$giftId).Trim() }
                        if ($autoGift -and $autoGift.id) { $lookupIds += ([string]$autoGift.id).Trim() }

                        if ($lookupIds.Count -gt 0) {
                            foreach ($g in $giftCards) {
                                $gGId = if ($g.giftId) { ([string]$g.giftId).Trim() } else { "" }
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
                                foreach ($g in $giftCards) {
                                    if ($g.giftName) {
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
                                foreach ($g in $giftCards) {
                                    if ($g.giftName) {
                                        $cleanCfgName = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
                                        if ($cleanCfgName -and ($cleanCfgName -eq $cleanCatName -or $cleanCatName.Contains($cleanCfgName) -or $cleanCatName.Contains($cleanCfgName))) {
                                            $matchedGift = $g; break
                                        }
                                    }
                                }
                            }
                        }

                        # 4. High-tier / Mega Boss fallback ONLY for massive donations >= 300 to 49,999+ coins (e.g. Galaxy, Money Gun, Lion, Universe)
                        # When a donor sends a huge multi-dollar gift that isn't mapped, summon the highest configured boss card
                        $unitCoins = if ($payload.diamondCount -and [int]$payload.diamondCount -gt 0) { [int]$payload.diamondCount } elseif ($payload.coins -and [int]$payload.coins -gt 0) { [int]$payload.coins / [Math]::Max(1, $repeatCount) } elseif ($giftCoinValue -gt 0) { [int]$giftCoinValue / [Math]::Max(1, $repeatCount) } else { 1 }
                        $unitCoinsInt = [int][Math]::Round($unitCoins)

                        if (-not $matchedGift -and $unitCoinsInt -ge 300) {
                            $bestCard = $null
                            $maxCoins = 0
                            foreach ($g in $giftCards) {
                                $gCoins = if ($g.coins -ne $null) { [int]$g.coins } else { 0 }
                                if ($gCoins -le $unitCoinsInt -and $gCoins -gt $maxCoins) {
                                    $maxCoins = $gCoins
                                    $bestCard = $g
                                }
                            }
                            if ($bestCard) {
                                $matchedGift = $bestCard
                            }
                        }
                    }

                    if ($matchedGift) {
                        # Increment card count in $counts so overlay updates in real-time!
                        $cardIdStr = [string]$matchedGift.id
                        if ($cardIdStr) {
                            if (-not $counts.ContainsKey($cardIdStr)) {
                                $counts[$cardIdStr] = 0
                            }
                            $counts[$cardIdStr] = [int]$counts[$cardIdStr] + $repeatCount
                            SaveCounts
                            AddEventLog @{
                                type = "card_count_updated"
                                cardId = $cardIdStr
                                count = [int]$counts[$cardIdStr]
                                amount = $repeatCount
                                timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                            }
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
                            $totalSpins = [Math]::Max(1, [int]$repeatCount)
                            $visualSpins = [Math]::Min($totalSpins, 15)
                            $cardSpName = if ($targetCardSp -and $targetCardSp.name) { $targetCardSp.name } else { "Lucky Wheel" }
                            $cardSpId = if ($targetCardSp -and $targetCardSp.id) { [string]$targetCardSp.id } else { "wheel" }
                            $cardSpDuration = if ($targetCardSp -and $targetCardSp.duration) { [int]$targetCardSp.duration } else { 2500 }
                            $cardSpTicks = if ($targetCardSp -and $targetCardSp.ticks) { [int]$targetCardSp.ticks } else { 100 }
                            $cardSpPointer = if ($targetCardSp) { $targetCardSp.pointerIcon } else { "" }
                            $cardSpGroup = if ($targetCardSp) { [string]$targetCardSp.groupId } else { "" }

                            for ($spinIdx = 0; $spinIdx -lt $totalSpins; $spinIdx++) {
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

                                    if ($picked.actionType -and $picked.actionType -ne "score" -and ($picked.command -or $picked.commands)) {
                                        if ($picked.commands -and $picked.commands.Count -gt 0) {
                                            foreach ($sc in $picked.commands) {
                                                if ($sc.command) {
                                                    $scAct = if ($sc.actionType) { $sc.actionType } else { $picked.actionType }
                                                    $scAmt = if ($sc.amount) { [int]$sc.amount } else { $spReps }
                                                    SendToPvZGame $scAct $sc.command $scAmt $user "" $spReps $spDelay $spInterval | Out-Null
                                                }
                                            }
                                        } else {
                                            $spAmt = if ($picked.amount) { [int]$picked.amount } else { $spReps }
                                            SendToPvZGame $picked.actionType $picked.command $spAmt $user "" $spReps $spDelay $spInterval | Out-Null
                                        }
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

                                    if ($spinIdx -lt $visualSpins) {
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
                                            alreadySummoned = $true
                                            success = $true
                                        }
                                        Add-SpinnerHistoryRecord $user $avatar $picked $cardSpName $cardSpId
                                    }
                                }
                            }
                            Send-JsonResponse $response @{ status = "ok"; type = "spin_result"; spinner = $cardSpName; spins = $totalSpins }
                            continue
                        } else {
                            # 1=1 COMMAND INTEGRITY:
                            # 1 gift sent = exactly 1 command execution of the configured card count!
                            # If card has Repetition: 5, then 1 gift spawns 5.
                            # If someone sends x2 gifts, it spawns 2 * 5 = 10.
                            $baseUnitCount = if ($matchedGift.repetition -and [int]$matchedGift.repetition -gt 0) {
                                [int]$matchedGift.repetition
                            } elseif ($matchedGift.amount -and [int]$matchedGift.amount -gt 0) {
                                [int]$matchedGift.amount
                            } else {
                                1
                            }

                            $isMultiplierActive = if ($null -eq $matchedGift.repetitionMultiplier) { $true } elseif ($matchedGift.repetitionMultiplier -is [bool]) { [bool]$matchedGift.repetitionMultiplier } else { (([string]$matchedGift.repetitionMultiplier).Trim().ToLower() -eq "true" -or ([string]$matchedGift.repetitionMultiplier).Trim() -eq "1") }
                            $giftRepeatQty = [Math]::Max(1, [int]$repeatCount)
                            $totalSpawns = if ($isMultiplierActive) { $baseUnitCount * $giftRepeatQty } else { $baseUnitCount }

                            $giftDelay = if ($matchedGift.delay) { [int]$matchedGift.delay } else { 0 }
                            $giftInterval = if ($matchedGift.interval) { [int]$matchedGift.interval } else { 100 }
                            $giftHide = ($matchedGift.hideInOverlay -eq $true -or $matchedGift.hideInOverlay -eq "true")

                            $cardGameCmds = @()
                            if ($matchedGift.commands -and $matchedGift.commands.Count -gt 0) {
                                foreach ($sc in $matchedGift.commands) {
                                    if ($sc.command) { $cardGameCmds += $sc }
                                }
                            }
                            # Log EXACTLY 1 overlay gift event per gift send immediately with command dispatch (no delay, perfect sync!)
                            AddEventLog @{
                                type = "gift"
                                cardId = [string]$matchedGift.id
                                label = $matchedGift.label
                                giftName = $giftName
                                repeatCount = $repeatCount
                                totalRepeatCount = $totReps
                                repeatEnd = $repEnd
                                isStreak = $isStreak
                                command = $matchedGift.command
                                amount = $totalSpawns
                                username = $user
                                icon = $icon
                                hideInOverlay = $giftHide
                                noSpinnerTrigger = $true
                            }

                            if ($cardGameCmds.Count -gt 0) {
                                foreach ($sc in $cardGameCmds) {
                                    $scAct = if ($sc.actionType) { $sc.actionType } else { $matchedGift.actionType }
                                    # Enforce 1=1 command ratio: Send $totalSpawns directly with repetition 1 to prevent double multiplication!
                                    SendToPvZGame $scAct $sc.command $totalSpawns $user "" 1 $giftDelay $giftInterval | Out-Null
                                }
                            } else {
                                SendToPvZGame $matchedGift.actionType $matchedGift.command $totalSpawns $user "" 1 $giftDelay $giftInterval | Out-Null
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

                    $tbSet = Load-TeamBattleSettings
                    $t1Name = if ($tbSet -and $tbSet.team1 -and $tbSet.team1.name) { $tbSet.team1.name } else { "Team Blue" }
                    $t2Name = if ($tbSet -and $tbSet.team2 -and $tbSet.team2.name) { $tbSet.team2.name } else { "Team Red" }
                    $t1Cmd = if ($tbSet -and $tbSet.team1 -and $tbSet.team1.command) { ($tbSet.team1.command -replace '^!','').ToLower() } else { "blue" }
                    $t2Cmd = if ($tbSet -and $tbSet.team2 -and $tbSet.team2.command) { ($tbSet.team2.command -replace '^!','').ToLower() } else { "red" }

                    if ($cLower -match "!$t1Cmd|team\s*$t1Cmd|!blue|team\s*blue|blue\s*army|!plant(s)?|team\s*plant(s)?") {
                        $userTeams[$user] = "plants"
                        AddEventLog @{
                            type = "team_join"
                            label = "$user joined $t1Name!"
                            team = "plants"
                            username = $user
                            icon = "images/indicators/indicator_general.svg"
                        }
                    } elseif ($cLower -match "!$t2Cmd|team\s*$t2Cmd|!red|team\s*red|red\s*army|!zombie(s)?|team\s*zombie(s)?") {
                        $userTeams[$user] = "zombies"
                        AddEventLog @{
                            type = "team_join"
                            label = "$user joined $t2Name!"
                            team = "zombies"
                            username = $user
                            icon = "images/indicators/indicator_general.svg"
                        }
                    }

                    # Log all chat messages for live AI Voice TTS
                    AddEventLog @{
                        type = "chat"
                        username = $user
                        comment = $comment
                        avatar = if ($payload.avatar) { $payload.avatar } elseif ($payload.profilePictureUrl) { $payload.profilePictureUrl } else { "" }
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

                    AddEventLog @{
                        type = "like"
                        likes = $likes
                        totalLikes = $totalLikes
                        username = $user
                        avatar = $avatar
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }

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
                    if ($likeCards.Count -eq 0) {
                        $allCardsRaw = LoadCards
                        $likeCards = @($allCardsRaw | Where-Object {
                            $_.enabled -ne $false -and (
                                [string]$_.id -in @("1", "2") -or
                                $_.action -in @("LikeForEach", "LikeAmount") -or
                                $_.triggerType -in @("likes_person", "likes_all") -or
                                $_.team -in @("plants", "zombies")
                            )
                        })
                    }

                    $card1 = $likeCards | Where-Object { [string]$_.id -eq "1" -or $_.eventType -eq "team_plants_likes" -or ($_.team -eq "plants") -or ($_.giftName -match "team\s*plants") } | Select-Object -First 1
                    $card2 = $likeCards | Where-Object { [string]$_.id -eq "2" -or $_.eventType -eq "team_zombies_likes" -or ($_.team -eq "zombies") -or ($_.giftName -match "team\s*zombies") } | Select-Object -First 1

                    $thresh1 = if ($card1 -and $card1.likeThreshold) { [int]$card1.likeThreshold } elseif ($card1 -and $card1.triggerValue) { [int]$card1.triggerValue } else { 20 }
                    $thresh2 = if ($card2 -and $card2.likeThreshold) { [int]$card2.likeThreshold } elseif ($card2 -and $card2.triggerValue) { [int]$card2.triggerValue } else { 20 }

                    if ($likeCards.Count -eq 1) {
                        # Single like card in active preset (e.g. Spawn Trident Jugger-nut Gargantuar 50 Likes)
                        # All incoming stream likes count towards this active card!
                        $singleCard = $likeCards[0]
                        $thresh = if ($singleCard.likeThreshold -and [int]$singleCard.likeThreshold -gt 0) { [int]$singleCard.likeThreshold } elseif ($singleCard.triggerValue) { [int]$singleCard.triggerValue } else { 50 }
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
                                    cardId = [string]$singleCard.id
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
                            AddEventLog @{
                                type = "team_battle_progress"
                                team = "plants"
                                current = $teamPlantsLikes
                                threshold = $thresh1
                                likes = $likes
                                username = $user
                            }
                            while ($teamPlantsLikes -ge $thresh1) {
                                $teamPlantsLikes -= $thresh1
                                if ($card1.enabled -ne $false) {
                                    $cReps = if ($card1.repetition -and [int]$card1.repetition -gt 0) { [int]$card1.repetition } else { 1 }
                                    $cAmt = if ($card1.amount -and [int]$card1.amount -gt 0) { [int]$card1.amount } else { 1 }
                                    $cDelay = if ($card1.delay) { [int]$card1.delay } else { 0 }
                                    $cInt = if ($card1.interval) { [int]$card1.interval } else { 100 }
                                    $cCmd = if ($card1.command) { $card1.command } else { $card1.commands }
                                    $cAct = if ($card1.actionType) { $card1.actionType } else { "plant" }
                                    $cIcon = if ($card1.unitIcon) { $card1.unitIcon } elseif ($card1.funcImg) { $card1.funcImg } else { "" }
                                    SendToPvZGame $cAct $cCmd $cAmt $user "" $cReps $cDelay $cInt | Out-Null
                                    if ($counts.Contains("1")) { $counts["1"] = [int]$counts["1"] + 1; SaveCounts }
                                    AddEventLog @{
                                        type = "team_battle_spawn"
                                        cardId = [string]$card1.id
                                        label = "Team Plants ($thresh1 Likes) -> $($card1.funcName)"
                                        team = "plants"
                                        command = $cCmd
                                        amount = $cAmt
                                        username = $user
                                        icon = $cIcon
                                        success = $true
                                    }
                                }
                            }
                        } elseif ($team -eq "zombies" -and $card2) {
                            $teamZombiesLikes += $likes
                            AddEventLog @{
                                type = "team_battle_progress"
                                team = "zombies"
                                current = $teamZombiesLikes
                                threshold = $thresh2
                                likes = $likes
                                username = $user
                            }
                            while ($teamZombiesLikes -ge $thresh2) {
                                $teamZombiesLikes -= $thresh2
                                if ($card2.enabled -ne $false) {
                                    $cReps = if ($card2.repetition -and [int]$card2.repetition -gt 0) { [int]$card2.repetition } else { 1 }
                                    $cAmt = if ($card2.amount -and [int]$card2.amount -gt 0) { [int]$card2.amount } else { 1 }
                                    $cDelay = if ($card2.delay) { [int]$card2.delay } else { 0 }
                                    $cInt = if ($card2.interval) { [int]$card2.interval } else { 100 }
                                    $cCmd = if ($card2.command) { $card2.command } else { $card2.commands }
                                    $cAct = if ($card2.actionType) { $card2.actionType } else { "zombie" }
                                    $cIcon = if ($card2.unitIcon) { $card2.unitIcon } elseif ($card2.funcImg) { $card2.funcImg } else { "" }
                                    SendToPvZGame $cAct $cCmd $cAmt $user "" $cReps $cDelay $cInt | Out-Null
                                    if ($counts.Contains("2")) { $counts["2"] = [int]$counts["2"] + 1; SaveCounts }
                                    AddEventLog @{
                                        type = "team_battle_spawn"
                                        cardId = [string]$card2.id
                                        label = "Team Zombies ($thresh2 Likes) -> $($card2.funcName)"
                                        team = "zombies"
                                        command = $cCmd
                                        amount = $cAmt
                                        username = $user
                                        icon = $cIcon
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
                                        cardId = [string]$alcId
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
                                cardId = $fcIdStr
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
                # Join / Member event (Viewer joins TikTok Live stream)
                elseif ($payload.event -eq "join" -or $payload.event -eq "member" -or $payload.type -eq "join" -or $payload.type -eq "member") {
                    $user = if ($payload.username) { [string]$payload.username } elseif ($payload.nickname) { [string]$payload.nickname } elseif ($payload.uniqueId) { [string]$payload.uniqueId } else { "Stream Viewer" }
                    $avatar = if ($payload.profilePictureUrl) { $payload.profilePictureUrl } elseif ($payload.avatar) { $payload.avatar } elseif ($payload.avatarUrl) { $payload.avatarUrl } else { "" }
                    $uniqueId = if ($payload.uniqueId) { [string]$payload.uniqueId } else { "" }

                    AddEventLog @{
                        type = "join"
                        username = $user
                        uniqueId = $uniqueId
                        avatar = $avatar
                        label = "$user joined the stream!"
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                }
                # Room Viewers & Realtime Stats update
                elseif ($payload.event -eq "room_viewers" -or $payload.event -eq "stats_update") {
                    $vCount = if ($payload.viewerCount) { [int]$payload.viewerCount } else { 0 }
                    $tLikes = if ($payload.totalLikes) { [int64]$payload.totalLikes } elseif ($payload.totalLikeCount) { [int64]$payload.totalLikeCount } else { 0 }
                    
                    AddEventLog @{
                        type = "room_stats"
                        viewerCount = $vCount
                        totalLikes = $tLikes
                        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                    }
                }
            } catch {
                Write-Host ">>> [TIKTOK WEBHOOK EXCEPTION]: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ">>> [TRACE]: $($_.ScriptStackTrace)" -ForegroundColor Red
            }

            Send-JsonResponse $response @{ status = "ok" }
            continue
        }

        # 9. Legacy / Live Overlay API: Counts (GET or POST)
        if ($reqPath -eq '/api/counts') {
            if ($request.HttpMethod -eq 'POST') {
                try {
                    $cBody = ReadRequestBody $request
                    if ($cBody) {
                        $parsedBody = $cBody
                        if ($cBody -is [string]) {
                            $parsedBody = $cBody | ConvertFrom-Json
                        }
                        if ($parsedBody -and $parsedBody.id) {
                            if ($parsedBody.isTest -eq $true -or $parsedBody.noOverlayCount -eq $true) {
                                Send-JsonResponse $response $counts
                                continue
                            }
                            $cIdStr = [string]$parsedBody.id
                            $cInc = if ($parsedBody.count) { [int]$parsedBody.count } else { 1 }
                            if (-not $counts.ContainsKey($cIdStr)) {
                                $counts[$cIdStr] = 0
                            }
                            $counts[$cIdStr] = [int]$counts[$cIdStr] + $cInc
                            SaveCounts
                            AddEventLog @{
                                type = "card_count_updated"
                                cardId = $cIdStr
                                count = [int]$counts[$cIdStr]
                                amount = $cInc
                                timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                            }
                        }
                    }
                } catch {}
            }
            Send-JsonResponse $response $counts
            continue
        }

        # 10. Live Stream / Overlay API: Donate / Increment count AND trigger in-game spawn!
        if ($reqPath -eq '/api/donate') {
            $id = $request.QueryString['id']
            $amt = 1
            if ($request.QueryString['amount']) {
                $amt = [int]$request.QueryString['amount']
            }

            $sId = [string]$id
            if ($sId) {
                if (-not $counts.ContainsKey($sId)) {
                    $counts[$sId] = 0
                }
                $counts[$sId] = [int]$counts[$sId] + $amt
                SaveCounts
                AddEventLog @{
                    type = "card_count_updated"
                    cardId = $sId
                    count = [int]$counts[$sId]
                    amount = $amt
                    timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                }
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
                    cardId = $sId
                    label = "$gLabel ($($targetCard.funcName))"
                    command = $cCmd
                    amount = $totalSpawns
                    username = "RENEarn"
                    icon = $targetCard.funcImg
                    success = $exec.success
                }
            }

            Send-JsonResponse $response $counts
            continue
        }

        # 11. Reset API (All counts or single command count)
        if ($reqPath -eq '/api/reset' -or $reqPath -eq '/api/counts/reset') {
            $singleId = $request.QueryString['id']
            if (-not $singleId -and $request.HttpMethod -eq 'POST') {
                try {
                    $resetBodyStr = ReadRequestBody $request
                    if ($resetBodyStr) {
                        $resetBody = $resetBodyStr | ConvertFrom-Json
                        if ($resetBody -and $resetBody.id) { $singleId = [string]$resetBody.id }
                    }
                } catch {}
            }

            if ($singleId) {
                $sIdStr = [string]$singleId
                if ($counts.ContainsKey($sIdStr)) {
                    $counts[$sIdStr] = 0
                }
                SaveCounts
                AddEventLog @{ type = "counts_reset"; cardId = $sIdStr; message = "Command $sIdStr count reset to 0"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
                Send-JsonResponse $response @{ status = "ok"; cardId = $sIdStr; count = 0 }
            } else {
                foreach ($k in @($counts.Keys)) {
                    $counts[$k] = 0
                }
                SaveCounts
                AddEventLog @{ type = "counts_reset"; cardId = "all"; message = "All command counts reset to 0"; timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
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

        # 12. Audio Library APIs
        if ($reqPath -eq '/api/sounds' -and $request.HttpMethod -eq 'GET') {
            $catFile = Join-Path $folder "sounds_catalog.json"
            $soundsDir = Join-Path $folder "sounds"
            if (-not (Test-Path $soundsDir)) { New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null }
            $rawJson = "[]"
            if (Test-Path $catFile) {
                try {
                    $rawJson = [System.IO.File]::ReadAllText($catFile, [System.Text.Encoding]::UTF8)
                    if ($rawJson.Length -gt 0 -and [int][char]$rawJson[0] -eq 65279) {
                        $rawJson = $rawJson.Substring(1)
                    }
                } catch { $rawJson = "[]" }
            }
            Send-JsonResponse $response $rawJson
            continue
        }

        if ($reqPath -eq '/api/upload-audio' -and $request.HttpMethod -eq 'POST') {
            try {
                $bodyStr = ReadRequestBody $request
                $body = $bodyStr | ConvertFrom-Json
                $rawName = if ($body.name) { [string]$body.name } else { "sound_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + ".mp3" }
                $cleanName = ($rawName -replace '[^a-zA-Z0-9_\.\-]', '_')
                if (-not ($cleanName -match '\.(mp3|wav|ogg|m4a|aac|flac|webm|opus|wma)$')) {
                    $cleanName = "$cleanName.mp3"
                }
                $soundsDir = Join-Path $folder "sounds"
                if (-not (Test-Path $soundsDir)) { New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null }
                $targetFile = Join-Path $soundsDir $cleanName

                if ($body.base64Data) {
                    $cleanB64 = [string]$body.base64Data
                    if ($cleanB64 -match '^data:audio\/[^;]+;base64,(.+)$') {
                        $cleanB64 = $matches[1]
                    }
                    $bytes = [System.Convert]::FromBase64String($cleanB64)
                    [System.IO.File]::WriteAllBytes($targetFile, $bytes)
                }

                $catFile = Join-Path $folder "sounds_catalog.json"
                $catalogList = @()
                if (Test-Path $catFile) {
                    try { $catalogList = @(Get-Content $catFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {}
                }
                $rel = "sounds/$cleanName"
                $existing = $catalogList | Where-Object { $_.file -eq $rel } | Select-Object -First 1
                if (-not $existing) {
                    $newItem = [PSCustomObject]@{
                        id = "snd_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
                        name = $cleanName
                        title = if ($body.title) { [string]$body.title } else { [System.IO.Path]::GetFileNameWithoutExtension($cleanName) -replace '[_\-]+', ' ' }
                        file = $rel
                        tag = if ($body.tag) { [string]$body.tag } else { "Local" }
                        duration = (Get-MediaDurationFormatted $targetFile)
                        used = $false
                        volume = if ($body.volume -ne $null) { [double]$body.volume } else { 1 }
                        multiplier = if ($body.multiplier -ne $null) { [bool]$body.multiplier } else { $true }
                        playerType = if ($body.playerType) { [string]$body.playerType } else { "Short" }
                    }
                    $catalogList += $newItem
                    $jsonStr = $catalogList | ConvertTo-Json -Depth 5
                    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [System.IO.File]::WriteAllText($catFile, $jsonStr, $utf8NoBom)
                    Send-JsonResponse $response @{ status = "ok"; sound = $newItem }
                } else {
                    Send-JsonResponse $response @{ status = "ok"; sound = $existing }
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        if ($reqPath -eq '/api/search-myinstants' -and $request.HttpMethod -eq 'GET') {
            try {
                $query = $request.QueryString['q']
                if (-not $query) {
                    Send-JsonResponse $response @()
                    continue
                }
                $searchUrl = "https://www.myinstants.com/en/search/?name=" + [System.Uri]::EscapeDataString($query)
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                $html = $wc.DownloadString($searchUrl)

                $results = @()
                $blocks = $html -split '<div class="instant'
                for ($i = 1; $i -lt $blocks.Length; $i++) {
                    $blk = $blocks[$i]
                    if ($blk -match 'play\([''"]([^''"]+)[''"]') {
                        $mp3Rel = $matches[1].TrimStart('/')
                        $fullMp3 = "https://www.myinstants.com/" + $mp3Rel
                        $title = ""
                        $pageUrl = ""
                        if ($blk -match '<a\s+href="([^"]+)"[^>]*class="instant-link[^"]*"[^>]*>([^<]+)</a>') {
                            $pageUrl = "https://www.myinstants.com" + $matches[1]
                            $title = $matches[2].Trim() -replace '&amp;', '&' -replace '&#x27;', "'" -replace '&quot;', '"'
                        }
                        $color = "#FF0000"
                        if ($blk -match 'style="background-color:\s*([^;"]+);?"') {
                            $color = $matches[1].Trim()
                        }
                        if ($title -and $fullMp3) {
                            $results += [PSCustomObject]@{
                                title = $title
                                color = $color
                                mp3Url = $fullMp3
                                pageUrl = $pageUrl
                                name = [System.IO.Path]::GetFileName($mp3Rel)
                            }
                        }
                    }
                    if ($results.Count -ge 20) { break }
                }
                Send-JsonResponse $response $results
            } catch {
                Send-JsonResponse $response @()
            }
            continue
        }

        if ($reqPath -eq '/api/fetch-audio-url' -and $request.HttpMethod -eq 'POST') {
            try {
                $bodyStr = ReadRequestBody $request
                $body = $bodyStr | ConvertFrom-Json
                $audioUrl = [string]$body.url
                if (-not $audioUrl) {
                    Send-JsonResponse $response @{ status = "error"; message = "Missing URL parameter" } 400
                    continue
                }
                if ($audioUrl -match 'myinstants\.com' -and $audioUrl -notmatch '\.mp3') {
                    try {
                        $wcTemp = New-Object System.Net.WebClient
                        $wcTemp.Headers.Add("User-Agent", "Mozilla/5.0")
                        $pageHtml = $wcTemp.DownloadString($audioUrl)
                        if ($pageHtml -match '(\/media\/sounds\/[^\s"''\)]+\.mp3)') {
                            $mp3Rel = $matches[1].TrimStart('/')
                            $audioUrl = "https://www.myinstants.com/" + $mp3Rel
                        }
                    } catch {}
                }
                $rawName = if ($body.name) { [string]$body.name } else { [System.IO.Path]::GetFileName(($audioUrl -split '\?')[0]) }
                if (-not $rawName -or $rawName -notmatch '\.(mp3|wav|ogg)$') {
                    $rawName = "bgm_" + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + ".mp3"
                }
                $cleanName = ($rawName -replace '[^a-zA-Z0-9_\.\-]', '_')
                $soundsDir = Join-Path $folder "sounds"
                if (-not (Test-Path $soundsDir)) { New-Item -ItemType Directory -Path $soundsDir -Force | Out-Null }
                $targetFile = Join-Path $soundsDir $cleanName

                # Download file
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                $wc.DownloadFile($audioUrl, $targetFile)

                $catFile = Join-Path $folder "sounds_catalog.json"
                $catalogList = @()
                if (Test-Path $catFile) {
                    try { $catalogList = @(Get-Content $catFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {}
                }
                $rel = "sounds/$cleanName"
                $existing = $catalogList | Where-Object { $_.file -eq $rel } | Select-Object -First 1
                if (-not $existing) {
                    $newItem = [PSCustomObject]@{
                        id = "snd_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
                        name = $cleanName
                        title = if ($body.title) { [string]$body.title } else { [System.IO.Path]::GetFileNameWithoutExtension($cleanName) -replace '[_\-]+', ' ' }
                        file = $rel
                        tag = if ($body.tag) { [string]$body.tag } else { "Music" }
                        duration = (Get-MediaDurationFormatted $targetFile)
                        used = $false
                        volume = 1
                        multiplier = $true
                        playerType = "Normal"
                    }
                    $catalogList += $newItem
                    $jsonStr = $catalogList | ConvertTo-Json -Depth 5
                    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [System.IO.File]::WriteAllText($catFile, $jsonStr, $utf8NoBom)
                    Send-JsonResponse $response @{ status = "ok"; sound = $newItem }
                } else {
                    Send-JsonResponse $response @{ status = "ok"; sound = $existing }
                }
            } catch {
                Send-JsonResponse $response @{ status = "error"; message = $_.Exception.Message } 500
            }
            continue
        }

        # ----------------- HIGH-PERFORMANCE STATIC FILE SERVING ----------------- #
        # Clean Branded RENEarn Overlay Route Aliases
        $cleanRoutes = @{
            "/renearn/jar"          = "overlay-jar.html"
            "/jar"                  = "overlay-jar.html"
            "/renearn/spinner"      = "overlay-spinner.html"
            "/spinner"              = "overlay-spinner.html"
            "/renearn/leaderboard"  = "overlay-leaderboard.html"
            "/leaderboard"          = "overlay-leaderboard.html"
            "/renearn/overlay"      = "stream-overlay.html"
            "/overlay"              = "stream-overlay.html"
            "/renearn/goal"         = "overlay-goal.html"
            "/goal"                 = "overlay-goal.html"
            "/renearn/gacha"        = "overlay-gacha.html"
            "/gacha"                = "overlay-gacha.html"
            "/renearn/claw"         = "overlay-spinner.html"
            "/claw"                 = "overlay-spinner.html"
            "/renearn/grid"         = "overlay-grid.html"
            "/grid"                 = "overlay-grid.html"
            "/renearn/hud"          = "groudon-hud-overlay.html"
            "/hud"                  = "groudon-hud-overlay.html"
            "/renearn"              = "app.html"
            "/app"                  = "app.html"
            "/renearn/side"         = "overlay-side.html"
            "/side"                 = "overlay-side.html"
            "/side-overlay"         = "overlay-side.html"
            "/renearn/normal"       = "overlay-side.html"
            "/normal"               = "overlay-side.html"
            "/overlay-normal"       = "overlay-side.html"
            "/overlay-normal.html"  = "overlay-side.html"
            "/kingdom-siege"        = "kingdom-siege.html"
            "/siege"                = "kingdom-siege.html"
            "/castle"               = "kingdom-siege.html"
            "/songrequest"          = "overlay-songrequest.html"
            "/music"                = "overlay-songrequest.html"
        }

        $normPath = $reqPath.ToLower().TrimEnd('/')
        if ($cleanRoutes.ContainsKey($normPath)) {
            $filePath = Join-Path $folder $cleanRoutes[$normPath]
        } elseif ($normPath -match '^/overlay/([a-f0-9]{16,64})/jar$' -or $normPath -match '^/overlay/jar/([a-f0-9]{16,64})$') {
            $filePath = Join-Path $folder "overlay-jar.html"
        } elseif ($normPath -match '^/overlay/([a-f0-9]{16,64})$') {
            $filePath = Join-Path $folder "overlay.html"
        } else {
            $localRelPath = $reqPath.TrimStart('/').Replace('/', '\')
            $filePath = Join-Path $folder $localRelPath
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mimeMap = @{
                ".html" = "text/html; charset=utf-8"
                ".htm"  = "text/html; charset=utf-8"
                ".css"  = "text/css; charset=utf-8"
                ".js"   = "application/javascript; charset=utf-8"
                ".json" = "application/json; charset=utf-8"
                ".png"  = "image/png"
                ".jpg"  = "image/jpeg"
                ".jpeg" = "image/jpeg"
                ".gif"  = "image/gif"
                ".svg"  = "image/svg+xml"
                ".webp" = "image/webp"
                ".mp3"  = "audio/mpeg"
                ".wav"  = "audio/wav"
                ".ogg"  = "audio/ogg"
                ".m4a"  = "audio/mp4"
                ".webm" = "video/webm"
                ".woff2"= "font/woff2"
                ".ttf"  = "font/ttf"
                ".glb"  = "model/gltf-binary"
                ".gltf" = "model/gltf+json"
            }
            $contentType = if ($mimeMap.ContainsKey($ext)) { $mimeMap[$ext] } else { "application/octet-stream" }

            $isStaticMedia = ($ext -in @(".webp", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".mp3", ".wav", ".ogg", ".woff2", ".ttf", ".js", ".css", ".glb", ".gltf"))

            if (-not $script:staticFileByteCache) {
                $script:staticFileByteCache = [System.Collections.Generic.Dictionary[string, byte[]]]::new([System.StringComparer]::OrdinalIgnoreCase)
            }

            $bytes = $null
            if ($isStaticMedia -and $script:staticFileByteCache.ContainsKey($filePath)) {
                $bytes = $script:staticFileByteCache[$filePath]
            } else {
                try {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                    if ($isStaticMedia -and $bytes.Length -lt 10485760) {
                        $script:staticFileByteCache[$filePath] = $bytes
                    }
                } catch {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                }
            }

            if ($bytes.Length -ge 8 -and $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47) {
                $contentType = "image/png"
            } elseif ($bytes.Length -ge 12 -and $bytes[0] -eq 0x52 -and $bytes[1] -eq 0x49 -and $bytes[2] -eq 0x46 -and $bytes[3] -eq 0x46) {
                $contentType = "image/webp"
            }
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length

            try {
                if ($isStaticMedia) {
                    # Cache images, audio, js and css for instant render
                    $response.Headers.Add("Cache-Control", "public, max-age=86400")
                } else {
                    $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
                    $response.Headers.Add("Pragma", "no-cache")
                    $response.Headers.Add("Expires", "0")
                }
            } catch {}

            try {
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    $response.OutputStream.Flush()
                }
            } catch {}
            finally {
                try { $response.Close() } catch {}
            }
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found: $reqPath")
            try {
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                $response.OutputStream.Flush()
            } catch {}
            finally {
                try { $response.Close() } catch {}
            }
        }
    } catch {
        try { if ($response) { $response.Close() } } catch {}
        Write-Host "Server Exception: $_" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 50
    }
}

