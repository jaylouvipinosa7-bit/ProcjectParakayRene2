# add_hybrid_album_preset.ps1
# Implements full Game Album & Preset support for PvZ: Hybrid Edition (and PvZ Classic) in RENEarn Studio

$coreDir = "c:\Users\pc\Downloads\ano na\core"
$appHtmlPath = Join-Path $coreDir "app.html"
$s2ePresetsPath = Join-Path $coreDir "s2e_presets.json"

Write-Host "1. Updating core/s2e_presets.json with official hybrid presets..."
$presetsJson = Get-Content -Path $s2ePresetsPath -Raw -Encoding UTF8
$presetsObj = $presetsJson | ConvertFrom-Json

if (-not $presetsObj.preset_pvz_hybrid) {
    $hybridPreset = [ordered]@{
        "_id" = "preset_pvz_hybrid"
        "id" = "preset_pvz_hybrid"
        "name" = "PvZ: Hybrid Edition Official"
        "game" = "pvz_hybrid"
        "createdAt" = "10/23/2026"
        "coverIcon" = "images/games/pvz_hybrid_poster.jpg"
        "eventsCount" = 6
        "events" = @(
            [ordered]@{
                "id" = "hyb_1"
                "giftName" = "Team plants likes"
                "coins" = 0
                "label" = "Spawn Hybrid Peashooter (1)"
                "actionType" = "plant"
                "icon" = "images/tiktok-gifts/5655_rose.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_gatling_pea.webp"
                "command" = "spawn_hybrid_pea"
                "repetition" = 1
                "triggerType" = "like"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_gatling_pea.webp"
                "funcName" = "Spawn Hybrid Peashooter (1)"
            },
            [ordered]@{
                "id" = "hyb_2"
                "giftName" = "Team zombies likes"
                "coins" = 0
                "label" = "Spawn Hybrid Conehead Zombie"
                "actionType" = "zombie"
                "icon" = "images/tiktok-gifts/5655_rose.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_knight_captain.webp"
                "command" = "spawn_hybrid_cone"
                "repetition" = 1
                "triggerType" = "like"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_knight_captain.webp"
                "funcName" = "Spawn Hybrid Conehead Zombie"
            },
            [ordered]@{
                "id" = "hyb_3"
                "giftName" = "Rose (1 Coin)"
                "coins" = 1
                "label" = "Spawn Hybrid Cattail"
                "actionType" = "plant"
                "icon" = "images/tiktok-gifts/5655_rose.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_ultimatecattail.webp"
                "command" = "spawn_hybrid_cattail"
                "repetition" = 1
                "triggerType" = "gift"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_ultimatecattail.webp"
                "funcName" = "Spawn Hybrid Cattail"
            },
            [ordered]@{
                "id" = "hyb_4"
                "giftName" = "Ice Cream (20 Coins)"
                "coins" = 20
                "label" = "Spawn Hybrid Gargantuar"
                "actionType" = "zombie"
                "icon" = "images/tiktok-gifts/5827_icecream.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                "command" = "spawn_hybrid_gargantuar"
                "repetition" = 1
                "triggerType" = "gift"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                "funcName" = "Spawn Hybrid Gargantuar"
            },
            [ordered]@{
                "id" = "hyb_5"
                "giftName" = "Gaming Chair (99 Coins)"
                "coins" = 99
                "label" = "Spawn Ultimate Mecha"
                "actionType" = "zombie"
                "icon" = "images/tiktok-gifts/5827_icecream.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_ultimatehorse.webp"
                "command" = "spawn_hybrid_mecha"
                "repetition" = 1
                "triggerType" = "gift"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_ultimatehorse.webp"
                "funcName" = "Spawn Ultimate Mecha"
            },
            [ordered]@{
                "id" = "hyb_6"
                "giftName" = "Leon the Kitten (488 Coins)"
                "coins" = 488
                "label" = "Super Hybrid Boss Wave"
                "actionType" = "zombie"
                "icon" = "images/tiktok-gifts/5827_icecream.webp"
                "unitIcon" = "images/game-icons/pvz/spawn_supergargantuar.webp"
                "command" = "spawn_hybrid_boss_wave"
                "repetition" = 1
                "triggerType" = "gift"
                "targetGame" = "pvz_hybrid"
                "funcImg" = "images/game-icons/pvz/spawn_supergargantuar.webp"
                "funcName" = "Super Hybrid Boss Wave"
            }
        )
    }
    $presetsObj | Add-Member -NotePropertyName "preset_pvz_hybrid" -NotePropertyValue $hybridPreset
    $updatedPresetsJson = $presetsObj | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($s2ePresetsPath, $updatedPresetsJson, $utf8NoBom)
    Write-Host "Added preset_pvz_hybrid to s2e_presets.json"
} else {
    Write-Host "preset_pvz_hybrid already exists in s2e_presets.json"
}

