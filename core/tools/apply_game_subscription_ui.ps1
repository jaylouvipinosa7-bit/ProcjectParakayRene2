# Script to cleanly inject the Game-Specific Subscription UI into core/app.html

$appPath = "c:\Users\pc\Downloads\ano na\core\app.html"
$content = [System.IO.File]::ReadAllText($appPath, [System.Text.Encoding]::UTF8)

# 1. CSS Styles to add
$cssStyles = @"

        /* GAME-SPECIFIC SUBSCRIPTION BANNER (IMAGE 1 PARITY) */
        .game-subscription-required-banner {
            display: flex;
            align-items: center;
            gap: 24px;
            padding: 18px 26px;
            background: linear-gradient(135deg, #231f1c 0%, #191614 100%);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 14px;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.06);
            position: relative;
            overflow: hidden;
            margin-bottom: 22px;
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .game-subscription-required-banner::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 4px;
            height: 100%;
            background: linear-gradient(180deg, #f59e0b, #ea580c);
            opacity: 0.9;
        }

        .game-sub-char-box {
            width: 145px;
            height: 108px;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            border-radius: 10px;
        }

        .game-sub-char-img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            object-position: center;
            filter: drop-shadow(0 6px 16px rgba(0, 0, 0, 0.75));
            transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .game-subscription-required-banner:hover .game-sub-char-img {
            transform: scale(1.06);
        }

        .game-sub-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 6px;
            min-width: 0;
        }

        .game-sub-header-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .game-sub-game-title {
            font-size: 21px;
            font-weight: 800;
            color: #ffffff;
            margin: 0;
            letter-spacing: -0.3px;
            display: flex;
            align-items: center;
            gap: 8px;
            font-family: 'Outfit', 'Plus Jakarta Sans', system-ui, sans-serif;
        }

        .game-sub-badge {
            font-size: 11px;
            font-weight: 800;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            color: #60a5fa;
            background: rgba(37, 99, 235, 0.14);
            border: 1.5px solid #2563eb;
            padding: 4px 14px;
            border-radius: 9999px;
            white-space: nowrap;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            box-shadow: 0 0 12px rgba(37, 99, 235, 0.25);
        }

        .game-sub-badge.badge-active-sub {
            color: #34d399;
            background: rgba(16, 185, 129, 0.15);
            border-color: #10b981;
            box-shadow: 0 0 12px rgba(16, 185, 129, 0.25);
        }

        .game-sub-desc {
            font-size: 13.5px;
            color: #a8a29e;
            margin: 2px 0 8px 0;
            line-height: 1.45;
            font-weight: 500;
        }

        .game-sub-actions-row {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }

        .btn-game-sub-subscribe {
            background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%);
            color: #ffffff;
            border: none;
            padding: 8px 18px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 800;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 7px;
            box-shadow: 0 4px 14px rgba(234, 88, 12, 0.4);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .btn-game-sub-subscribe:hover {
            background: linear-gradient(135deg, #fbbf24 0%, #f97316 100%);
            box-shadow: 0 6px 20px rgba(234, 88, 12, 0.6);
            transform: translateY(-1px);
        }

        .btn-game-sub-subscribe:active {
            transform: translateY(0);
        }

        .btn-game-sub-preview-toggle {
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.14);
            color: #cbd5e1;
            font-size: 11.5px;
            font-weight: 700;
            padding: 7px 13px;
            border-radius: 7px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-game-sub-preview-toggle:hover {
            background: rgba(255, 255, 255, 0.12);
            border-color: rgba(255, 255, 255, 0.25);
            color: #ffffff;
        }

        .game-sub-required-pill {
            font-size: 9.5px;
            font-weight: 800;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            color: #60a5fa;
            background: rgba(37, 99, 235, 0.15);
            border: 1px solid rgba(59, 130, 246, 0.4);
            padding: 2px 7px;
            border-radius: 4px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
"@

if ($content -notmatch 'game-subscription-required-banner') {
    $targetGrid = '/* 2-Column Audience Games Grid */'
    $content = $content.Replace($targetGrid, $cssStyles + "`r`n`r`n        " + $targetGrid)
    Write-Host "Injected CSS styles successfully!"
} else {
    Write-Host "CSS styles already present."
}

# 2. Inject Banner Container in tab-album
$targetDiv = '<div class="pvz-choose-games-grid" id="pvzChooseGamesGrid">'
$bannerHtml = @"
                    <!-- Specific Game Subscription Banner (Image 1 Parity) -->
                    <div id="gameSpecificSubscriptionBanner"></div>

                    $targetDiv
"@

if ($content -notmatch 'id="gameSpecificSubscriptionBanner"') {
    $content = $content.Replace($targetDiv, $bannerHtml)
    Write-Host "Injected gameSpecificSubscriptionBanner container!"
} else {
    Write-Host "gameSpecificSubscriptionBanner container already present."
}

# 3. Add game-sub-required-pill to cards in pvzChooseGamesGrid if not present
if ($content -notmatch 'game-sub-required-pill') {
    $oldBadge = '<span class="audience-game-badge">AUDIENCE GAME</span>'
    $newBadge = '<span class="audience-game-badge">AUDIENCE GAME</span><span class="game-sub-required-pill">SUBSCRIPTION REQUIRED</span>'
    $content = $content.Replace($oldBadge, $newBadge)
    Write-Host "Injected game-sub-required-pill on audience game cards!"
}

# 4. JavaScript Functions & Data to inject
$jsLogic = @'

            // GAME SPECIFIC SUBSCRIPTION METADATA & CONTROLS (IMAGE 1 PARITY)
            const GAME_SUB_DATA = {
                'l4d2': {
                    name: 'Left 4 Dead 2',
                    charImg: 'images/games/chars/l4d2.png',
                    fallbackArt: 'images/games/l4d2.jpg',
                    desc: 'A Plus or Ultra subscription is required to install mods and execute in-game actions.',
                    genre: 'Co-op Survival'
                },
                'gta_sa': {
                    name: 'GTA San Andreas',
                    charImg: 'images/games/chars/gta_sa.png',
                    fallbackArt: 'images/games/gta_sa.jpg',
                    desc: 'A Plus or Ultra subscription is required to install CLEO mods and execute in-game actions.',
                    genre: 'Action Sandbox'
                },
                're4': {
                    name: 'Resident Evil 4 Remake',
                    charImg: 'images/games/chars/re4.png',
                    fallbackArt: 'images/games/re4.jpg',
                    desc: 'A Plus or Ultra subscription is required to install REFramework mods and execute in-game actions.',
                    genre: 'Action Survival Horror'
                },
                'PvZFusion': {
                    name: 'Plants vs. Zombies Fusion',
                    charImg: 'images/games/chars/pvz_fusion.png',
                    fallbackArt: 'images/pvz_fusion_cover.jpg',
                    desc: 'A Plus or Ultra subscription is required to install mods and execute in-game actions.',
                    genre: 'Strategy Tower Defense'
                },
                'gtav_chaos': {
                    name: 'Grand Theft Auto V Chaos',
                    charImg: 'images/games/chars/gtav_chaos.png',
                    fallbackArt: 'images/games/gtav_chaos.jpg',
                    desc: 'A Plus or Ultra subscription is required to install ScriptHookV mods and execute in-game actions.',
                    genre: 'Action Sandbox'
                },
                'gtav_koth': {
                    name: 'GTA V King of the Hill',
                    charImg: 'images/games/chars/gtav_koth.png',
                    fallbackArt: 'images/games/gtav_koth.jpg',
                    desc: 'A Plus or Ultra subscription is required to install arena mods and execute in-game actions.',
                    genre: 'Competitive Arena'
                },
                'gtav_airport': {
                    name: 'GTA V Airport',
                    charImg: 'images/games/chars/gtav_airport.png',
                    fallbackArt: 'images/games/gtav_airport.jpg',
                    desc: 'A Plus or Ultra subscription is required to install sandbox mods and execute in-game actions.',
                    genre: 'Action Sandbox'
                },
                'Minecraft': {
                    name: 'Minecraft Chaos Live',
                    charImg: 'images/games/chars/minecraft.png',
                    fallbackArt: 'images/games/minecraft.jpg',
                    desc: 'A Plus or Ultra subscription is required to install Spigot/Forge mods and execute in-game actions.',
                    genre: 'Sandbox Survival'
                },
                'zombie_tsunami': {
                    name: 'Zombie Tsunami PC',
                    charImg: 'images/games/chars/zombie_tsunami.png',
                    fallbackArt: 'images/games/zombie_tsunami_poster.jpg',
                    desc: 'A Plus or Ultra subscription is required to install runner mods and execute in-game actions.',
                    genre: 'Arcade Runner'
                },
                'pvz_classic': {
                    name: 'Plants vs. Zombies GOTY',
                    charImg: 'images/games/chars/pvz_classic.png',
                    fallbackArt: 'images/games/pvz_classic_poster.jpg',
                    desc: 'A Plus or Ultra subscription is required to install classic mods and execute in-game actions.',
                    genre: 'Strategy Tower Defense'
                },
                'pvz_hybrid': {
                    name: 'PvZ: Hybrid Edition',
                    charImg: 'images/games/chars/pvz_hybrid.png',
                    fallbackArt: 'images/games/pvz_hybrid_poster.jpg',
                    desc: 'A Plus or Ultra subscription is required to install hybrid mods and execute in-game actions.',
                    genre: 'Strategy Mutant Defense'
                },
                'tabs': {
                    name: 'Totally Accurate Battle Simulator',
                    charImg: 'images/games/chars/tabs.svg',
                    fallbackArt: 'images/games/tabs.svg',
                    desc: 'A Plus or Ultra subscription is required to install physics mods and execute in-game actions.',
                    genre: 'Simulation Physics'
                },
                'uebs2': {
                    name: 'Ultimate Epic Battle Simulator 2',
                    charImg: 'images/games/chars/uebs2.svg',
                    fallbackArt: 'images/games/uebs2.svg',
                    desc: 'A Plus or Ultra subscription is required to install warfare hooks and spawn massive armies.',
                    genre: 'Simulation Warfare'
                },
                'Crown Clash': {
                    name: 'Crown Clash Arena',
                    charImg: 'images/games/chars/crown_clash.svg',
                    fallbackArt: 'images/games/crown_clash.svg',
                    desc: 'A Plus or Ultra subscription is required to install arena deck hooks and summon live cards.',
                    genre: 'Strategy Card Battles'
                }
            };

            let simulatedGameSubUnlocked = false;

            function toggleSimulatedGameSubscription(forceState) {
                if (typeof forceState === 'boolean') {
                    simulatedGameSubUnlocked = forceState;
                } else {
                    simulatedGameSubUnlocked = !simulatedGameSubUnlocked;
                }
                updateGameSpecificSubscriptionBanner(currentActiveAlbumGame || 'l4d2');
                if (typeof showToast === 'function') {
                    showToast(simulatedGameSubUnlocked ? '👑 Demo Mode: Subscription Unlocked' : '🔒 Demo Mode: Subscription Required', 'INFO');
                }
            }

            function getGameSubscriptionBannerHTML(gameKey) {
                const normKey = normalizeGameKey(gameKey || 'l4d2');
                const game = GAME_SUB_DATA[normKey] || GAME_SUB_DATA['l4d2'];
                const isSubscribed = simulatedGameSubUnlocked || !!(currentSubscription && (currentSubscription.tier === 'owner' || currentSubscription.tier === 'premium' || currentSubscription.tier === 'ultra' || currentSubscription.tier === 'plus' || currentSubscription.isUnlimited));

                return `
                    <div class="game-subscription-required-banner" id="gameSubBanner_${normKey}">
                        <!-- Specific Game Character Icon/Picture (Image 1 Parity) -->
                        <div class="game-sub-char-box">
                            <img src="${game.charImg}" onerror="this.onerror=null; this.src='${game.fallbackArt}';" alt="${game.name}" class="game-sub-char-img">
                        </div>

                        <!-- Right Content Column -->
                        <div class="game-sub-content">
                            <div class="game-sub-header-row">
                                <h3 class="game-sub-game-title">
                                    <span>${game.name}</span>
                                </h3>
                                <span class="game-sub-badge ${isSubscribed ? 'badge-active-sub' : ''}">
                                    ${isSubscribed ? '👑 OWNER LIFETIME ACTIVE' : 'SUBSCRIPTION REQUIRED'}
                                </span>
                            </div>
                            <p class="game-sub-desc">
                                ${isSubscribed ? `Active subscription unlocks direct mod injection, audience triggers, and in-game live actions for ${game.name}.` : game.desc}
                            </p>
                            <div class="game-sub-actions-row">
                                <button type="button" class="btn-game-sub-subscribe" onclick="openManageSubscriptionModal()">
                                    <span style="font-size: 15px;">✦</span>
                                    <span>${isSubscribed ? 'Manage Subscription' : 'Subscribe to access'}</span>
                                    <span style="font-size: 14px; margin-left: 2px;">→</span>
                                </button>
                                <button type="button" class="btn-game-sub-preview-toggle" onclick="toggleSimulatedGameSubscription()">
                                    <span>${isSubscribed ? '🔒 Preview Locked State' : '👁️ Preview Unlocked State'}</span>
                                </button>
                            </div>
                        </div>
                    </div>
                `;
            }

            function updateGameSpecificSubscriptionBanner(gameKey) {
                const bannerContainer = document.getElementById('gameSpecificSubscriptionBanner');
                if (bannerContainer) {
                    bannerContainer.innerHTML = getGameSubscriptionBannerHTML(gameKey);
                }
            }

'@

if ($content -notmatch 'GAME_SUB_DATA') {
    $targetFunc = 'function selectGameAlbum(gameName, openModal = true) {'
    $content = $content.Replace($targetFunc, $jsLogic + "`r`n`r`n            " + $targetFunc)
    Write-Host "Injected GAME_SUB_DATA and banner helper functions!"
} else {
    Write-Host "GAME_SUB_DATA already present."
}

# 5. Call updateGameSpecificSubscriptionBanner inside selectGameAlbum
$selectCall = "if (statusBarName) statusBarName.textContent = albumData.name;"
$newSelectCall = "$selectCall`r`n                updateGameSpecificSubscriptionBanner(gameName);"

if ($content -notmatch 'updateGameSpecificSubscriptionBanner\(gameName\)') {
    $content = $content.Replace($selectCall, $newSelectCall)
    Write-Host "Injected updateGameSpecificSubscriptionBanner call into selectGameAlbum!"
}

# 6. Inject game subscription banner inside modal detail view
$heroTag = '<!-- Hero Banner -->'
$modalSubBanner = "<!-- Game-Specific Subscription Banner (Image 1 Parity) -->`r`n                        <div style=`"margin-bottom: 16px;`">`${getGameSubscriptionBannerHTML(gameKey)}</div>`r`n`r`n                        $heroTag"

if ($content -notmatch 'getGameSubscriptionBannerHTML\(gameKey\)') {
    $content = $content.Replace($heroTag, $modalSubBanner)
    Write-Host "Injected banner into modal detail view!"
}

[System.IO.File]::WriteAllText($appPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "core/app.html updated successfully with all Game Subscription UI features!"
