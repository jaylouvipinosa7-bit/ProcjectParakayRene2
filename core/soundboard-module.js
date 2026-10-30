/**
 * Streamer Soundboard & SFX Vault Engine
 * Powers the interactive Soundboard tab, catalog filtering, audio playback,
 * favorite pinning, and auto-audio ducking integration.
 */

(function () {
    'use strict';

    // State
    let soundsCatalog = [];
    let filteredSounds = [];
    let activeTag = 'All';
    let searchQuery = '';
    let masterVolume = 1.0;
    let duckOnSFX = true;
    let allowOverlap = true;
    let activeAudioInstances = new Map(); // soundId -> HTMLAudioElement

    // Load favorites from localStorage
    let favorites = new Set();
    try {
        const savedFavs = JSON.parse(localStorage.getItem('studio_soundboard_favorites') || '[]');
        if (Array.isArray(savedFavs)) favorites = new Set(savedFavs);
    } catch (e) {
        favorites = new Set();
    }

    // Load soundboard settings
    try {
        const savedVol = localStorage.getItem('studio_soundboard_vol');
        if (savedVol !== null) masterVolume = Math.max(0, Math.min(1, parseFloat(savedVol)));
        const savedDuck = localStorage.getItem('studio_soundboard_duck');
        if (savedDuck !== null) duckOnSFX = savedDuck === 'true';
    } catch (e) {}

    // Color mapper for tags
    function getTagColor(tag) {
        const map = {
            'Meme': { bg: 'rgba(236, 72, 153, 0.15)', border: 'rgba(236, 72, 153, 0.4)', text: '#f472b6', icon: '🔥' },
            'Sound Effects': { bg: 'rgba(56, 189, 248, 0.15)', border: 'rgba(56, 189, 248, 0.4)', text: '#38bdf8', icon: '💥' },
            'Games': { bg: 'rgba(16, 185, 129, 0.15)', border: 'rgba(16, 185, 129, 0.4)', text: '#34d399', icon: '🎮' },
            'Reactions': { bg: 'rgba(234, 179, 8, 0.15)', border: 'rgba(234, 179, 8, 0.4)', text: '#facc15', icon: '😂' },
            'Music': { bg: 'rgba(168, 85, 247, 0.15)', border: 'rgba(168, 85, 247, 0.4)', text: '#c084fc', icon: '🎵' },
            'Anime': { bg: 'rgba(249, 115, 22, 0.15)', border: 'rgba(249, 115, 22, 0.4)', text: '#fb923c', icon: '⚔️' },
            'Local': { bg: 'rgba(100, 116, 139, 0.2)', border: 'rgba(100, 116, 139, 0.4)', text: '#94a3b8', icon: '📁' }
        };
        return map[tag] || { bg: 'rgba(255,255,255,0.08)', border: 'rgba(255,255,255,0.15)', text: '#cbd5e1', icon: '🔊' };
    }

    // Fetch sound catalog from server
    async function fetchSoundCatalog() {
        try {
            const res = await fetch('/api/sounds');
            if (res.ok) {
                const data = await res.json();
                if (Array.isArray(data) && data.length > 0) {
                    soundsCatalog = data;
                } else if (data && Array.isArray(data.sounds) && data.sounds.length > 0) {
                    soundsCatalog = data.sounds;
                }
            } else {
                throw new Error('HTTP ' + res.status);
            }
        } catch (e) {
            console.warn('[Soundboard] Could not load /api/sounds, trying sounds_catalog.json fallback:', e);
            try {
                const res2 = await fetch('sounds_catalog.json');
                if (res2.ok) {
                    const data2 = await res2.json();
                    if (Array.isArray(data2) && data2.length > 0) {
                        soundsCatalog = data2;
                    }
                }
            } catch (err2) {
                console.warn('[Soundboard] Using catalog fallback:', err2);
            }
        }
        applySoundFilters();
    }

    // Apply active category and search filter
    function applySoundFilters() {
        let list = soundsCatalog;

        if (activeTag === 'Favorites') {
            list = list.filter(s => favorites.has(s.id));
        } else if (activeTag !== 'All') {
            list = list.filter(s => (s.tag || 'Meme').toLowerCase() === activeTag.toLowerCase());
        }

        if (searchQuery.trim()) {
            const q = searchQuery.toLowerCase().trim();
            list = list.filter(s => {
                const nameMatch = (s.title || s.name || '').toLowerCase().includes(q);
                const tagMatch = (s.tag || '').toLowerCase().includes(q);
                return nameMatch || tagMatch;
            });
        }

        filteredSounds = list;
        renderSoundboardUI();
    }

    // Toggle favorite state
    function toggleFavorite(id, event) {
        if (event) event.stopPropagation();
        if (favorites.has(id)) {
            favorites.delete(id);
        } else {
            favorites.add(id);
        }
        try {
            localStorage.setItem('studio_soundboard_favorites', JSON.stringify(Array.from(favorites)));
        } catch (e) {}

        applySoundFilters();
    }

    // Play a specific sound by ID or item
    function playSound(item) {
        if (!item || !item.file) return;

        // If not allowing overlap, stop all other active soundboard sounds first
        if (!allowOverlap) {
            stopAllSounds();
        }

        // If this exact sound is already playing, stop it
        if (activeAudioInstances.has(item.id)) {
            const existing = activeAudioInstances.get(item.id);
            try {
                existing.pause();
                existing.currentTime = 0;
            } catch (e) {}
            activeAudioInstances.delete(item.id);
            updatePadActiveState(item.id, false);
            checkDuckingStatus();
            return;
        }

        // Create new audio instance
        const audioUrl = '/' + item.file.replace(/^\/+/, '');
        const audio = new Audio(audioUrl);
        const itemVol = typeof item.volume === 'number' ? item.volume : 1.0;
        audio.volume = Math.max(0, Math.min(1, itemVol * masterVolume));

        activeAudioInstances.set(item.id, audio);
        updatePadActiveState(item.id, true);

        // Auto-duck song request background music if enabled
        if (duckOnSFX && typeof window.duckSongVolume === 'function') {
            window.duckSongVolume(true, 15);
        }

        audio.onended = () => {
            activeAudioInstances.delete(item.id);
            updatePadActiveState(item.id, false);
            checkDuckingStatus();
        };

        audio.onerror = (err) => {
            console.warn('[Soundboard] Playback error on:', item.file, err);
            activeAudioInstances.delete(item.id);
            updatePadActiveState(item.id, false);
            checkDuckingStatus();
            if (typeof showToast === 'function') {
                showToast(`⚠️ Could not play sound "${item.title || item.name}"`, 'warning');
            }
        };

        audio.play().catch(err => {
            console.warn('[Soundboard] Autoplay rejected:', err);
            activeAudioInstances.delete(item.id);
            updatePadActiveState(item.id, false);
            checkDuckingStatus();
        });
    }

    // Stop a single sound
    function stopSound(id) {
        if (activeAudioInstances.has(id)) {
            const audio = activeAudioInstances.get(id);
            try {
                audio.pause();
                audio.currentTime = 0;
            } catch (e) {}
            activeAudioInstances.delete(id);
            updatePadActiveState(id, false);
            checkDuckingStatus();
        }
    }

    // Stop all active soundboard sounds
    function stopAllSounds() {
        activeAudioInstances.forEach((audio, id) => {
            try {
                audio.pause();
                audio.currentTime = 0;
            } catch (e) {}
            updatePadActiveState(id, false);
        });
        activeAudioInstances.clear();
        checkDuckingStatus();
        if (typeof showToast === 'function') {
            showToast('🛑 All Soundboard audio stopped', 'info');
        }
    }

    // Check if background music should stay ducked or restore
    function checkDuckingStatus() {
        if (activeAudioInstances.size === 0) {
            if (duckOnSFX && typeof window.duckSongVolume === 'function') {
                // Restore song volume after slight grace period
                setTimeout(() => {
                    if (activeAudioInstances.size === 0) {
                        window.duckSongVolume(false);
                    }
                }, 150);
            }
        }
    }

    // Play random meme sound
    function playRandomMeme() {
        const pool = soundsCatalog.filter(s => (s.tag || 'Meme').toLowerCase() === 'meme' || s.tag === 'Reactions');
        if (pool.length === 0) return;
        const randomItem = pool[Math.floor(Math.random() * pool.length)];
        playSound(randomItem);
        if (typeof showToast === 'function') {
            showToast(`🎲 Playing Random SFX: "${randomItem.title || randomItem.name}"`, 'success');
        }
    }

    // Update pad visual state (animated waves and active border)
    function updatePadActiveState(id, isPlaying) {
        const pad = document.getElementById(`sfxPad_${id}`);
        if (!pad) return;
        const waves = pad.querySelector('.sfx-playing-wave');
        const playBtn = pad.querySelector('.sfx-play-icon');

        if (isPlaying) {
            pad.style.borderColor = '#10b981';
            pad.style.boxShadow = '0 0 16px rgba(16, 185, 129, 0.4)';
            pad.style.background = 'rgba(16, 185, 129, 0.12)';
            if (waves) waves.style.display = 'flex';
            if (playBtn) playBtn.innerHTML = '⏹';
        } else {
            pad.style.borderColor = 'rgba(255, 255, 255, 0.08)';
            pad.style.boxShadow = 'none';
            pad.style.background = 'rgba(15, 23, 42, 0.65)';
            if (waves) waves.style.display = 'none';
            if (playBtn) playBtn.innerHTML = '▶';
        }
    }

    // Inject dedicated CSS
    function injectSoundboardStyles() {
        if (document.getElementById('soundboardCustomStyles')) return;
        const style = document.createElement('style');
        style.id = 'soundboardCustomStyles';
        style.textContent = `
            .sfx-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
                gap: 12px;
                max-height: calc(100vh - 280px);
                overflow-y: auto;
                padding-right: 6px;
            }
            .sfx-grid::-webkit-scrollbar {
                width: 6px;
            }
            .sfx-grid::-webkit-scrollbar-thumb {
                background: rgba(255, 255, 255, 0.2);
                border-radius: 4px;
            }
            .sfx-pad-card {
                background: rgba(15, 23, 42, 0.7);
                border: 1.5px solid rgba(255, 255, 255, 0.08);
                border-radius: 12px;
                padding: 12px 14px;
                cursor: pointer;
                transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
                display: flex;
                flex-direction: column;
                justify-content: space-between;
                position: relative;
                overflow: hidden;
            }
            .sfx-pad-card:hover {
                transform: translateY(-2px);
                border-color: rgba(56, 189, 248, 0.4);
                background: rgba(30, 41, 59, 0.75);
                box-shadow: 0 6px 18px rgba(0, 0, 0, 0.4);
            }
            .sfx-wave-bar {
                width: 3px;
                background: #10b981;
                border-radius: 2px;
                animation: sfxWaveAnim 0.7s ease-in-out infinite alternate;
            }
            .sfx-wave-bar:nth-child(1) { height: 35%; animation-delay: 0.1s; }
            .sfx-wave-bar:nth-child(2) { height: 95%; animation-delay: 0.25s; }
            .sfx-wave-bar:nth-child(3) { height: 60%; animation-delay: 0.15s; }
            .sfx-wave-bar:nth-child(4) { height: 100%; animation-delay: 0.3s; }
            @keyframes sfxWaveAnim {
                0% { height: 20%; }
                100% { height: 100%; }
            }
        `;
        document.head.appendChild(style);
    }

    // Render the complete Soundboard UI into #tab-soundboard
    function renderSoundboardUI() {
        const container = document.getElementById('tab-soundboard');
        if (!container) return;

        injectSoundboardStyles();

        // Calculate counts
        const totalCount = soundsCatalog.length;
        const favCount = favorites.size;
        const countsByTag = {};
        soundsCatalog.forEach(s => {
            const t = s.tag || 'Meme';
            countsByTag[t] = (countsByTag[t] || 0) + 1;
        });

        const categories = [
            { id: 'All', label: 'All Sounds', icon: '🌐', count: totalCount },
            { id: 'Meme', label: 'Memes', icon: '🔥', count: countsByTag['Meme'] || 0 },
            { id: 'Sound Effects', label: 'Sound FX', icon: '💥', count: countsByTag['Sound Effects'] || 0 },
            { id: 'Games', label: 'Games & PvZ', icon: '🎮', count: countsByTag['Games'] || 0 },
            { id: 'Reactions', label: 'Reactions', icon: '😂', count: countsByTag['Reactions'] || 0 },
            { id: 'Music', label: 'Music Stings', icon: '🎵', count: countsByTag['Music'] || 0 },
            { id: 'Favorites', label: 'Favorites', icon: '⭐', count: favCount }
        ];

        container.innerHTML = `
            <div style="display: flex; flex-direction: column; gap: 16px;">
                
                <!-- TOP HEADER & CONTROLS BAR -->
                <div style="background: linear-gradient(135deg, rgba(15, 23, 42, 0.95) 0%, rgba(10, 15, 28, 0.95) 100%); border: 1.5px solid rgba(255, 255, 255, 0.1); border-radius: 16px; padding: 18px 22px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 16px; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);">
                    <div style="display: flex; align-items: center; gap: 14px;">
                        <div style="font-size: 30px; background: rgba(244, 63, 94, 0.15); border: 1px solid rgba(244, 63, 94, 0.4); width: 50px; height: 50px; border-radius: 12px; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 15px rgba(244, 63, 94, 0.2);">
                            🔊
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <h2 style="font-size: 19px; font-weight: 800; color: #f8fafc; letter-spacing: -0.3px; margin: 0;">Streamer Soundboard & SFX Vault</h2>
                                <span style="background: rgba(244, 63, 94, 0.2); color: #fb7185; border: 1px solid rgba(244, 63, 94, 0.4); font-size: 10px; font-weight: 800; padding: 3px 8px; border-radius: 999px;">
                                    ${totalCount} FX READY
                                </span>
                            </div>
                            <p style="font-size: 12px; color: #94a3b8; margin-top: 3px; margin-bottom: 0;">
                                Trigger meme audio, crowd reactions, and game sound effects with 1-click & auto-audio ducking.
                            </p>
                        </div>
                    </div>

                    <!-- ACTION BUTTONS & DUCKING CONTROLS -->
                    <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                        <!-- Master Volume -->
                        <div style="display: flex; align-items: center; gap: 8px; background: #0b1120; border: 1px solid rgba(255,255,255,0.1); padding: 7px 12px; border-radius: 10px;">
                            <span style="font-size: 13px;">🔊</span>
                            <input type="range" min="0" max="100" value="${Math.round(masterVolume * 100)}"
                                oninput="window.setSoundboardMasterVolume(this.value / 100)"
                                style="width: 85px; accent-color: #f43f5e; cursor: pointer;">
                            <span id="sfxMasterVolLabel" style="font-size: 11.5px; font-weight: 700; color: #cbd5e1; min-width: 32px;">${Math.round(masterVolume * 100)}%</span>
                        </div>

                        <!-- Auto-Ducking Toggle -->
                        <label title="When enabled, playing a sound effect automatically lowers Song Request background music smoothly"
                            style="display: flex; align-items: center; gap: 7px; background: #0b1120; border: 1px solid rgba(255,255,255,0.1); padding: 7px 12px; border-radius: 10px; cursor: pointer; user-select: none;">
                            <input type="checkbox" ${duckOnSFX ? 'checked' : ''} onchange="window.toggleSoundboardDucking(this.checked)"
                                style="transform: scale(1.15); accent-color: #38bdf8; cursor: pointer;">
                            <span style="font-size: 12px; font-weight: 700; color: #cbd5e1;">🎙️ Duck Music</span>
                        </label>

                        <!-- Random Meme Button -->
                        <button type="button" onclick="window.playRandomMemeSound()"
                            style="background: linear-gradient(135deg, rgba(168, 85, 247, 0.25) 0%, rgba(236, 72, 153, 0.25) 100%); border: 1px solid rgba(168, 85, 247, 0.5); color: #e9d5ff; font-size: 12px; font-weight: 800; padding: 8px 14px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s ease;">
                            <span>🎲</span> <span>Random Meme</span>
                        </button>

                        <!-- Stop All Sounds Button -->
                        <button type="button" onclick="window.stopAllSoundboardSounds()"
                            style="background: rgba(239, 68, 68, 0.2); border: 1.5px solid rgba(239, 68, 68, 0.5); color: #fca5a5; font-size: 12px; font-weight: 800; padding: 8px 16px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; gap: 6px; box-shadow: 0 0 10px rgba(239, 68, 68, 0.2); transition: all 0.2s ease;">
                            <span>🛑</span> <span>Stop All</span>
                        </button>
                    </div>
                </div>

                <!-- SEARCH & CATEGORY FILTER STRIP -->
                <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;">
                    
                    <!-- CATEGORY PILLS -->
                    <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                        ${categories.map(c => `
                            <button type="button" onclick="window.filterSoundboardCategory('${c.id}')"
                                style="background: ${activeTag === c.id ? '#f43f5e' : 'rgba(255, 255, 255, 0.05)'}; border: 1px solid ${activeTag === c.id ? '#f43f5e' : 'rgba(255, 255, 255, 0.1)'}; color: ${activeTag === c.id ? '#ffffff' : '#94a3b8'}; padding: 6px 12px; border-radius: 8px; font-size: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.15s ease;">
                                <span>${c.icon}</span>
                                <span>${c.label}</span>
                                <span style="background: rgba(0,0,0,0.25); padding: 1px 6px; border-radius: 6px; font-size: 10.5px; opacity: 0.85;">${c.count}</span>
                            </button>
                        `).join('')}
                    </div>

                    <!-- SEARCH INPUT -->
                    <div style="position: relative; width: 260px;">
                        <input type="text" id="sfxSearchInput" value="${searchQuery}" placeholder="Search sounds, memes..."
                            oninput="window.setSoundboardSearch(this.value)"
                            style="width: 100%; background: #0f172a; border: 1px solid rgba(255, 255, 255, 0.12); color: #f8fafc; padding: 7px 12px 7px 32px; border-radius: 8px; font-size: 12.5px; outline: none; transition: border-color 0.2s ease;">
                        <span style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); font-size: 12px; color: #64748b;">🔍</span>
                        ${searchQuery ? `
                            <button type="button" onclick="window.setSoundboardSearch('')" style="position: absolute; right: 8px; top: 50%; transform: translateY(-50%); background: none; border: none; color: #94a3b8; cursor: pointer; font-size: 12px;">✕</button>
                        ` : ''}
                    </div>
                </div>

                <!-- SOUND PADS GRID -->
                <div class="sfx-grid">
                    ${filteredSounds.length === 0 ? `
                        <div style="grid-column: 1 / -1; text-align: center; padding: 60px 20px; color: #64748b; background: rgba(15, 23, 42, 0.5); border-radius: 14px; border: 1px dashed rgba(255, 255, 255, 0.1);">
                            <div style="font-size: 40px; margin-bottom: 10px;">🔍</div>
                            <div style="font-size: 15px; font-weight: 700; color: #94a3b8;">No matching sound effects found</div>
                            <div style="font-size: 12px; margin-top: 4px;">Try a different search word or select "All Sounds".</div>
                        </div>
                    ` : filteredSounds.map(item => {
                        const isFav = favorites.has(item.id);
                        const isPlaying = activeAudioInstances.has(item.id);
                        const tagStyle = getTagColor(item.tag || 'Meme');
                        const cleanTitle = (item.title || item.name || 'Sound FX')
                            .replace(/\.[a-zA-Z0-9]+$/, '')
                            .replace(/[-_]/g, ' ');

                        return `
                            <div class="sfx-pad-card" id="sfxPad_${item.id}" onclick="window.playSoundboardItem('${item.id}')"
                                style="${isPlaying ? 'border-color: #10b981; box-shadow: 0 0 16px rgba(16, 185, 129, 0.4); background: rgba(16, 185, 129, 0.12);' : ''}">
                                
                                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px;">
                                    <span style="background: ${tagStyle.bg}; border: 1px solid ${tagStyle.border}; color: ${tagStyle.text}; font-size: 10px; font-weight: 800; padding: 2px 7px; border-radius: 6px; display: inline-flex; align-items: center; gap: 4px;">
                                        <span>${tagStyle.icon}</span> <span>${item.tag || 'Meme'}</span>
                                    </span>
                                    
                                    <button type="button" onclick="window.toggleSoundboardFavorite('${item.id}', event)"
                                        title="${isFav ? 'Remove from favorites' : 'Star as favorite'}"
                                        style="background: none; border: none; font-size: 14px; cursor: pointer; color: ${isFav ? '#eab308' : '#475569'}; transition: transform 0.15s ease;"
                                        onmouseover="this.style.transform='scale(1.2)'" onmouseout="this.style.transform='scale(1)'">
                                        ${isFav ? '⭐' : '☆'}
                                    </button>
                                </div>

                                <div style="font-size: 13.5px; font-weight: 800; color: #f8fafc; line-height: 1.3; margin-bottom: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"
                                     title="${cleanTitle}">
                                    ${cleanTitle}
                                </div>

                                <div style="display: flex; align-items: center; justify-content: space-between; padding-top: 8px; border-top: 1px solid rgba(255, 255, 255, 0.06);">
                                    <span style="font-size: 11px; font-family: monospace; color: #64748b;">
                                        ${item.duration ? item.duration.replace(/^00:/, '') : '0:02'}
                                    </span>

                                    <!-- EQUALIZER WAVE (VISIBLE WHEN PLAYING) -->
                                    <div class="sfx-playing-wave" style="display: ${isPlaying ? 'flex' : 'none'}; align-items: flex-end; gap: 2px; height: 14px;">
                                        <div class="sfx-wave-bar"></div>
                                        <div class="sfx-wave-bar"></div>
                                        <div class="sfx-wave-bar"></div>
                                        <div class="sfx-wave-bar"></div>
                                    </div>

                                    <button type="button" class="sfx-play-icon"
                                        style="background: ${isPlaying ? '#ef4444' : '#10b981'}; border: none; color: #fff; width: 26px; height: 26px; border-radius: 50%; font-size: 11px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
                                        ${isPlaying ? '⏹' : '▶'}
                                    </button>
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>

            </div>
        `;
    }

    // Keyboard Shortcuts
    document.addEventListener('keydown', (e) => {
        // Press Escape to kill all active soundboard sounds
        if (e.key === 'Escape' && activeAudioInstances.size > 0) {
            stopAllSounds();
        }
    });

    // Window Exposure
    window.playSoundboardItem = (id) => {
        const item = soundsCatalog.find(s => s.id === id);
        if (item) playSound(item);
    };

    window.toggleSoundboardFavorite = toggleFavorite;
    window.stopAllSoundboardSounds = stopAllSounds;
    window.playRandomMemeSound = playRandomMeme;

    window.filterSoundboardCategory = (cat) => {
        activeTag = cat;
        applySoundFilters();
    };

    window.setSoundboardSearch = (query) => {
        searchQuery = query;
        applySoundFilters();
    };

    window.setSoundboardMasterVolume = (vol) => {
        masterVolume = Math.max(0, Math.min(1, parseFloat(vol) || 1));
        try { localStorage.setItem('studio_soundboard_vol', masterVolume.toString()); } catch (e) {}
        const lbl = document.getElementById('sfxMasterVolLabel');
        if (lbl) lbl.textContent = `${Math.round(masterVolume * 100)}%`;
        activeAudioInstances.forEach(audio => {
            audio.volume = masterVolume;
        });
    };

    window.toggleSoundboardDucking = (enabled) => {
        duckOnSFX = !!enabled;
        try { localStorage.setItem('studio_soundboard_duck', duckOnSFX.toString()); } catch (e) {}
    };

    window.loadSoundboardCatalog = fetchSoundCatalog;
    window.renderSoundboardUI = renderSoundboardUI;

    window.playQuickSFX = function(query) {
        if (!query) return;
        const q = String(query).toLowerCase().replace(/[-_]/g, ' ').trim();
        const found = soundsCatalog.find(s => {
            const t = (s.title || s.name || s.id || '').toLowerCase().replace(/[-_]/g, ' ');
            return t.includes(q);
        });
        if (found) {
            playSound(found.id);
        } else if (soundsCatalog.length > 0) {
            playSound(soundsCatalog[0].id);
        }
    };

    // Auto-init on load
    document.addEventListener('DOMContentLoaded', () => {
        fetchSoundCatalog().then(() => {
            if (typeof renderSoundboardUI === 'function') renderSoundboardUI();
        });
    });

    setTimeout(() => {
        fetchSoundCatalog().then(() => {
            if (typeof renderSoundboardUI === 'function') renderSoundboardUI();
        });
    }, 400);

})();