Write-Host "2. Reading core/app.html..."
$html = [System.IO.File]::ReadAllText($appHtmlPath, [System.Text.Encoding]::UTF8)

# A. Add "Game Albums" to Sidebar Navigation right before Presets
$oldNavTarget = '                    <!-- 5. PRESETS TAB (CUSTOM 3D HOLOGRAPHIC PRESET DECK ICON) -->'
$newNavContent = @'
                    <!-- 4.5 GAME ALBUMS TAB -->
                    <button type="button" class="sidebar-nav-item tab-btn" data-tab="album" id="sideBtnAlbum"
                        onclick="switchTab('album')">
                        <div class="nav-item-left">
                            <span class="nav-icon" style="font-size: 18px;" title="Game Albums Library">💿</span>
                            <span class="nav-text">Game Albums</span>
                        </div>
                        <span class="nav-badge nav-badge-live" style="background: rgba(56,189,248,0.2); color: #38bdf8; border: 1px solid rgba(56,189,248,0.4); font-weight: 800;">3D</span>
                    </button>

                    <!-- 5. PRESETS TAB (CUSTOM 3D HOLOGRAPHIC PRESET DECK ICON) -->
'@

if ($html.Contains($oldNavTarget) -and -not $html.Contains('id="sideBtnAlbum"')) {
    $html = $html.Replace($oldNavTarget, $newNavContent)
    Write-Host "Added Game Albums sidebar navigation item."
}

# B. Add "PvZ: Hybrid Edition" to album-selection-strip
$oldPillTarget = '<button type="button" class="album-select-pill active" id="albumPillPvZFusion"'
$newPillContent = @'
<button type="button" class="album-select-pill" id="albumPillpvz_hybrid"
                            onclick="selectGameAlbum('pvz_hybrid')"
                            style="background: rgba(56, 189, 248, 0.15); border: 1.5px solid #38bdf8; color: #7dd3fc; border-radius: 999px; padding: 6px 14px; font-size: 12px; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 6px; white-space: nowrap;">
                            <span style="width: 8px; height: 8px; border-radius: 50%; background: #38bdf8; box-shadow: 0 0 6px #38bdf8;"></span>
                            🧬 PvZ: Hybrid Edition (杂交版)
                        </button>
                        <button type="button" class="album-select-pill active" id="albumPillPvZFusion"
'@

if ($html.Contains($oldPillTarget) -and -not $html.Contains('id="albumPillpvz_hybrid"')) {
    $html = $html.Replace($oldPillTarget, $newPillContent)
    Write-Host "Added PvZ: Hybrid Edition to album-selection-strip."
}

