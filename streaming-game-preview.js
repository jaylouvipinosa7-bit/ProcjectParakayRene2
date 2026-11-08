/**
 * RENEarn Studio - Streaming Gameplay Preview System & Game Catalog HUD
 * Continuous 60fps Autoplay for Verified Game Clips, Muted & Looping,
 * 200ms Crossfade on CanPlay, 40% Visibility IntersectionObserver (Max 4),
 * In-place Non-destructive Game Selection (Zero Video Reload/Flicker),
 * "Pause Previews" Toolbar Toggle with LocalStorage Memory,
 * Precision Object-Positioning, and Responsive Enlarged Popover.
 */

(function () {
    'use strict';

    // ==========================================
    // 1. DATA-DRIVEN STREAMING GAMES CATALOG (13 Games)
    // Only games with verified local clips have previewVideo set.
    // ==========================================
    const STREAMING_GAMES_CATALOG = [
        {
            id: 'pvz_fusion_4',
            name: 'PvZ Fusion 4.0',
            subtitle: 'Direct Mod Link Active • 150+ Actions',
            tag: 'Official • Live Ready',
            category: 'official',
            accent: '#10b981',
            accentRgb: '16, 185, 129',
            accent2: '#059669',
            poster: 'images/pvz_fusion_cover.jpg',
            previewPoster: 'images/pvz_fusion_cover.jpg',
            objectPosition: 'center center',
            previewVideo: 'assets/previews/pvz_fusion_4.mp4',
            previewFallback: '',
            previewDuration: 7,
            features: ['72 Spawns', '3D Spinner', 'Matter.js Jar', 'Overlay HUD'],
            featureCounts: '72 spawn commands, 3D Spinner, Matter.js Jar, Custom Triggers',
            badgeText: 'CONNECTED'
        },
        {
            id: 'pvz_hybrid',
            name: 'PvZ: Hybrid Edition',
            subtitle: 'Hybrid Plants & Zombie Mutations',
            tag: 'Hybrid • Ready',
            category: 'official',
            accent: '#a855f7',
            accentRgb: '168, 85, 247',
            accent2: '#7e22ce',
            poster: 'images/games/pvz_hybrid_poster.jpg',
            previewPoster: 'images/games/pvz_hybrid_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Hybrid Plants', 'Mutant Spawns', 'Laser Corn', 'Sun Boost'],
            featureCounts: '64 hybrid mutations, custom sun spawners, laser triggers',
            badgeText: 'READY'
        },
        {
            id: 'pvz_classic',
            name: 'PvZ: Classic / GOTY',
            subtitle: 'Classic GOTY Memory Injection',
            tag: 'Classic PvZ1 • Ready',
            category: 'official',
            accent: '#f59e0b',
            accentRgb: '245, 158, 11',
            accent2: '#d97706',
            poster: 'images/games/pvz_classic_poster.jpg',
            previewPoster: 'images/games/pvz_classic_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['GOTY Engine', 'Sun Drops', 'Gargantuar Rush', 'Roof Spawns'],
            featureCounts: 'Direct RAM injection, sun burst triggers, vanilla waves',
            badgeText: 'READY'
        },
        {
            id: 'zombie_tsunami',
            name: 'Zombie Tsunami (PC)',
            subtitle: 'Interactive Crowd Horde Runner',
            tag: 'Interactive Web • Ready',
            category: 'live',
            accent: '#14b8a6',
            accentRgb: '20, 184, 166',
            accent2: '#0f766e',
            poster: 'images/games/zombie_tsunami_poster.jpg',
            previewPoster: 'images/games/zombie_tsunami_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Crowd Horde', 'Tsunami Waves', 'Audience Voting', 'Bonus Drops'],
            featureCounts: 'Live horde spawns, tsunami multipliers, gift coin triggers',
            badgeText: 'LIVE READY'
        },
        {
            id: 'universal_stream',
            name: 'Minecraft & Universal',
            subtitle: 'Universal Mod Injection & Socket Link',
            tag: 'Universal Stream • Ready',
            category: 'universal',
            accent: '#c084fc',
            accentRgb: '192, 132, 252',
            accent2: '#9333ea',
            poster: 'images/games/minecraft_chaos_poster.jpg',
            previewPoster: 'images/games/minecraft_chaos_poster.jpg',
            objectPosition: 'center 20%',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Forge & Fabric', 'TNT Drops', 'Mob Spawners', 'Universal RCON'],
            featureCounts: 'Forge/Fabric socket link, TNT triggers, mob wave summons',
            badgeText: 'UNIVERSAL'
        },
        {
            id: 'l4d2',
            name: 'Left 4 Dead 2',
            subtitle: 'Source Engine VPK Hook & VScript',
            tag: 'Co-op Survival • Ready',
            category: 'live',
            accent: '#ef4444',
            accentRgb: '239, 68, 68',
            accent2: '#b91c1c',
            poster: 'images/games/l4d2.jpg',
            previewPoster: 'images/games/l4d2.jpg',
            objectPosition: 'center 20%',
            previewVideo: 'assets/previews/l4d2.mp4',
            previewFallback: 'assets/previews/left4dead.mp4',
            previewDuration: 6,
            features: ['Tank Spawns', 'Witch Triggers', 'Horde Rush', 'Director Override'],
            featureCounts: 'Direct VScript injection, special infected spawns, supply crates',
            badgeText: 'LIVE READY'
        },
        {
            id: 'gta_sa',
            name: 'GTA San Andreas',
            subtitle: 'CLEO & ASI Chaos Script Controller',
            tag: 'Action Sandbox • Ready',
            category: 'sandbox',
            accent: '#f59e0b',
            accentRgb: '245, 158, 11',
            accent2: '#b45309',
            poster: 'images/games/gta_sa.jpg',
            previewPoster: 'images/games/gta_sa.jpg',
            objectPosition: 'center 12%',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['CLEO Scripts', 'Vehicle Drops', 'Chaos Cheats', 'Weapon Spawns'],
            featureCounts: 'Vehicle parachute drops, weather toggles, jetpack triggers',
            badgeText: 'LIVE READY'
        },
        {
            id: 'gtav_chaos',
            name: 'GTA V Chaos',
            subtitle: 'Chaos Mod WebSocket Live Bridge',
            tag: 'Chaos Sandbox • Ready',
            category: 'sandbox',
            accent: '#38bdf8',
            accentRgb: '56, 189, 248',
            accent2: '#0284c7',
            poster: 'images/games/gtav_chaos_poster.jpg',
            previewPoster: 'images/games/gtav_chaos_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Chaos Voting', 'Gravity Flips', 'Exploding Cars', 'Skyfall Spawns'],
            featureCounts: 'Twitch/TikTok chat voting, random effect trigger queue',
            badgeText: 'LIVE READY'
        },
        {
            id: 're4',
            name: 'Resident Evil 4',
            subtitle: 'Biohazard Survival Horror Memory Hook',
            tag: 'Survival Horror • Ready',
            category: 'live',
            accent: '#f43f5e',
            accentRgb: '244, 63, 94',
            accent2: '#be123c',
            poster: 'images/games/re4_poster.jpg',
            previewPoster: 'images/games/re4_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Chainsaw Guy', 'Ammo Crates', 'Health Herbs', 'Plaga Bosses'],
            featureCounts: 'Chainsaw Salvador spawns, rocket launcher drops, enemy surges',
            badgeText: 'LIVE READY'
        },
        {
            id: 'tabs',
            name: 'TABS Simulator',
            subtitle: 'Totally Accurate Battle Physics Link',
            tag: 'Physics Warfare • Ready',
            category: 'live',
            accent: '#eab308',
            accentRgb: '234, 179, 8',
            accent2: '#a16207',
            poster: 'images/games/tabs_poster.jpg',
            previewPoster: 'images/games/tabs_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Mammoth Drops', 'Zeus Strikes', 'Wobbly Spawns', 'Unit Roster'],
            featureCounts: 'Massive ragdoll army spawns, custom faction unit injection',
            badgeText: 'LIVE READY'
        },
        {
            id: 'uebs2',
            name: 'UEBS 2',
            subtitle: 'Ultimate Epic Battle 100k Mass Sim',
            tag: 'Mass Battle • Live Ready',
            category: 'live',
            accent: '#f97316',
            accentRgb: '249, 115, 22',
            accent2: '#c2410c',
            poster: 'images/games/uebs2_poster.jpg',
            previewPoster: 'images/games/uebs2_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['100k Soldiers', 'Nuke Drops', 'Dragon Swarms', 'Carnage Mode'],
            featureCounts: '100,000 unit batch spawners, orbital laser strikes',
            badgeText: 'LIVE READY'
        },
        {
            id: 'crown_clash',
            name: 'Crown Clash Arena',
            subtitle: 'Deck Building & Tower Raid Live Engine',
            tag: 'Deck Strategy • Ready',
            category: 'live',
            accent: '#06b6d4',
            accentRgb: '6, 182, 212',
            accent2: '#0e7490',
            poster: 'images/games/crown_clash_poster.jpg',
            previewPoster: 'images/games/crown_clash_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Spell Cards', 'Tower Damage', 'Mana Boosts', 'Champion Summons'],
            featureCounts: 'Viewer card drafting, live elixir pool, tower spell bombardment',
            badgeText: 'LIVE READY'
        },
        {
            id: 'kingdom_siege',
            name: 'Kingdom Siege',
            subtitle: 'Castle Defenses & Audience Raid Triggers',
            tag: 'Siege Defense • Ready',
            category: 'live',
            accent: '#10b981',
            accentRgb: '16, 185, 129',
            accent2: '#047857',
            poster: 'images/games/kingdom_siege_poster.jpg',
            previewPoster: 'images/games/kingdom_siege_poster.jpg',
            objectPosition: 'center top',
            previewVideo: '',
            previewFallback: '',
            previewDuration: 6,
            features: ['Dragon Boss', 'Catapult Strikes', 'Castle Raids', 'Treasure Chests'],
            featureCounts: 'Raid commander voting, dragon boss spawns, defense buffs',
            badgeText: 'LIVE READY'
        }
    ];

    window.STREAMING_GAMES_CATALOG = STREAMING_GAMES_CATALOG;

    // ==========================================
    // 2. STATE & PLAYBACK CONTROLLER
    // ==========================================
    const MAX_CONCURRENT_AUTOPLAY = 4;
    const activePlayingVideoIds = new Set();
    const visibleVideoCards = new Set();
    const cardDOMElementsMap = new Map(); // Preserves mounted <video> elements
    let intersectionObserver = null;
    let currentFilter = 'all';
    let currentSearchTerm = '';
    let enlargedActiveGameId = null;

    function isPreviewsPaused() {
        try {
            return localStorage.getItem('renearn_pause_previews') === '1';
        } catch (_) {
            return false;
        }
    }

    function isReducedMotion() {
        try {
            return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        } catch (_) {
            return false;
        }
    }

    function getActiveStreamingGameId() {
        return (typeof window.currentActiveStreamingGame !== 'undefined' && window.currentActiveStreamingGame)
            ? window.currentActiveStreamingGame
            : (localStorage.getItem('active_streaming_game') || 'pvz_fusion_4');
    }

    function getRecentGames() {
        try {
            const raw = localStorage.getItem('renearn_recent_games');
            return raw ? JSON.parse(raw) : ['pvz_fusion_4'];
        } catch (_) {
            return ['pvz_fusion_4'];
        }
    }

    function addRecentGame(gameId) {
        try {
            let list = getRecentGames().filter(id => id !== gameId);
            list.unshift(gameId);
            if (list.length > 3) list = list.slice(0, 3);
            localStorage.setItem('renearn_recent_games', JSON.stringify(list));
            renderRecentGamesBar();
        } catch (_) {}
    }

    // ==========================================
    // 3. CARD DOM BUILDER (Mounted once, reused across filters/selections)
    // ==========================================
    function createGameCardElement(game, index, activeGameId) {
        const isSelected = (game.id === activeGameId);
        const badgeText = isSelected ? 'CONNECTED' : game.badgeText;
        const badgeClass = isSelected ? 'badge-connected' : (game.id === 'universal_stream' ? 'badge-universal' : 'badge-ready');
        const hasVideo = !!game.previewVideo;

        const card = document.createElement('div');
        card.className = `stream-game-card ${isSelected ? 'active' : ''}`;
        card.id = `gameCard_${game.id}`;
        card.setAttribute('data-game-id', game.id);
        card.setAttribute('data-category', game.category);
        card.setAttribute('tabindex', '0');
        card.setAttribute('role', 'button');
        card.setAttribute('aria-label', `${game.name} - ${game.subtitle}. ${isSelected ? 'Currently Selected.' : 'Press Enter to select.'}`);
        card.style.setProperty('--card-accent', game.accent);
        card.style.setProperty('--card-accent-rgb', game.accentRgb);
        card.style.setProperty('--card-accent-2', game.accent2);
        card.style.setProperty('--card-glow', `rgba(${game.accentRgb}, 0.28)`);
        card.style.setProperty('--card-object-position', game.objectPosition);
        card.style.setProperty('--card-index', index);

        card.innerHTML = `
            <!-- Game Poster & Gameplay Video Box -->
            <div class="game-poster-box">
                <div class="game-poster-skeleton" aria-hidden="true"></div>
                <img src="${game.poster}" 
                     alt="${game.name}" 
                     class="game-poster-img"
                     loading="lazy"
                     onload="this.previousElementSibling && (this.previousElementSibling.style.display='none')"
                     onerror="this.onerror=null; this.src='images/pvz_fusion_cover.jpg';">

                ${hasVideo ? `
                <video class="game-preview-video" 
                       src="${game.previewVideo}"
                       autoplay 
                       muted 
                       loop 
                       playsinline 
                       preload="auto" 
                       poster="${game.previewPoster || game.poster}"
                       aria-hidden="true">
                </video>
                ` : ''}

                <div class="game-poster-gradient" aria-hidden="true"></div>

                <!-- Live Preview Badge (Pulsing REC dot while clip is active, neutral gray when paused) -->
                <div class="gameplay-preview-pill" aria-label="Gameplay Preview Available">
                    <span class="preview-rec-dot" id="recDot_${game.id}"></span>
                    <span class="preview-pill-text" id="previewText_${game.id}">LIVE PREVIEW</span>
                </div>

                <!-- Expand Popover Button -->
                <button type="button" 
                        class="btn-card-expand" 
                        onclick="event.stopPropagation(); window.openEnlargedPreview('${game.id}', event);"
                        title="Expand preview & details" 
                        aria-label="Expand preview for ${game.name}">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <polyline points="15 3 21 3 21 9"></polyline>
                        <polyline points="9 21 3 21 3 15"></polyline>
                        <line x1="21" y1="3" x2="14" y2="10"></line>
                        <line x1="3" y1="21" x2="10" y2="14"></line>
                    </svg>
                </button>

                <!-- Status Tag Badge on Poster -->
                <span class="game-card-badge ${badgeClass}" id="badge_${game.id}">${badgeText}</span>

                <!-- Progress Bar along bottom -->
                <div class="preview-progress-track" aria-hidden="true">
                    <div class="preview-progress-bar" id="progressBar_${game.id}"></div>
                </div>

                <!-- NOW SELECTED Ribbon inside poster box so it is NEVER clipped -->
                ${isSelected ? `
                    <div class="game-selected-ribbon" aria-hidden="true">
                        <span>NOW SELECTED</span>
                    </div>
                ` : ''}
            </div>

            <!-- Bottom Info Area -->
            <div class="game-card-info-wrap">
                <div>
                    <div class="game-card-title" title="${game.name}">${game.name}</div>
                    <div class="game-card-subtitle" title="${game.subtitle}">${game.subtitle}</div>
                    
                    <!-- Feature Micro-Icons Row -->
                    <div class="game-feature-icons-row" aria-label="Supported features">
                        <span class="feature-micro-pill" title="Audience Spawns">
                            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                            <span>Spawns</span>
                        </span>
                        <span class="feature-micro-pill" title="Live Triggers">
                            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
                            <span>Live Hook</span>
                        </span>
                        <span class="feature-micro-pill" title="Overlay HUD">
                            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><circle cx="15.5" cy="8.5" r="1.5"/></svg>
                            <span>HUD</span>
                        </span>
                    </div>
                </div>

                <div class="game-card-footer">
                    <span class="game-card-tag">${game.tag}</span>
                    <button type="button" 
                            class="btn-game-select ${isSelected ? 'active' : ''}" 
                            id="btnSelect_${game.id}"
                            onclick="event.stopPropagation(); window.handleSwitchGameClick('${game.id}', this);"
                            aria-label="${isSelected ? 'Game currently selected' : 'Switch to ' + game.name}">
                        <span class="btn-select-label">${isSelected ? 'Selected ✓' : 'Switch Game'}</span>
                        <span class="btn-select-spinner"></span>
                    </button>
                </div>
            </div>
        `;

        // Wire video autoplay controller
        if (hasVideo) {
            setupCardVideoPlayback(card, game);
        }

        // Wire card-level click & keyboard events
        wireCardInteractions(card, game.id);

        return card;
    }

    // ==========================================
    // 4. AUTOPLAY & VIDEO CONTROLLER
    // ==========================================
    function setupCardVideoPlayback(card, game) {
        const video = card.querySelector('.game-preview-video');
        if (!video) return;

        video.muted = true;
        video.volume = 0;
        video.playsInline = true;

        const progressBar = card.querySelector('.preview-progress-bar');
        const recDot = card.querySelector('.preview-rec-dot');

        // Progress bar along bottom
        video.ontimeupdate = function () {
            if (progressBar && video.duration) {
                const pct = (video.currentTime / video.duration) * 100;
                progressBar.style.width = pct + '%';
            }
        };

        // Smooth crossfade to video once canplay fires (no blank/black flash)
        video.oncanplay = function () {
            if (!isPreviewsPaused() && !isReducedMotion()) {
                attemptPlayVideo(video, card, game.id);
            }
        };

        video.onplaying = function () {
            card.classList.add('is-previewing');
            if (recDot) recDot.classList.add('is-recording');
            activePlayingVideoIds.add(game.id);
        };

        video.onpause = function () {
            if (recDot) recDot.classList.remove('is-recording');
            activePlayingVideoIds.delete(game.id);
        };

        video.onerror = function () {
            console.warn(`[RENEarn Preview] Video unavailable for ${game.id}. Showing poster.`);
            card.classList.remove('is-previewing');
            if (recDot) recDot.classList.remove('is-recording');
            activePlayingVideoIds.delete(game.id);
        };

        // If already buffered enough on initial mount, start playing
        if (video.readyState >= 2) {
            if (!isPreviewsPaused() && !isReducedMotion()) {
                attemptPlayVideo(video, card, game.id);
            }
        }
    }

    function attemptPlayVideo(video, card, gameId) {
        if (!video || !card) return;
        if (isPreviewsPaused() || isReducedMotion()) return;

        // Concurrent playback cap: max 4 videos at once
        if (activePlayingVideoIds.size >= MAX_CONCURRENT_AUTOPLAY && !activePlayingVideoIds.has(gameId)) {
            return;
        }

        video.muted = true;
        video.volume = 0;
        video.playsInline = true;

        const playPromise = video.play();
        if (playPromise !== undefined) {
            playPromise.then(() => {
                card.classList.add('is-previewing');
                const recDot = card.querySelector('.preview-rec-dot');
                if (recDot) recDot.classList.add('is-recording');
                activePlayingVideoIds.add(gameId);
            }).catch(err => {
                console.log(`[RENEarn Preview] Autoplay postponed until user interaction for ${gameId}:`, err);
                card.classList.remove('is-previewing');
                const recDot = card.querySelector('.preview-rec-dot');
                if (recDot) recDot.classList.remove('is-recording');

                // Retry automatically on first user click or keydown
                const onFirstInteraction = () => {
                    if (!isPreviewsPaused() && !isReducedMotion()) {
                        video.play().then(() => {
                            card.classList.add('is-previewing');
                            if (recDot) recDot.classList.add('is-recording');
                            activePlayingVideoIds.add(gameId);
                        }).catch(() => {});
                    }
                    window.removeEventListener('pointerdown', onFirstInteraction);
                    window.removeEventListener('keydown', onFirstInteraction);
                };
                window.addEventListener('pointerdown', onFirstInteraction, { once: true });
                window.addEventListener('keydown', onFirstInteraction, { once: true });
            });
        }
    }

    function checkAndFillVideoSlots() {
        if (isPreviewsPaused() || isReducedMotion()) return;
        for (const gId of visibleVideoCards) {
            if (activePlayingVideoIds.size >= MAX_CONCURRENT_AUTOPLAY) break;
            if (!activePlayingVideoIds.has(gId)) {
                const card = document.getElementById(`gameCard_${gId}`);
                if (card) {
                    const video = card.querySelector('.game-preview-video');
                    if (video) attemptPlayVideo(video, card, gId);
                }
            }
        }
    }

    // ==========================================
    // 5. INTERSECTION OBSERVER (40% Visibility Threshold)
    // ==========================================
    function setupIntersectionObserver() {
        if (!('IntersectionObserver' in window)) return;

        if (intersectionObserver) {
            intersectionObserver.disconnect();
        }

        intersectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                const card = entry.target;
                const gameId = card.getAttribute('data-game-id');
                const video = card.querySelector('.game-preview-video');
                if (!gameId || !video) return;

                if (entry.isIntersecting && entry.intersectionRatio >= 0.4) {
                    visibleVideoCards.add(gameId);
                    if (!isPreviewsPaused() && !isReducedMotion()) {
                        if (activePlayingVideoIds.size < MAX_CONCURRENT_AUTOPLAY) {
                            attemptPlayVideo(video, card, gameId);
                        }
                    }
                } else if (!entry.isIntersecting || entry.intersectionRatio < 0.4) {
                    visibleVideoCards.delete(gameId);
                    try { video.pause(); } catch (_) {}
                    card.classList.remove('is-previewing');
                    const recDot = card.querySelector('.preview-rec-dot');
                    if (recDot) recDot.classList.remove('is-recording');
                    activePlayingVideoIds.delete(gameId);

                    // Refill open slots with other visible games
                    checkAndFillVideoSlots();
                }
            });
        }, {
            threshold: [0, 0.4, 0.8]
        });

        // Observe cards that have a video element
        cardDOMElementsMap.forEach(card => {
            if (card.querySelector('.game-preview-video')) {
                intersectionObserver.observe(card);
            }
        });
    }

    // Window minimized / tab hidden handler
    document.addEventListener('visibilitychange', function () {
        if (document.hidden) {
            document.querySelectorAll('.stream-game-card').forEach(card => {
                const video = card.querySelector('.game-preview-video');
                if (video && !video.paused) {
                    try { video.pause(); } catch (_) {}
                }
            });
        } else {
            if (!isPreviewsPaused() && !isReducedMotion()) {
                checkAndFillVideoSlots();
            }
        }
    });

    // ==========================================
    // 6. CARD INTERACTIONS (Hover lift & Keyboard Nav)
    // ==========================================
    function wireCardInteractions(card, gameId) {
        // Keep video playing and lift card on hover
        card.addEventListener('mouseenter', () => {
            const video = card.querySelector('.game-preview-video');
            if (video && !isPreviewsPaused() && !isReducedMotion()) {
                if (video.paused) {
                    attemptPlayVideo(video, card, gameId);
                }
            }
        });

        // Click outside buttons selects game
        card.addEventListener('click', (e) => {
            if (e.target.closest('.btn-game-select') || e.target.closest('.btn-card-expand')) return;
            window.handleSwitchGameClick(gameId);
        });

        // Keyboard accessibility
        card.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                window.handleSwitchGameClick(gameId);
            } else if (e.key === ' ') {
                e.preventDefault();
                const video = card.querySelector('.game-preview-video');
                if (video) {
                    if (video.paused) {
                        attemptPlayVideo(video, card, gameId);
                    } else {
                        video.pause();
                    }
                }
            }
        });
    }

    // ==========================================
    // 7. IN-PLACE CARD SELECTION (Zero Video Reload/Flicker)
    // ==========================================
    function updateCardSelectionState(activeGameId) {
        STREAMING_GAMES_CATALOG.forEach(game => {
            const card = document.getElementById(`gameCard_${game.id}`);
            if (!card) return;

            const isSelected = (game.id === activeGameId);
            card.classList.toggle('active', isSelected);
            card.setAttribute('aria-label', `${game.name} - ${game.subtitle}. ${isSelected ? 'Currently Selected.' : 'Press Enter to select.'}`);

            // Unclipped Ribbon inside poster box
            const posterBox = card.querySelector('.game-poster-box');
            let ribbon = posterBox ? posterBox.querySelector('.game-selected-ribbon') : null;
            if (isSelected) {
                if (!ribbon && posterBox) {
                    ribbon = document.createElement('div');
                    ribbon.className = 'game-selected-ribbon';
                    ribbon.setAttribute('aria-hidden', 'true');
                    ribbon.innerHTML = '<span>NOW SELECTED</span>';
                    posterBox.appendChild(ribbon);
                }
            } else {
                if (ribbon) ribbon.remove();
            }

            // Status tag on poster
            const badge = document.getElementById(`badge_${game.id}`);
            if (badge) {
                const badgeText = isSelected ? 'CONNECTED' : game.badgeText;
                const badgeClass = isSelected ? 'badge-connected' : (game.id === 'universal_stream' ? 'badge-universal' : 'badge-ready');
                badge.className = `game-card-badge ${badgeClass}`;
                badge.textContent = badgeText;
            }

            // Switch button state
            const btn = document.getElementById(`btnSelect_${game.id}`);
            if (btn) {
                btn.classList.toggle('active', isSelected);
                const label = btn.querySelector('.btn-select-label');
                if (label) {
                    label.textContent = isSelected ? 'Selected ✓' : 'Switch Game';
                }
            }
        });
    }

    // ==========================================
    // 8. GRID RENDERING & CACHING
    // ==========================================
    function renderStreamingGameCards(filter = 'all', searchTerm = '') {
        const grid = document.getElementById('streamingGamesGrid');
        if (!grid) return;

        currentFilter = filter;
        currentSearchTerm = searchTerm.trim().toLowerCase();
        const activeGameId = getActiveStreamingGameId();

        let list = [...STREAMING_GAMES_CATALOG];

        // Apply category filter
        if (filter !== 'all') {
            list = list.filter(g => g.category === filter);
        }

        // Apply search filter
        if (currentSearchTerm) {
            list = list.filter(g => {
                return g.name.toLowerCase().includes(currentSearchTerm) ||
                    g.subtitle.toLowerCase().includes(currentSearchTerm) ||
                    g.tag.toLowerCase().includes(currentSearchTerm) ||
                    g.features.some(f => f.toLowerCase().includes(currentSearchTerm));
            });
        }

        // Update live counter
        const counter = document.getElementById('streamingGamesCount');
        if (counter) {
            counter.textContent = currentSearchTerm || filter !== 'all'
                ? `${list.length} Game${list.length === 1 ? '' : 's'} Found`
                : `${STREAMING_GAMES_CATALOG.length} Games Available`;
        }

        if (list.length === 0) {
            grid.innerHTML = `
                <div style="grid-column: 1 / -1; padding: 40px 20px; text-align: center; color: #94a3b8; background: rgba(14, 18, 28, 0.4); border: 1px dashed rgba(255, 255, 255, 0.1); border-radius: 14px;">
                    <div style="font-size: 32px; margin-bottom: 8px;">🎮</div>
                    <div style="font-size: 15px; font-weight: 700; color: #fff; margin-bottom: 4px;">No streaming games match your search</div>
                    <div style="font-size: 12px; color: #64748b; margin-bottom: 16px;">Try adjusting your search terms or category filter.</div>
                    <button type="button" class="btn btn-secondary btn-sm" onclick="window.clearStreamingGameSearch()" style="font-size: 11.5px; padding: 5px 14px;">Reset Filters</button>
                </div>
            `;
            return;
        }

        // Non-destructive mounting: reuse existing card DOM elements
        grid.innerHTML = '';
        list.forEach((g, idx) => {
            let cardEl = cardDOMElementsMap.get(g.id);
            if (!cardEl) {
                cardEl = createGameCardElement(g, idx, activeGameId);
                cardDOMElementsMap.set(g.id, cardEl);
            }
            grid.appendChild(cardEl);
        });

        // Ensure selection highlight is synced
        updateCardSelectionState(activeGameId);

        // Reconnect intersection observer
        setupIntersectionObserver();
    }

    function renderRecentGamesBar() {
        const bar = document.getElementById('streamingGamesRecentBar');
        const itemsWrap = document.getElementById('streamingGamesRecentItems');
        if (!bar || !itemsWrap) return;

        const recents = getRecentGames();
        if (!recents || recents.length === 0) {
            bar.style.display = 'none';
            return;
        }

        const activeGameId = getActiveStreamingGameId();
        bar.style.display = 'flex';

        itemsWrap.innerHTML = recents.map(id => {
            const g = STREAMING_GAMES_CATALOG.find(item => item.id === id);
            if (!g) return '';
            const isNowActive = (id === activeGameId);
            return `
                <button type="button" 
                        class="recent-game-chip ${isNowActive ? 'is-active-now' : ''}" 
                        style="--chip-accent: ${g.accent};"
                        onclick="window.handleSwitchGameClick('${g.id}', this)"
                        title="${g.name} (${g.tag})">
                    <span>${isNowActive ? '●' : '🎮'}</span>
                    <span>${g.name}</span>
                </button>
            `;
        }).join('');
    }

    // ==========================================
    // 9. PAUSE PREVIEWS TOOLBAR TOGGLE
    // ==========================================
    window.togglePausePreviews = function () {
        const currentlyPaused = isPreviewsPaused();
        const willBePaused = !currentlyPaused;
        try {
            localStorage.setItem('renearn_pause_previews', willBePaused ? '1' : '0');
        } catch (_) {}

        updatePauseButtonUI(willBePaused);

        if (willBePaused) {
            // Pause all videos and clear active set
            document.querySelectorAll('.stream-game-card').forEach(card => {
                const video = card.querySelector('.game-preview-video');
                if (video) {
                    try { video.pause(); } catch (_) {}
                }
                card.classList.remove('is-previewing');
                const recDot = card.querySelector('.preview-rec-dot');
                if (recDot) recDot.classList.remove('is-recording');
            });
            activePlayingVideoIds.clear();
            if (typeof showToast === 'function') {
                showToast('⏸ Gameplay previews paused', 'info');
            }
        } else {
            // Resume visible videos up to 4
            checkAndFillVideoSlots();
            if (typeof showToast === 'function') {
                showToast('▶ Gameplay previews playing', 'info');
            }
        }
    };

    window.togglePreviewAllGames = window.togglePausePreviews;

    function updatePauseButtonUI(isPaused) {
        const btn = document.getElementById('btnPausePreviewsToggle');
        const icon = document.getElementById('pausePreviewsIcon');
        const text = document.getElementById('pausePreviewsText');
        if (btn) {
            btn.classList.toggle('is-paused', isPaused);
            btn.title = isPaused ? 'Resume autoplay gameplay previews' : 'Pause autoplay gameplay previews';
        }
        if (icon) icon.textContent = isPaused ? '▶' : '⏸';
        if (text) text.textContent = isPaused ? 'Resume Previews' : 'Pause Previews';
    }

    // ==========================================
    // 10. SWITCH GAME HANDLER (In-place update)
    // ==========================================
    window.handleSwitchGameClick = function (gameId, btnElement) {
        if (!gameId) return;

        const targetBtn = btnElement || document.getElementById(`btnSelect_${gameId}`);
        if (targetBtn) targetBtn.classList.add('is-loading');

        addRecentGame(gameId);

        // App's native game selector
        if (typeof window.selectStreamingGame === 'function') {
            window.selectStreamingGame(gameId);
        }

        // In-place UI update (preserves <video> element playback without flicker)
        setTimeout(() => {
            if (targetBtn) targetBtn.classList.remove('is-loading');
            updateCardSelectionState(gameId);
            renderRecentGamesBar();
        }, 120);
    };

    // Filter by category
    window.filterStreamingGames = function (cat, btn) {
        document.querySelectorAll('.filter-chip').forEach(c => {
            c.classList.remove('active');
            c.setAttribute('aria-selected', 'false');
        });
        if (btn) {
            btn.classList.add('active');
            btn.setAttribute('aria-selected', 'true');
        }
        renderStreamingGameCards(cat, currentSearchTerm);
    };

    // Search games
    window.handleStreamingGameSearch = function (query) {
        const clearBtn = document.getElementById('btnClearGameSearch');
        if (clearBtn) {
            clearBtn.style.display = query.trim() ? 'block' : 'none';
        }
        renderStreamingGameCards(currentFilter, query);
    };

    window.clearStreamingGameSearch = function () {
        const input = document.getElementById('gameSearchInput');
        if (input) input.value = '';
        const clearBtn = document.getElementById('btnClearGameSearch');
        if (clearBtn) clearBtn.style.display = 'none';
        renderStreamingGameCards(currentFilter, '');
    };

    // ==========================================
    // 11. ENLARGED PREVIEW POPOVER MODAL
    // ==========================================
    function ensureEnlargedModalDOM() {
        if (document.getElementById('gameEnlargedPreviewBackdrop')) return;

        const modalHTML = `
            <div class="game-enlarged-preview-backdrop" id="gameEnlargedPreviewBackdrop" onclick="window.closeEnlargedPreview(event)">
                <div class="game-enlarged-preview-card" id="gameEnlargedPreviewCard" onclick="event.stopPropagation();" role="dialog" aria-modal="true" aria-labelledby="enlargedGameTitle">
                    <button type="button" class="btn-enlarged-close" onclick="window.closeEnlargedPreview()" aria-label="Close enlarged preview">&times;</button>
                    
                    <div class="enlarged-video-box">
                        <video class="enlarged-video" id="enlargedVideoEl" muted loop playsinline></video>
                        <img class="enlarged-poster-fallback" id="enlargedPosterEl" alt="">
                        <div class="enlarged-video-gradient"></div>
                        <div class="enlarged-live-badge">
                            <span class="preview-rec-dot is-recording"></span>
                            <span>GAMEPLAY PREVIEW</span>
                        </div>
                        <div class="preview-progress-track">
                            <div class="preview-progress-bar" id="enlargedProgressBar"></div>
                        </div>
                    </div>

                    <div class="enlarged-body">
                        <div class="enlarged-header">
                            <h3 class="enlarged-title" id="enlargedGameTitle">PvZ Fusion 4.0</h3>
                            <span class="enlarged-tag" id="enlargedGameTag">Official • Live Ready</span>
                        </div>
                        <p class="enlarged-desc" id="enlargedGameDesc">Direct mod injection with full live audience interactivity and spawns.</p>
                        
                        <div class="enlarged-features-wrap">
                            <div class="enlarged-features-label">INTEGRATED FEATURES:</div>
                            <div class="enlarged-chips" id="enlargedFeaturesChips"></div>
                        </div>

                        <div class="enlarged-footer">
                            <button type="button" class="btn-enlarged-select" id="btnEnlargedSelect" onclick="window.selectFromEnlargedPreview()">
                                <span id="enlargedBtnLabel">Select this game</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', modalHTML);

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                window.closeEnlargedPreview();
            }
        });
    }

    window.openEnlargedPreview = function (gameId, ev) {
        if (ev) ev.stopPropagation();
        ensureEnlargedModalDOM();

        const game = STREAMING_GAMES_CATALOG.find(g => g.id === gameId);
        if (!game) return;

        enlargedActiveGameId = gameId;
        const backdrop = document.getElementById('gameEnlargedPreviewBackdrop');
        const card = document.getElementById('gameEnlargedPreviewCard');
        const video = document.getElementById('enlargedVideoEl');
        const poster = document.getElementById('enlargedPosterEl');
        const title = document.getElementById('enlargedGameTitle');
        const tag = document.getElementById('enlargedGameTag');
        const desc = document.getElementById('enlargedGameDesc');
        const chipsWrap = document.getElementById('enlargedFeaturesChips');
        const btnLabel = document.getElementById('enlargedBtnLabel');
        const progressBar = document.getElementById('enlargedProgressBar');

        if (!backdrop || !card) return;

        card.style.setProperty('--popover-accent', game.accent);
        card.style.setProperty('--popover-accent-rgb', game.accentRgb);
        card.style.setProperty('--popover-accent-2', game.accent2);

        title.textContent = game.name;
        tag.textContent = game.tag;
        desc.textContent = `${game.subtitle}. Features: ${game.featureCounts}.`;

        const isSelected = (game.id === getActiveStreamingGameId());
        btnLabel.textContent = isSelected ? 'Selected ✓' : 'Select this game';

        // Feature chips
        chipsWrap.innerHTML = game.features.map(feat => `
            <span class="enlarged-chip">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"></polyline></svg>
                <span>${feat}</span>
            </span>
        `).join('');

        // Video playback in enlarged card
        if (video) {
            if (game.previewVideo) {
                video.src = game.previewVideo;
                video.poster = game.previewPoster || game.poster;
                video.muted = true;
                video.ontimeupdate = function () {
                    if (progressBar && video.duration) {
                        progressBar.style.width = ((video.currentTime / video.duration) * 100) + '%';
                    }
                };
                video.onerror = function () {
                    video.style.display = 'none';
                    if (poster) {
                        poster.src = game.poster;
                        poster.style.display = 'block';
                    }
                };
                video.style.display = 'block';
                if (poster) poster.style.display = 'none';
                video.play().catch(() => {});
            } else {
                video.style.display = 'none';
                if (poster) {
                    poster.src = game.poster;
                    poster.style.display = 'block';
                }
            }
        }

        backdrop.classList.add('is-open');
    };

    window.closeEnlargedPreview = function (ev) {
        if (ev && ev.target && ev.target.closest('#gameEnlargedPreviewCard') && !ev.target.classList.contains('btn-enlarged-close')) {
            return;
        }
        const backdrop = document.getElementById('gameEnlargedPreviewBackdrop');
        const video = document.getElementById('enlargedVideoEl');
        if (backdrop) backdrop.classList.remove('is-open');
        if (video) {
            try { video.pause(); video.currentTime = 0; } catch (_) {}
        }
        enlargedActiveGameId = null;
    };

    window.selectFromEnlargedPreview = function () {
        if (enlargedActiveGameId) {
            window.handleSwitchGameClick(enlargedActiveGameId);
            window.closeEnlargedPreview();
        }
    };

    // ==========================================
    // 12. INITIALIZATION
    // ==========================================
    function init() {
        updatePauseButtonUI(isPreviewsPaused());
        renderRecentGamesBar();
        renderStreamingGameCards('all', '');
        setupIntersectionObserver();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