# C. Add "PvZ: Hybrid Edition" 3D Album Card to pvzGameAlbumsGrid
$oldGridTarget = '                        <div class="pvz-game-albums-grid" id="pvzGameAlbumsGrid">'
$newGridContent = @'
                        <div class="pvz-game-albums-grid" id="pvzGameAlbumsGrid">
                            <!-- Game 0: PvZ: Hybrid Edition (杂交版) -->
                            <div class="pvz-game-album-card" id="albumCardpvz_hybrid"
                                onclick="selectGameAlbum('pvz_hybrid', true)"
                                title="Click to choose presets for PvZ: Hybrid Edition">
                                <div class="album-card-cover-wrap">
                                    <img src="images/games/pvz_hybrid_poster.jpg"
                                        onerror="this.src='images/pvz_fusion_cover.jpg'" class="album-card-cover"
                                        alt="PvZ Hybrid Edition">
                                    <div class="album-card-overlay-tag">READY</div>
                                </div>
                                <div class="album-card-body">
                                    <div class="album-card-title">PvZ: Hybrid Edition (杂交版)</div>
                                    <div class="album-card-engine">🧬 Hybrid Mod & Memory Link</div>
                                    <div class="album-card-footer">
                                        <span class="album-card-presets-badge">🎁 100+ Hybrids</span>
                                        <button type="button" class="album-card-action-btn"
                                            onclick="event.stopPropagation(); openPvzPresetModal('pvz_hybrid')">Choose Presets</button>
                                    </div>
                                </div>
                            </div>
'@

if ($html.Contains($oldGridTarget) -and -not $html.Contains('id="albumCardpvz_hybrid"')) {
    $html = $html.Replace($oldGridTarget, $newGridContent)
    Write-Host "Added PvZ: Hybrid Edition 3D album card."
}

# D. Add "PvZ: Hybrid Edition" to myPresetsGameSelect
$oldGameSelectTarget = '<option value="PvZFusion">PvZFusion</option>'
$newGameSelectContent = @'
<option value="PvZFusion">PvZFusion</option>
                                <option value="pvz_hybrid">PvZ: Hybrid Edition (杂交版)</option>
                                <option value="pvz_classic">PvZ: Classic / GOTY</option>
'@

if ($html.Contains($oldGameSelectTarget) -and -not $html.Contains('value="pvz_hybrid"')) {
    $html = $html.Replace($oldGameSelectTarget, $newGameSelectContent)
    Write-Host "Added PvZ: Hybrid Edition to myPresetsGameSelect."
}

# E. Add "PvZ: Hybrid Edition" to Create New Preset Modal game dropdown
$oldModalGameTarget = '<option value="PvZFusion">Plants vs Zombies Fusion</option>'
$newModalGameContent = @'
<option value="PvZFusion">Plants vs Zombies Fusion</option>
                                    <option value="pvz_hybrid">Plants vs Zombies: Hybrid Edition (杂交版)</option>
                                    <option value="pvz_classic">Plants vs Zombies: Classic / GOTY</option>
'@

if ($html.Contains($oldModalGameTarget)) {
    # Check if already added
    if (-not $html.Contains('value="pvz_hybrid">Plants vs Zombies: Hybrid Edition')) {
        $html = $html.Replace($oldModalGameTarget, $newModalGameContent)
        Write-Host "Added PvZ: Hybrid Edition to presetInputGame modal dropdown."
    }
}

# F. Add Cover option in presetInputCover
$oldCoverTarget = '<option value="images/pvz_fusion_cover.jpg">PvZ Fusion Official Album Poster'
$newCoverContent = @'
<option value="images/games/pvz_hybrid_poster.jpg">PvZ: Hybrid Edition Poster (Recommended for Hybrid)</option>
                                    <option value="images/pvz_fusion_cover.jpg">PvZ Fusion Official Album Poster
'@

if ($html.Contains($oldCoverTarget) -and -not $html.Contains('images/games/pvz_hybrid_poster.jpg')) {
    $html = $html.Replace($oldCoverTarget, $newCoverContent)
    Write-Host "Added PvZ: Hybrid Edition Poster to presetInputCover."
}

# G. Update gameAlbumsCatalog in JS to include pvz_hybrid & pvz_classic
$oldCatalogTarget = "const gameAlbumsCatalog = {"
$newCatalogContent = @'
const gameAlbumsCatalog = {
                    'pvz_hybrid': {
                        name: 'Plants vs. Zombies: Hybrid Edition (杂交版)',
                        poster: 'images/games/pvz_hybrid_poster.jpg',
                        port: 'Hybrid Memory Link Active',
                        exe: 'PlantsVsZombies.exe',
                        catalog: '100+ Hybrid Plants & Mutant Zombies',
                        desc: 'Official interactive live streaming game album for Plants vs. Zombies: Hybrid Edition (杂交版). Viewers send gifts to spawn hybrid plants and mutant boss zombies in real time.'
                    },
                    'pvz_classic': {
                        name: 'Plants vs. Zombies: Original / GOTY',
                        poster: 'images/games/pvz_classic_poster.jpg',
                        port: 'Classic PvZ1 Memory Hook Active',
                        exe: 'popcapgame1.exe',
                        catalog: 'Original PvZ1 Plants & Classic Zombies',
                        desc: 'Classic Plants vs. Zombies live streaming game engine. Direct viewer gift triggers to spawn classic zombies, waves, and sun drop aids.'
                    },
'@

if ($html.Contains($oldCatalogTarget) -and -not $html.Contains("'pvz_hybrid': {")) {
    $html = $html.Replace($oldCatalogTarget, $newCatalogContent)
    Write-Host "Added pvz_hybrid and pvz_classic to gameAlbumsCatalog."
}

# H. Update GAME_INFO_MAP in JS to include pvz_hybrid & pvz_classic
$oldGameInfoTarget = "const GAME_INFO_MAP = {"
$newGameInfoContent = @'
const GAME_INFO_MAP = {
                    'pvz_hybrid': {
                        name: 'PvZ: Hybrid Edition (杂交版)',
                        tag: 'Hybrid Mod PC',
                        color: '#38bdf8',
                        border: 'rgba(56,189,248,0.3)',
                        bg: 'rgba(56,189,248,0.12)',
                        engine: 'Hybrid Mod Engine & Memory Link',
                        desc: 'Official interactive live stream template for Plants vs. Zombies: Hybrid Edition (杂交版). Real-time hybrid plants and mutant boss zombies spawned live via TikTok stream gifts.',
                        defaultCover: 'images/games/pvz_hybrid_poster.jpg',
                        fallbackIcon: 'images/games/pvz_hybrid_poster.jpg',
                        sampleTriggers: [
                            { id: "hyb1", giftName: "Team plants likes", coins: 0, label: "Spawn Hybrid Peashooter", actionType: "plant", unitIcon: "images/game-icons/pvz/spawn_gatling_pea.webp", command: "spawn_hybrid_pea" },
                            { id: "hyb2", giftName: "Team zombies likes", coins: 0, label: "Spawn Hybrid Conehead", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_knight_captain.webp", command: "spawn_hybrid_cone" },
                            { id: "hyb3", giftName: "Rose (1 Coin)", coins: 1, label: "Spawn Hybrid Cattail", actionType: "plant", unitIcon: "images/game-icons/pvz/spawn_ultimatecattail.webp", command: "spawn_hybrid_cattail" },
                            { id: "hyb4", giftName: "Ice Cream (20 Coins)", coins: 20, label: "Spawn Hybrid Gargantuar", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp", command: "spawn_hybrid_gargantuar" },
                            { id: "hyb5", giftName: "Gaming Chair (99 Coins)", coins: 99, label: "Spawn Ultimate Mecha", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_ultimatehorse.webp", command: "spawn_hybrid_mecha" },
                            { id: "hyb6", giftName: "Leon the Kitten (488 Coins)", coins: 488, label: "Super Hybrid Boss Wave", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_supergargantuar.webp", command: "spawn_hybrid_boss_wave" }
                        ],
                        catLabels: { plant: '🌿 Hybrid Plants', zombie: '🧟 Hybrid Zombies', special: '⚡ Mutant Powers' }
                    },
                    'pvz_classic': {
                        name: 'PvZ: Classic / GOTY',
                        tag: 'Classic PvZ1',
                        color: '#eab308',
                        border: 'rgba(234,179,8,0.3)',
                        bg: 'rgba(234,179,8,0.12)',
                        engine: 'Classic Memory Link & Direct Injection',
                        desc: 'Official interactive stream template for Plants vs. Zombies: Original / GOTY Edition. Classic zombies, football zombies, jack-in-the-box, and gargantuars spawned by TikTok stream gifts.',
                        defaultCover: 'images/games/pvz_classic_poster.jpg',
                        fallbackIcon: 'images/games/pvz_classic_poster.jpg',
                        sampleTriggers: [
                            { id: "cls1", giftName: "Rose (1 Coin)", coins: 1, label: "Spawn Conehead Zombie", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_gatling_pea.webp", command: "spawn_conehead" },
                            { id: "cls2", giftName: "Ice Cream (20 Coins)", coins: 20, label: "Spawn Buckethead Zombie", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_knight_captain.webp", command: "spawn_buckethead" },
                            { id: "cls3", giftName: "Doughnut (30 Coins)", coins: 30, label: "Spawn Football Zombie", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_ultimatehorse.webp", command: "spawn_football" },
                            { id: "cls4", giftName: "Lion (488 Coins)", coins: 488, label: "Classic Gargantuar Wave", actionType: "zombie", unitIcon: "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp", command: "spawn_classic_gargantuar" }
                        ],
                        catLabels: { plant: '🌻 Plants', zombie: '🧟 Zombies', special: '⚡ Powerups' }
                    },
'@

if ($html.Contains($oldGameInfoTarget) -and -not $html.Contains("'pvz_hybrid': {")) {
    $html = $html.Replace($oldGameInfoTarget, $newGameInfoContent)
    Write-Host "Added pvz_hybrid and pvz_classic to GAME_INFO_MAP."
}

# I. Update normalizeGameKey
$oldNormalize = @'
                function normalizeGameKey(rawGame) {
                    if (!rawGame) return 'PvZFusion';
                    const g = rawGame.trim().toLowerCase();
                    if (g.includes('pvz') || g.includes('fusion') || g.includes('plant')) return 'PvZFusion';
'@

$newNormalize = @'
                function normalizeGameKey(rawGame) {
                    if (!rawGame) return 'PvZFusion';
                    const g = rawGame.trim().toLowerCase();
                    if (g.includes('hybrid')) return 'pvz_hybrid';
                    if (g.includes('classic') || g.includes('goty')) return 'pvz_classic';
                    if (g.includes('tsunami')) return 'zombie_tsunami';
                    if (g.includes('pvz') || g.includes('fusion') || g.includes('plant')) return 'PvZFusion';
'@

if ($html.Contains($oldNormalize)) {
    $html = $html.Replace($oldNormalize, $newNormalize)
    Write-Host "Updated normalizeGameKey to recognize hybrid and classic."
}

# J. Update selectStreamingGame target preset routing
$oldSelectRouting = @'
                    // Open "Choose a preset" modal asking to continue existing commands or create new
                    let targetPresetGame = 'PvZFusion';
                    if (gameId === 'zombie_tsunami') targetPresetGame = 'Zombie Tsunami';
                    else if (gameId === 'universal_stream') targetPresetGame = 'Minecraft';
                    else targetPresetGame = 'PvZFusion';
'@

$newSelectRouting = @'
                    // Open "Choose a preset" modal asking to continue existing commands or create new
                    let targetPresetGame = 'PvZFusion';
                    if (gameId === 'pvz_hybrid') targetPresetGame = 'pvz_hybrid';
                    else if (gameId === 'pvz_classic') targetPresetGame = 'pvz_classic';
                    else if (gameId === 'zombie_tsunami') targetPresetGame = 'zombie_tsunami';
                    else if (gameId === 'universal_stream') targetPresetGame = 'Minecraft';
                    else targetPresetGame = 'PvZFusion';
'@

if ($html.Contains($oldSelectRouting)) {
    $html = $html.Replace($oldSelectRouting, $newSelectRouting)
    Write-Host "Updated selectStreamingGame preset routing for pvz_hybrid."
}

# K. Update onPresetGameChanged in JS
$oldGameChanged = @'
                function onPresetGameChanged(game) {
                    const coverSelect = document.getElementById('presetInputCover');
                    if (!coverSelect) return;
                    const gLower = game.toLowerCase();
                    if (gLower.includes('minecraft')) coverSelect.value = 'images/games/minecraft.jpg';
'@

$newGameChanged = @'
                function onPresetGameChanged(game) {
                    const coverSelect = document.getElementById('presetInputCover');
                    if (!coverSelect) return;
                    const gLower = (game || '').toLowerCase();
                    if (gLower.includes('hybrid')) coverSelect.value = 'images/games/pvz_hybrid_poster.jpg';
                    else if (gLower.includes('classic') || gLower.includes('goty')) coverSelect.value = 'images/games/pvz_classic_poster.jpg';
                    else if (gLower.includes('minecraft')) coverSelect.value = 'images/games/minecraft.jpg';
'@

if ($html.Contains($oldGameChanged)) {
    $html = $html.Replace($oldGameChanged, $newGameChanged)
    Write-Host "Updated onPresetGameChanged cover selection."
}

# L. Update saveNewPresetModal auto_game starter triggers for pvz_hybrid
$oldStarterTarget = @'
                    } else if (starter === 'auto_game') {
                        if (game === 'Minecraft') {
'@

$newStarterContent = @'
                    } else if (starter === 'auto_game') {
                        if (game === 'pvz_hybrid') {
                            initialEvents = [
                                { id: "hyb_" + Date.now() + "_1", giftName: "Spawn Hybrid Peashooter", coins: 1, icon: "images/tiktok-gifts/5655_rose.webp", unitIcon: "images/game-icons/pvz/spawn_gatling_pea.webp", actionType: "plant", command: "spawn_hybrid_pea", label: "Hybrid Peashooter (1)", repetition: 1, targetGame: "pvz_hybrid", spinnerRarity: "Common", funcImg: "images/game-icons/pvz/spawn_gatling_pea.webp", funcName: "Hybrid Peashooter" },
                                { id: "hyb_" + Date.now() + "_2", giftName: "Spawn Hybrid Gargantuar", coins: 20, icon: "images/tiktok-gifts/5827_icecream.webp", unitIcon: "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp", actionType: "zombie", command: "spawn_hybrid_gargantuar", label: "Hybrid Gargantuar", repetition: 1, targetGame: "pvz_hybrid", spinnerRarity: "Rare", funcImg: "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp", funcName: "Hybrid Gargantuar" },
                                { id: "hyb_" + Date.now() + "_3", giftName: "Summon Mecha Horse", coins: 99, icon: "images/tiktok-gifts/5655_rose.webp", unitIcon: "images/game-icons/pvz/spawn_ultimatehorse.webp", actionType: "zombie", command: "spawn_hybrid_mecha", label: "Mecha Horse Zombie", repetition: 1, targetGame: "pvz_hybrid", spinnerRarity: "Epic", funcImg: "images/game-icons/pvz/spawn_ultimatehorse.webp", funcName: "Mecha Horse Zombie" },
                                { id: "hyb_" + Date.now() + "_4", giftName: "Super Hybrid Boss Wave", coins: 488, icon: "images/tiktok-gifts/5827_icecream.webp", unitIcon: "images/game-icons/pvz/spawn_supergargantuar.webp", actionType: "zombie", command: "spawn_hybrid_boss_wave", label: "Super Hybrid Mega Boss", repetition: 1, targetGame: "pvz_hybrid", spinnerRarity: "Legendary", funcImg: "images/game-icons/pvz/spawn_supergargantuar.webp", funcName: "Super Hybrid Mega Boss" }
                            ];
                        } else if (game === 'Minecraft') {
'@

if ($html.Contains($oldStarterTarget)) {
    $html = $html.Replace($oldStarterTarget, $newStarterContent)
    Write-Host "Updated saveNewPresetModal auto_game starter triggers for pvz_hybrid."
}

# M. Save app.html BOM-free UTF-8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($appHtmlPath, $html, $utf8NoBom)
Write-Host "Successfully saved updated core/app.html!"
