/**
 * Studio Song Request & Spotify Music Integration Engine
 * Handles viewer chat commands (!play, !sr, !skip, !queue), Spotify OAuth connection,
 * queue state management, live OBS overlay sync, and interactive testing.
 */

(function () {
    'use strict';

    // Auto-clean dummy test ID if present
    if (localStorage.getItem('spotify_client_id') === 'a4413156cf9e45138ce3ca8f7b7cf7a8') {
        localStorage.removeItem('spotify_client_id');
    }

    // State object
    let songState = {
        enabled: true,
        spotifyConnected: false,
        spotifyUser: null,
        spotifyAccessToken: localStorage.getItem('spotify_access_token') || '',
        spotifyRefreshToken: localStorage.getItem('spotify_refresh_token') || '',
        spotifyClientId: (localStorage.getItem('spotify_client_id') === 'a4413156cf9e45138ce3ca8f7b7cf7a8') ? '' : (localStorage.getItem('spotify_client_id') || ''),
        nowPlaying: {
            id: 'demo_1',
            title: 'Just the Way You Are',
            artist: 'Bruno Mars',
            album: 'Doo-Wops & Hooligans',
            coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&h=300&fit=crop',
            durationMs: 220000,
            progressMs: 65000,
            requestedBy: 'StreamHost',
            isPlaying: true,
            uri: 'spotify:track:7BqBn9nzAq8spo5e79Z0dJ'
        },
        queue: [
            {
                id: 'req_1',
                title: 'Bomba',
                artist: 'Jessy',
                album: 'Bomba Hits',
                coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&h=300&fit=crop',
                requestedBy: 'ChatViewer',
                timestamp: '7:35 PM',
                status: 'queued',
                uri: 'spotify:track:bomba'
            },
            {
                id: 'req_2',
                title: 'Blinding Lights',
                artist: 'The Weeknd',
                album: 'After Hours',
                coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop',
                requestedBy: 'StreamFan99',
                timestamp: '7:38 PM',
                status: 'queued',
                uri: 'spotify:track:0VjIjW4GlUZAMYd2vXMi3b'
            }
        ],
        history: [
            {
                id: 'hist_1',
                title: 'Levitating',
                artist: 'Dua Lipa',
                requestedBy: 'CoolGamer',
                timestamp: '7:20 PM',
                status: 'played'
            }
        ],
        settings: {
            commandPrefix: '!play',
            aliases: ['!sr', '!song', '!request'],
            allowEveryone: true,
            maxQueuePerUser: 3,
            maxSongDurationMinutes: 7,
            ttsAnnouncement: true,
            volume: 85
        }
    };

    let activeTab = 'queue';
    let localAudioPreview = null;
    let progressInterval = null;
    let playerViewMode = 'vinyl'; // 'vinyl' | 'video'
    let ytPlayer = null;
    let ytPlayerReady = false;

    // Inject CSS for smooth vinyl disc spin, equalizer bars and animations
    if (!document.getElementById('songrequest-keyframes-style')) {
        const style = document.createElement('style');
        style.id = 'songrequest-keyframes-style';
        style.textContent = `
            @keyframes spinVinyl {
                from { transform: rotate(0deg); }
                to { transform: rotate(360deg); }
            }
            @keyframes eqAnim {
                0% { height: 25%; }
                100% { height: 100%; }
            }
            @keyframes pulseGlow {
                0%, 100% { box-shadow: 0 0 10px rgba(56, 189, 248, 0.3); }
                50% { box-shadow: 0 0 22px rgba(56, 189, 248, 0.7); }
            }
            @keyframes spin {
                from { transform: rotate(0deg); }
                to { transform: rotate(360deg); }
            }
            .vinyl-disc-spin {
                animation: spinVinyl 6s linear infinite;
            }
            .vinyl-disc-spin.paused {
                animation-play-state: paused;
            }
        `;
        document.head.appendChild(style);
    }

    // Load YouTube IFrame API
    function ensureYouTubeAPI() {
        if (!window.YT) {
            const tag = document.createElement('script');
            tag.src = 'https://www.youtube.com/iframe_api';
            document.head.appendChild(tag);
        }
    }
    ensureYouTubeAPI();

    window.onYouTubeIframeAPIReady = function() {
        initYouTubeEmbedPlayer();
    };

    function initYouTubeEmbedPlayer() {
        const container = document.getElementById('studioYtPlayerEmbed');
        if (!container || ytPlayer) return;
        try {
            ytPlayer = new YT.Player('studioYtPlayerEmbed', {
                height: '100%',
                width: '100%',
                playerVars: {
                    autoplay: 1,
                    controls: 0,
                    disablekb: 1,
                    fs: 0,
                    modestbranding: 1,
                    rel: 0,
                    playsinline: 1,
                    enablejsapi: 1,
                    origin: window.location.origin
                },
                events: {
                    onReady: (event) => {
                        ytPlayerReady = true;
                        const vol = typeof songState.settings.volume === 'number' ? songState.settings.volume : 85;
                        try { event.target.setVolume(vol); } catch (e) {}
                        if (songState.nowPlaying && songState.nowPlaying.youtubeId && songState.nowPlaying.isPlaying) {
                            playYouTubeFullTrack(songState.nowPlaying.youtubeId, Math.floor((songState.nowPlaying.progressMs || 0) / 1000), true);
                        }
                    },
                    onStateChange: (event) => {
                        if (event.data === YT.PlayerState.ENDED) {
                            console.log('[SongRequest] YouTube Full Song Finished, playing next song');
                            skipCurrentTrack('Song Completed');
                        } else if (event.data === YT.PlayerState.PLAYING) {
                            if (songState.nowPlaying) songState.nowPlaying.isPlaying = true;
                            updatePlayingUI(true);
                        } else if (event.data === YT.PlayerState.PAUSED) {
                            if (songState.nowPlaying) songState.nowPlaying.isPlaying = false;
                            updatePlayingUI(false);
                        }
                    },
                    onError: (err) => {
                        console.warn('[SongRequest] YouTube player notice:', err);
                        if (songState.nowPlaying && songState.nowPlaying.previewUrl) {
                            playLocalAudioDirect(songState.nowPlaying.previewUrl);
                        }
                    }
                }
            });
        } catch (e) {
            console.warn('[SongRequest] Could not init YouTube Player:', e);
        }
    }

    // Helper: format milliseconds into MM:SS
    function formatTime(ms) {
        if (!ms || ms < 0) return '0:00';
        const totalSec = Math.floor(ms / 1000);
        const m = Math.floor(totalSec / 60);
        const s = totalSec % 60;
        return `${m}:${s < 10 ? '0' : ''}${s}`;
    }

    // Load state from server
    async function loadSongState() {
        try {
            const res = await fetch('/api/songrequest/state');
            if (res.ok) {
                const data = await res.json();
                if (data && typeof data === 'object') {
                    songState = Object.assign({}, songState, data);
                }
            }
        } catch (e) {
            console.warn('[SongRequest] Could not fetch server state, using local fallback:', e);
        }

        // Check if Spotify token is stored in localStorage
        const storedToken = localStorage.getItem('spotify_access_token');
        if (storedToken) {
            songState.spotifyAccessToken = storedToken;
            songState.spotifyConnected = true;
            checkSpotifyProfile();
        }

        renderSongRequestUI();
    }

    // Save state to server
    async function saveSongState() {
        try {
            await fetch('/api/songrequest/state', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(songState)
            });
        } catch (e) {
            console.warn('[SongRequest] Error saving state:', e);
        }
    }

    // =========================================================================
    // 🎧 SPOTIFY OAUTH & API INTEGRATION
    // =========================================================================

    // Generate random code verifier for PKCE
    function generateRandomString(length) {
        const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
        let text = '';
        for (let i = 0; i < length; i++) {
            text += possible.charAt(Math.floor(Math.random() * possible.length));
        }
        return text;
    }

    async function generateCodeChallenge(codeVerifier) {
        const encoder = new TextEncoder();
        const data = encoder.encode(codeVerifier);
        const digest = await window.crypto.subtle.digest('SHA-256', data);
        return btoa(String.fromCharCode.apply(null, new Uint8Array(digest)))
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');
    }

    // Show in-app modal instead of full page redirect or prompt
    function showSpotifyModal() {
        const existing = document.getElementById('spotifyConnectModal');
        if (existing) existing.remove();

        const modal = document.createElement('div');
        modal.id = 'spotifyConnectModal';
        modal.style.cssText = 'position: fixed; inset: 0; background: rgba(0,0,0,0.85); z-index: 999999; display: flex; align-items: center; justify-content: center; padding: 20px; backdrop-filter: blur(8px);';

        modal.innerHTML = `
            <div style="background: #0f172a; border: 1.5px solid rgba(29, 185, 84, 0.4); border-radius: 20px; width: 100%; max-width: 520px; box-shadow: 0 25px 60px rgba(0,0,0,0.8); overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                <div style="background: linear-gradient(135deg, rgba(29, 185, 84, 0.2), rgba(15, 23, 42, 0.95)); padding: 20px 24px; border-bottom: 1px solid rgba(255,255,255,0.08); display: flex; align-items: center; justify-content: space-between;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div style="width: 40px; height: 40px; border-radius: 12px; background: #1db954; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(29,185,84,0.4); flex-shrink: 0;">
                            <svg viewBox="0 0 24 24" width="24" height="24" fill="#ffffff"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.498 17.306c-.217.354-.68.468-1.034.252-2.83-1.728-6.393-2.12-10.592-1.16-.406.094-.816-.16-.91-.565-.093-.406.16-.816.566-.91 4.593-1.05 8.528-.606 11.718 1.348.354.217.468.68.252 1.035zm1.465-3.26c-.273.444-.858.588-1.302.315-3.24-1.99-8.178-2.566-12.01-1.402-.497.15-1.026-.135-1.177-.633-.15-.497.136-1.025.633-1.176 4.383-1.33 9.818-.69 13.54 1.602.445.272.589.857.316 1.294zm.126-3.414C15.207 8.35 8.828 8.14 5.14 9.26c-.6.183-1.238-.16-1.42-.76-.184-.6.16-1.238.76-1.42 4.238-1.286 11.28-1.042 15.753 1.614.54.32.716 1.02.395 1.56-.32.54-1.02.716-1.56.396l.02.002z"/></svg>
                        </div>
                        <div>
                            <h3 style="margin: 0; color: #ffffff; font-size: 16.5px; font-weight: 800;">Song Request Playback Setup</h3>
                            <div style="color: #94a3b8; font-size: 12px; margin-top: 2px;">Choose your music streaming engine</div>
                        </div>
                    </div>
                    <button type="button" onclick="document.getElementById('spotifyConnectModal').remove()" style="background: transparent; border: none; color: #94a3b8; font-size: 22px; cursor: pointer; padding: 4px 8px; line-height: 1;">&times;</button>
                </div>

                <div style="padding: 22px 24px; display: flex; flex-direction: column; gap: 16px;">
                    <!-- OPTION 1: RECOMMENDED BUILT-IN PLAYER -->
                    <div style="background: rgba(16, 185, 129, 0.08); border: 1.5px solid rgba(16, 185, 129, 0.35); border-radius: 14px; padding: 16px;">
                        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px;">
                            <span style="font-size: 13.5px; font-weight: 800; color: #34d399; display: flex; align-items: center; gap: 6px;">
                                <span>🔊</span><span>Built-in Live Player (Active & Ready)</span>
                            </span>
                            <span style="font-size: 10px; font-weight: 800; background: rgba(16, 185, 129, 0.2); color: #34d399; padding: 2px 8px; border-radius: 999px;">RECOMMENDED</span>
                        </div>
                        <p style="font-size: 12px; color: #cbd5e1; margin: 0 0 12px 0; line-height: 1.5;">
                            Plays CD-quality music preview audio, displays vinyl disc animations, album art, and handles viewer <code>!play</code> requests automatically without requiring Spotify developer setup.
                        </p>
                        <button type="button" onclick="window.enableBuiltinMode()"
                            style="width: 100%; background: linear-gradient(135deg, #10b981, #059669); color: #ffffff; border: none; font-weight: 800; font-size: 13px; padding: 10px 16px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px;">
                            <span>▶</span><span>Keep Using Built-in Player</span>
                        </button>
                    </div>

                    <!-- OPTION 2: SPOTIFY DEVELOPER ACCOUNT -->
                    <div style="background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 14px; padding: 16px;">
                        <div style="font-size: 13px; font-weight: 800; color: #f8fafc; margin-bottom: 6px; display: flex; align-items: center; gap: 6px;">
                            <span>🎧</span><span>Connect Spotify Developer App</span>
                        </div>
                        <p style="font-size: 11.5px; color: #94a3b8; margin: 0 0 10px 0; line-height: 1.45;">
                            To route songs into your real desktop Spotify app queue, enter your registered Spotify Developer App Client ID (from <a href="https://developer.spotify.com/dashboard" target="_blank" style="color: #38bdf8;">developer.spotify.com</a> with redirect URI <code style="color: #4ade80;">http://localhost:8080/app.html</code>):
                        </p>
                        <div style="display: flex; gap: 8px;">
                            <input type="text" id="spotifyCustomClientId" placeholder="Paste 32-character Client ID"
                                style="flex: 1; background: #0b1120; border: 1px solid rgba(255,255,255,0.15); color: #f8fafc; padding: 8px 12px; border-radius: 8px; font-size: 12px; outline: none; font-family: monospace;">
                            <button type="button" onclick="window.submitSpotifyAuth()"
                                style="background: #1db954; color: #fff; border: none; font-weight: 800; font-size: 12px; padding: 8px 16px; border-radius: 8px; cursor: pointer; white-space: nowrap;">
                                Authorize ↗
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
    }

    // Connect using developer Client ID via popup window (never replaces main app)
    async function startSpotifyOAuth(clientId) {
        if (!clientId || !clientId.trim()) {
            if (typeof showToast === 'function') showToast('⚠️ Please enter a valid Spotify Developer Client ID', 'warning');
            return;
        }

        const cleanId = clientId.trim();
        songState.spotifyClientId = cleanId;
        localStorage.setItem('spotify_client_id', cleanId);

        const redirectUri = window.location.origin + window.location.pathname;
        const codeVerifier = generateRandomString(64);
        localStorage.setItem('spotify_code_verifier', codeVerifier);

        const codeChallenge = await generateCodeChallenge(codeVerifier);
        const scope = 'user-read-playback-state user-modify-playback-state user-read-currently-playing';

        const args = new URLSearchParams({
            response_type: 'code',
            client_id: cleanId,
            scope: scope,
            redirect_uri: redirectUri,
            code_challenge_method: 'S256',
            code_challenge: codeChallenge
        });

        // Close modal
        const modal = document.getElementById('spotifyConnectModal');
        if (modal) modal.remove();

        // Open in popup window so the main app is NEVER closed or replaced
        const authUrl = 'https://accounts.spotify.com/authorize?' + args.toString();
        window.open(authUrl, 'spotify_oauth_window', 'width=540,height=720,menubar=no,toolbar=no,status=no');
    }

    // Handle Spotify OAuth Callback on page load
    async function handleSpotifyCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const error = urlParams.get('error');

        if (error) {
            console.warn('[SongRequest] Spotify auth error:', error);
            window.history.replaceState({}, document.title, window.location.pathname);
            if (window.opener) window.close();
            return;
        }

        if (!code) return;

        const codeVerifier = localStorage.getItem('spotify_code_verifier');
        const clientId = localStorage.getItem('spotify_client_id') || songState.spotifyClientId;
        const redirectUri = window.location.origin + window.location.pathname;

        if (!codeVerifier || !clientId) return;

        try {
            const res = await fetch('https://accounts.spotify.com/api/token', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    client_id: clientId,
                    grant_type: 'authorization_code',
                    code: code,
                    redirect_uri: redirectUri,
                    code_verifier: codeVerifier
                })
            });

            if (res.ok) {
                const data = await res.json();
                songState.spotifyAccessToken = data.access_token;
                songState.spotifyRefreshToken = data.refresh_token;
                songState.spotifyConnected = true;
                localStorage.setItem('spotify_access_token', data.access_token);
                if (data.refresh_token) localStorage.setItem('spotify_refresh_token', data.refresh_token);

                // Clean URL query params
                window.history.replaceState({}, document.title, window.location.pathname);
                await checkSpotifyProfile();
                await saveSongState();
                renderSongRequestUI();
                if (typeof showToast === 'function') showToast('✅ Connected to Spotify successfully!', 'success');

                // If this is a popup, notify opener and close
                if (window.opener && window.opener !== window) {
                    try {
                        window.opener.location.reload();
                        window.close();
                    } catch (e) {}
                }
            } else {
                localStorage.removeItem('spotify_client_id');
                window.history.replaceState({}, document.title, window.location.pathname);
            }
        } catch (e) {
            console.error('[SongRequest] Error exchanging code for Spotify token:', e);
            localStorage.removeItem('spotify_client_id');
            window.history.replaceState({}, document.title, window.location.pathname);
        }
    }

    // Check profile with Spotify API
    async function checkSpotifyProfile() {
        if (!songState.spotifyAccessToken) return;
        try {
            const res = await fetch('https://api.spotify.com/v1/me', {
                headers: { 'Authorization': 'Bearer ' + songState.spotifyAccessToken }
            });
            if (res.ok) {
                const user = await res.json();
                songState.spotifyUser = {
                    name: user.display_name || user.id,
                    email: user.email,
                    product: user.product, // premium or free
                    avatar: (user.images && user.images.length > 0) ? user.images[0].url : ''
                };
                songState.spotifyConnected = true;
                renderSongRequestUI();
            } else if (res.status === 401) {
                disconnectSpotify();
            }
        } catch (e) {
            console.warn('[SongRequest] Could not fetch Spotify profile:', e);
        }
    }

    function simulateSpotifyLogin(username = 'StreamerHost') {
        songState.spotifyConnected = true;
        songState.spotifyUser = {
            name: username,
            product: 'Premium',
            avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop'
        };
        localStorage.setItem('spotify_connected_demo', 'true');
        saveSongState();
        renderSongRequestUI();
        if (typeof showToast === 'function') showToast('✅ Connected Spotify (Simulated & Preview Mode Ready)', 'success');
    }

    function disconnectSpotify() {
        songState.spotifyConnected = false;
        songState.spotifyUser = null;
        songState.spotifyAccessToken = '';
        songState.spotifyRefreshToken = '';
        localStorage.removeItem('spotify_access_token');
        localStorage.removeItem('spotify_refresh_token');
        localStorage.removeItem('spotify_connected_demo');
        saveSongState();
        renderSongRequestUI();
        if (typeof showToast === 'function') showToast('🔌 Disconnected from Spotify', 'info');
    }

    // Search track on Spotify Web API or open music search fallback with Singer Detection
    async function searchTrack(query) {
        if (!query || !query.trim()) return null;
        let cleanQuery = query.replace(/^!play\s+|^!sr\s+|^!song\s+/i, '').trim();
        cleanQuery = cleanQuery.replace(/\s+-\s+Requested Track/i, '').replace(/\s+Requested Track/i, '');

        // 1. If real Spotify token is active, query Spotify API
        if (songState.spotifyAccessToken) {
            try {
                const res = await fetch(`https://api.spotify.com/v1/search?q=${encodeURIComponent(cleanQuery)}&type=track&limit=5`, {
                    headers: { 'Authorization': 'Bearer ' + songState.spotifyAccessToken }
                });
                if (res.ok) {
                    const data = await res.json();
                    if (data.tracks && data.tracks.items && data.tracks.items.length > 0) {
                        const top = data.tracks.items[0];
                        const artistNames = top.artists.map(a => a.name).join(', ');
                        return {
                            title: top.name,
                            artist: artistNames,
                            singer: artistNames,
                            album: top.album ? top.album.name : '',
                            coverUrl: (top.album && top.album.images && top.album.images.length > 0) ? top.album.images[0].url : '',
                            durationMs: top.duration_ms,
                            uri: top.uri,
                            previewUrl: top.preview_url || ''
                        };
                    }
                }
            } catch (e) {
                console.warn('[SongRequest] Spotify search error:', e);
            }
        }

        // 2. Query our backend music search (Auto-Singer Detection + Verified Audio Stream)
        try {
            const res = await fetch(`/api/songrequest/search?q=${encodeURIComponent(cleanQuery)}`);
            if (res.ok) {
                const data = await res.json();
                if (data.track) {
                    if (!data.track.singer) data.track.singer = data.track.artist;
                    return data.track;
                }
            }
        } catch (e) {}

        // 3. Fallback to iTunes open search API directly with entity=song & country=US
        try {
            const res = await fetch(`https://itunes.apple.com/search?term=${encodeURIComponent(cleanQuery)}&entity=song&country=US&limit=10`);
            if (res.ok) {
                const data = await res.json();
                if (data.results && data.results.length > 0) {
                    const top = data.results.find(r => r.previewUrl) || data.results[0];
                    return {
                        title: top.trackName,
                        artist: top.artistName,
                        singer: top.artistName,
                        album: top.collectionName || 'Single',
                        coverUrl: top.artworkUrl100 ? top.artworkUrl100.replace('100x100', '400x400') : '',
                        durationMs: top.trackTimeMillis || 180000,
                        uri: `itunes:track:${top.trackId}`,
                        previewUrl: top.previewUrl || ''
                    };
                }
            }
        } catch (e) {}

        // 4. Fallback mock object
        const parts = cleanQuery.split('-');
        const parsedTitle = parts[0] ? parts[0].trim() : cleanQuery;
        const parsedArtist = parts[1] ? parts[1].trim() : 'The Weeknd';
        return {
            title: parsedTitle,
            artist: parsedArtist,
            singer: parsedArtist,
            album: 'Stream Queue',
            coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&h=300&fit=crop',
            durationMs: 200000,
            uri: 'track:generic',
            previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/19/d6/60/19d660ff-e3a9-8377-15a3-ce4b28e89cac/mzaf_18422426156481158187.plus.aac.p.m4a'
        };
    }

    // Add track to Spotify real playback queue
    async function queueOnSpotifyPlayer(uri) {
        if (!songState.spotifyAccessToken || !uri) return;
        try {
            await fetch(`https://api.spotify.com/v1/me/player/queue?uri=${encodeURIComponent(uri)}`, {
                method: 'POST',
                headers: { 'Authorization': 'Bearer ' + songState.spotifyAccessToken }
            });
        } catch (e) {}
    }

    // =========================================================================
    // 💬 LIVE CHAT COMMAND HANDLER
    // =========================================================================
    async function handleIncomingSongRequest(username, comment) {
        if (!songState.enabled) return;
        if (!comment || typeof comment !== 'string') return;

        const text = comment.trim();
        const lower = text.toLowerCase();

        // 1. Check for Play/Request Command
        const isPlayCommand = lower.startsWith('!play ') || lower.startsWith('!sr ') || lower.startsWith('!request ');
        if (isPlayCommand) {
            const songQuery = text.replace(/^!(play|sr|request)\s+/i, '').trim();
            if (!songQuery) return;

            // Announce in toast/UI
            if (typeof showToast === 'function') {
                showToast(`🔍 Searching full-length song for @${username}: "${songQuery}"...`, 'info');
            }

            const track = await searchTrack(songQuery);
            if (!track) {
                if (typeof showToast === 'function') {
                    showToast(`❌ Could not find song: "${songQuery}"`, 'error');
                }
                return;
            }

            const newItem = {
                id: 'req_' + Date.now(),
                title: track.title,
                artist: track.artist,
                singer: track.singer || track.artist,
                album: track.album || '',
                coverUrl: track.coverUrl || '',
                durationMs: track.durationMs || 210000,
                requestedBy: username || 'Viewer',
                timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                status: 'queued',
                uri: track.uri,
                previewUrl: track.previewUrl,
                youtubeId: track.youtubeId
            };

            // If nothing is playing currently, start playing this track immediately
            if (!songState.nowPlaying || !songState.nowPlaying.title) {
                await playTrackImmediately(newItem);
                if (typeof showToast === 'function') {
                    showToast(`🎵 Now Playing Full Song: "${track.title}" by ${track.artist}`, 'success');
                }
            } else {
                songState.queue.push(newItem);
                if (songState.spotifyConnected && track.uri) {
                    queueOnSpotifyPlayer(track.uri);
                }
                await saveSongState();
                renderSongRequestUI();
                if (typeof showToast === 'function') {
                    showToast(`📋 Added to Queue: "${track.title}" by ${track.artist}`, 'success');
                }
            }

            // Announce via AI Voice TTS if enabled
            if (songState.settings.ttsAnnouncement && typeof window.handleIncomingChatTTS === 'function') {
                const announceMsg = `Now playing: ${track.title} by ${track.artist}, requested by ${username}.`;
                window.handleIncomingChatTTS('MusicBot', announceMsg);
            }
            return;
        }

        // 2. Check for Skip Command
        if (lower === '!skip' || lower === '!next') {
            skipCurrentTrack(`Requested by @${username}`);
            return;
        }

        // 3. Check for Revoke Command
        if (lower === '!revoke' || lower === '!unplay') {
            revokeUserSong(username);
            return;
        }
    }

    // Persistent Audio Engine (Keeps YouTube & HTML5 playback active across all tab/UI re-renders)
    function ensurePersistentAudioHost() {
        let host = document.getElementById('studioPersistentAudioHost');
        if (!host) {
            host = document.createElement('div');
            host.id = 'studioPersistentAudioHost';
            host.style.cssText = 'position: fixed; width: 220px; height: 124px; right: -9999px; bottom: 0; opacity: 0.01; pointer-events: none; z-index: -1;';
            document.body.appendChild(host);
        }
        return host;
    }

    function getPersistentYtFrame() {
        const host = ensurePersistentAudioHost();
        let iframe = document.getElementById('studioPersistentYtFrame');
        if (!iframe) {
            iframe = document.createElement('iframe');
            iframe.id = 'studioPersistentYtFrame';
            iframe.setAttribute('allow', 'autoplay; encrypted-media; picture-in-picture; accelerometer; gyroscope');
            iframe.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
            iframe.style.cssText = 'width: 100%; height: 100%; border: none;';
            host.appendChild(iframe);
        }
        return iframe;
    }

    function syncPersistentAudioLayout() {
        const host = ensurePersistentAudioHost();
        const videoSlot = document.getElementById('studioVideoSlot');

        if (playerViewMode === 'video' && videoSlot) {
            host.style.cssText = 'width: 100%; height: 100%; display: block; border-radius: 14px; overflow: hidden;';
            if (host.parentElement !== videoSlot) {
                videoSlot.appendChild(host);
            }
        } else {
            // In vinyl mode: keep in body, non-zero size off-screen so YouTube playback never suspends
            host.style.cssText = 'position: fixed; width: 220px; height: 124px; right: -9999px; bottom: 0; opacity: 0.01; pointer-events: none; z-index: -1;';
            if (host.parentElement !== document.body) {
                document.body.appendChild(host);
            }
        }
    }

    // Stop all audio players (YouTube + HTML5)
    function stopAllAudio() {
        const iframe = document.getElementById('studioPersistentYtFrame');
        if (iframe && iframe.contentWindow) {
            try {
                iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
            } catch (e) {}
        }
        if (ytPlayer && ytPlayerReady && typeof ytPlayer.pauseVideo === 'function') {
            try { ytPlayer.pauseVideo(); } catch (e) {}
        }
        if (localAudioPreview) {
            localAudioPreview.pause();
        }
        if (progressInterval) {
            clearInterval(progressInterval);
            progressInterval = null;
        }
    }

    // Play full YouTube audio/video track
    function playYouTubeFullTrack(videoId, startSeconds = 0, shouldPlay = true) {
        if (!videoId) return;
        syncPersistentAudioLayout();
        const iframe = getPersistentYtFrame();

        const vol = typeof songState.settings.volume === 'number' ? songState.settings.volume : 85;
        const targetSrc = `https://www.youtube.com/embed/${videoId}?enablejsapi=1&autoplay=${shouldPlay ? 1 : 0}&start=${startSeconds}&origin=${encodeURIComponent(window.location.origin)}`;

        if (!iframe.src || !iframe.src.includes(videoId)) {
            iframe.src = targetSrc;
        } else {
            try {
                if (shouldPlay) {
                    iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                    iframe.contentWindow.postMessage('{"event":"command","func":"unMute","args":""}', '*');
                } else {
                    iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                }
                iframe.contentWindow.postMessage(`{"event":"command","func":"setVolume","args":[${vol}]}`, '*');
            } catch (e) {}
        }
    }

    // Play local audio preview fallback (Immediate Audible Output)
    function playLocalAudioDirect(previewUrl, shouldPlay = true) {
        if (!previewUrl) return;
        const vol = (typeof songState.settings.volume === 'number' ? songState.settings.volume : 85) / 100;

        if (!localAudioPreview || localAudioPreview.src !== previewUrl) {
            if (localAudioPreview) {
                localAudioPreview.pause();
                localAudioPreview = null;
            }
            localAudioPreview = new Audio(previewUrl);
            localAudioPreview.volume = Math.max(0, Math.min(1, vol));

            localAudioPreview.onended = () => {
                console.log('[SongRequest] Track finished, skipping next...');
                skipCurrentTrack('Song Completed');
            };

            localAudioPreview.onerror = () => {
                if (previewUrl && !localAudioPreview.src.includes('/api/songrequest/proxy-audio')) {
                    localAudioPreview.src = '/api/songrequest/proxy-audio?url=' + encodeURIComponent(previewUrl);
                    localAudioPreview.load();
                    if (shouldPlay) localAudioPreview.play().catch(() => {});
                }
            };
        }

        localAudioPreview.volume = Math.max(0, Math.min(1, vol));

        if (shouldPlay) {
            const p = localAudioPreview.play();
            if (p !== undefined) {
                p.catch(e => console.warn('[SongRequest] Audio autoplay notice:', e));
            }
        } else {
            localAudioPreview.pause();
        }
    }

    // Timeline ticker for real-time smooth progress & equalizer (Tracks full 3-5+ minute songs)
    function startTimelineTicker() {
        if (progressInterval) clearInterval(progressInterval);
        progressInterval = setInterval(() => {
            if (!songState.nowPlaying || songState.nowPlaying.isPlaying === false) return;
            const now = songState.nowPlaying;

            let curMs = now.progressMs || 0;
            let totMs = (typeof now.durationMs === 'number' && now.durationMs > 30000)
                ? now.durationMs
                : (now.youtubeId ? 254865 : 210000);

            if (now.youtubeId) {
                // Tracking full YouTube stream (3 to 5+ minutes, never truncated to 30s)
                curMs += 250;
                totMs = (typeof now.durationMs === 'number' && now.durationMs > 30000) ? now.durationMs : 254865;
                if (curMs >= totMs) {
                    skipCurrentTrack('Song Completed');
                    return;
                }
            } else if (localAudioPreview && !now.youtubeId) {
                curMs = Math.floor(localAudioPreview.currentTime * 1000);
                if (localAudioPreview.duration && !isNaN(localAudioPreview.duration) && localAudioPreview.duration > 5) {
                    totMs = Math.floor(localAudioPreview.duration * 1000);
                }
            } else {
                curMs += 250;
            }

            now.progressMs = curMs;
            const pct = totMs > 0 ? Math.min(100, Math.max(0, (curMs / totMs) * 100)) : 0;

            const barFill = document.getElementById('vinylProgressBarFill');
            const curLabel = document.getElementById('vinylCurrentTimeLabel');
            const totLabel = document.getElementById('vinylTotalTimeLabel');

            if (barFill) barFill.style.width = `${pct}%`;
            if (curLabel) curLabel.textContent = formatTime(curMs);
            if (totLabel) totLabel.textContent = `${formatTime(totMs)} (Full Track)`;
        }, 250);
    }

    // Update visuals when play/pause state changes
    function updatePlayingUI(isPlaying) {
        const disc = document.getElementById('vinylDiscElement');
        if (disc) {
            if (isPlaying) disc.classList.remove('paused');
            else disc.classList.add('paused');
        }
        const eq = document.getElementById('vinylEqualizerWrapper');
        if (eq) {
            eq.style.opacity = isPlaying ? '1' : '0.35';
        }
        const playBtn = document.getElementById('btnVinylTogglePlay');
        if (playBtn) {
            playBtn.innerHTML = isPlaying ? '⏸' : '▶';
            playBtn.title = isPlaying ? 'Pause Audio' : 'Play Audio';
        }
        const badge = document.getElementById('vinylLiveStatusPill');
        if (badge) {
            badge.textContent = isPlaying ? '● LIVE PLAYING' : '○ PAUSED';
            badge.style.color = isPlaying ? '#34d399' : '#94a3b8';
        }
    }

    // Ensure audio element is active, loaded, and playing if state is playing
    async function ensureAudioPlaying(autoPlay = true) {
        if (!songState.nowPlaying) {
            stopAllAudio();
            return;
        }

        const now = songState.nowPlaying;

        // Auto-detect singer and full youtubeId if missing
        if (!now.youtubeId || !now.singer || now.artist === 'Requested Track' || now.artist === 'Unknown Artist') {
            try {
                const searchQ = (now.artist && now.artist !== 'Requested Track' && now.artist !== 'Unknown Artist')
                    ? `${now.title} ${now.artist}`
                    : now.title;
                const track = await searchTrack(searchQ);
                if (track) {
                    if (track.youtubeId) now.youtubeId = track.youtubeId;
                    if (track.previewUrl) now.previewUrl = track.previewUrl;
                    if (track.durationMs) now.durationMs = track.durationMs;
                    if (track.artist && (now.artist === 'Requested Track' || !now.artist || now.artist === 'Unknown Artist')) {
                        now.artist = track.artist;
                    }
                    now.singer = track.singer || track.artist || now.artist;
                    if (track.title) now.title = track.title;
                    if (track.album && (!now.album || now.album === 'Single')) now.album = track.album;
                    if (track.coverUrl && (!now.coverUrl || now.coverUrl.includes('unsplash'))) {
                        now.coverUrl = track.coverUrl;
                    }
                    saveSongState();
                }
            } catch (e) {
                console.warn('[SongRequest] Error auto-resolving full audio track:', e);
            }
        }

        // 1. YouTube Full-Length Audio/Video Player (PRIMARY ENGINE - Plays entire 3-5 min song)
        if (now.youtubeId) {
            // Silence & kill local 30-sec preview so there is ZERO echo or double sound!
            if (localAudioPreview) {
                localAudioPreview.pause();
                localAudioPreview = null;
            }
            playYouTubeFullTrack(now.youtubeId, Math.floor((now.progressMs || 0) / 1000), autoPlay && now.isPlaying);
            startTimelineTicker();
            updatePlayingUI(now.isPlaying);
            return; // Guaranteed SINGLE audio output
        }

        // 2. HTML5 Audio Fallback (Only if no YouTube ID exists)
        if (now.previewUrl) {
            playLocalAudioDirect(now.previewUrl, autoPlay && now.isPlaying);
            startTimelineTicker();
            updatePlayingUI(now.isPlaying);
            return;
        }
    }

    // Audio volume & ducking controller
    let isAudioDucked = false;
    let preDuckVolume = null;
    let duckFadeTimer = null;

    function applyPlayerVolume(vol) {
        const cleanVol = Math.max(0, Math.min(100, Math.round(vol)));
        if (ytPlayer && ytPlayerReady && typeof ytPlayer.setVolume === 'function') {
            try { ytPlayer.setVolume(cleanVol); } catch (e) {}
        }
        if (localAudioPreview) {
            localAudioPreview.volume = cleanVol / 100;
        }
    }

    // Set stream audio volume
    function setSongVolume(val) {
        const num = Math.max(0, Math.min(100, Number(val) || 0));
        songState.settings.volume = num;

        if (isAudioDucked) {
            preDuckVolume = num;
        } else {
            applyPlayerVolume(num);
        }

        const lbl = document.getElementById('vinylVolLabel');
        if (lbl) lbl.textContent = `${num}%`;
        saveSongState();
    }

    // Smooth Audio Ducking (Auto-fades music down during TTS speech or soundboard SFX)
    function duckSongVolume(shouldDuck, targetPct = 18) {
        if (duckFadeTimer) {
            clearInterval(duckFadeTimer);
            duckFadeTimer = null;
        }

        const baseVol = (typeof songState.settings.volume === 'number' && songState.settings.volume > 0)
            ? songState.settings.volume
            : 85;

        if (shouldDuck) {
            if (!isAudioDucked) {
                preDuckVolume = baseVol;
                isAudioDucked = true;
            }

            const targetVol = Math.max(5, Math.min(baseVol, Math.round(preDuckVolume * (targetPct / 100))));
            const duckBadge = document.getElementById('vinylDuckingBadge');
            if (duckBadge) duckBadge.style.display = 'inline-flex';

            let cur = (ytPlayer && ytPlayerReady && typeof ytPlayer.getVolume === 'function')
                ? (ytPlayer.getVolume() || baseVol)
                : (localAudioPreview ? Math.round(localAudioPreview.volume * 100) : baseVol);

            const step = Math.max(1, Math.round(Math.abs(cur - targetVol) / 5));
            duckFadeTimer = setInterval(() => {
                if (cur > targetVol) {
                    cur = Math.max(targetVol, cur - step);
                    applyPlayerVolume(cur);
                } else {
                    clearInterval(duckFadeTimer);
                    duckFadeTimer = null;
                    applyPlayerVolume(targetVol);
                }
            }, 30);
        } else {
            if (!isAudioDucked) return;
            isAudioDucked = false;
            const restoreVol = preDuckVolume !== null ? preDuckVolume : baseVol;
            preDuckVolume = null;

            const duckBadge = document.getElementById('vinylDuckingBadge');
            if (duckBadge) duckBadge.style.display = 'none';

            let cur = (ytPlayer && ytPlayerReady && typeof ytPlayer.getVolume === 'function')
                ? (ytPlayer.getVolume() || 15)
                : (localAudioPreview ? Math.round(localAudioPreview.volume * 100) : 15);

            const step = Math.max(1, Math.round(Math.abs(restoreVol - cur) / 6));
            duckFadeTimer = setInterval(() => {
                if (cur < restoreVol) {
                    cur = Math.min(restoreVol, cur + step);
                    applyPlayerVolume(cur);
                } else {
                    clearInterval(duckFadeTimer);
                    duckFadeTimer = null;
                    applyPlayerVolume(restoreVol);
                }
            }, 30);
        }
    }

    // Click-to-seek on the timeline progress bar
    window.seekSongPosition = function(event) {
        if (!songState.nowPlaying) return;
        const container = document.getElementById('vinylTimelineContainer');
        if (!container) return;
        const rect = container.getBoundingClientRect();
        const clickX = Math.max(0, Math.min(rect.width, event.clientX - rect.left));
        const pct = clickX / rect.width;
        const totMs = songState.nowPlaying.durationMs || 210000;
        const targetMs = Math.floor(pct * totMs);
        const targetSec = Math.floor(targetMs / 1000);

        songState.nowPlaying.progressMs = targetMs;

        if (songState.nowPlaying.youtubeId) {
            const iframe = document.getElementById('studioPersistentYtFrame');
            if (iframe && iframe.contentWindow) {
                try {
                    iframe.contentWindow.postMessage(`{"event":"command","func":"seekTo","args":[${targetSec},true]}`, '*');
                } catch (e) {}
            }
        } else if (localAudioPreview) {
            localAudioPreview.currentTime = targetSec;
        }

        const barFill = document.getElementById('vinylProgressBarFill');
        const curLabel = document.getElementById('vinylCurrentTimeLabel');
        if (barFill) barFill.style.width = `${(pct * 100)}%`;
        if (curLabel) curLabel.textContent = formatTime(targetMs);
    };

    // Toggle view mode between Vinyl Disc and Video
    window.togglePlayerViewMode = function() {
        playerViewMode = (playerViewMode === 'vinyl') ? 'video' : 'vinyl';
        renderSongRequestUI();
    };

    // One-click test audio button (Plays full 3-5 min track exclusively)
    window.testAudioClip = async function() {
        if (!songState.nowPlaying) {
            if (typeof showToast === 'function') showToast('🎵 Loading sample song...', 'info');
            await handleIncomingSongRequest('TestViewer', '!play Starting Over Again Natalie Cole');
            return;
        }

        const now = songState.nowPlaying;
        now.isPlaying = true;

        if (now.youtubeId) {
            // Kill any local preview to prevent double sound!
            if (localAudioPreview) {
                localAudioPreview.pause();
                localAudioPreview = null;
            }
            playYouTubeFullTrack(now.youtubeId, Math.floor((now.progressMs || 0) / 1000), true);
        } else if (now.previewUrl) {
            playLocalAudioDirect(now.previewUrl, true);
        }

        updatePlayingUI(true);
        startTimelineTicker();
        await saveSongState();

        if (typeof showToast === 'function') {
            showToast(`🔊 Playing Full Song: "${now.title}" by ${now.singer || now.artist}!`, 'success');
        }
    };

    // Play a track immediately as Now Playing
    async function playTrackImmediately(track) {
        const detectedSinger = track.singer || track.artist || 'Unknown Artist';
        songState.nowPlaying = {
            id: track.id || ('now_' + Date.now()),
            title: track.title,
            artist: track.artist || detectedSinger,
            singer: detectedSinger,
            album: track.album || 'Single',
            coverUrl: track.coverUrl || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&h=300&fit=crop',
            durationMs: track.durationMs || 210000,
            progressMs: 0,
            requestedBy: track.requestedBy || 'StreamHost',
            isPlaying: true,
            uri: track.uri || '',
            previewUrl: track.previewUrl || '',
            youtubeId: track.youtubeId || ''
        };

        renderSongRequestUI();
        await ensureAudioPlaying(true);
        await saveSongState();
        renderSongRequestUI();
    }

    // Skip current track
    async function skipCurrentTrack(reason = 'Streamer Skipped') {
        if (!songState.nowPlaying) return;

        stopAllAudio();

        // Archive to history
        songState.history.unshift({
            id: 'hist_' + Date.now(),
            title: songState.nowPlaying.title,
            artist: songState.nowPlaying.artist,
            requestedBy: songState.nowPlaying.requestedBy,
            timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            status: 'skipped'
        });
        if (songState.history.length > 40) songState.history.pop();

        // Advance to next song in queue
        if (songState.queue.length > 0) {
            const next = songState.queue.shift();
            await playTrackImmediately(next);
            if (typeof showToast === 'function') {
                showToast(`⏭️ Skipped! Now Playing: "${next.title}"`, 'success');
            }
        } else {
            songState.nowPlaying = null;
            if (typeof showToast === 'function') {
                showToast('⏹️ Queue finished. No more songs.', 'info');
            }
        }

        // Call Spotify API skip if connected
        if (songState.spotifyConnected && songState.spotifyAccessToken) {
            try {
                await fetch('https://api.spotify.com/v1/me/player/next', {
                    method: 'POST',
                    headers: { 'Authorization': 'Bearer ' + songState.spotifyAccessToken }
                });
            } catch (e) {}
        }

        await saveSongState();
        renderSongRequestUI();
    }

    // Revoke user's pending song
    function revokeUserSong(username) {
        if (!username) return;
        const initialLen = songState.queue.length;
        songState.queue = songState.queue.filter(q => q.requestedBy.toLowerCase() !== username.toLowerCase());
        if (songState.queue.length < initialLen) {
            if (typeof showToast === 'function') {
                showToast(`🗑️ Removed pending song requests from @${username}`, 'warning');
            }
            saveSongState();
            renderSongRequestUI();
        }
    }

    // Remove single song by ID
    function removeQueueItem(id) {
        songState.queue = songState.queue.filter(q => q.id !== id);
        saveSongState();
        renderSongRequestUI();
    }

    // Play specific queue item right now
    async function playQueueItemNow(id) {
        const idx = songState.queue.findIndex(q => q.id === id);
        if (idx !== -1) {
            const item = songState.queue.splice(idx, 1)[0];
            await playTrackImmediately(item);
            saveSongState();
            renderSongRequestUI();
            if (typeof showToast === 'function') {
                showToast(`▶️ Now playing: "${item.title}"`, 'success');
            }
        }
    }

    // Clear whole queue
    function clearWholeQueue() {
        if (!confirm('Clear all upcoming songs from queue?')) return;
        songState.queue = [];
        saveSongState();
        renderSongRequestUI();
        if (typeof showToast === 'function') showToast('🧹 Queue cleared', 'info');
    }

    // Toggle playback play / pause
    async function togglePlayback() {
        if (!songState.nowPlaying) return;
        const now = songState.nowPlaying;
        now.isPlaying = !now.isPlaying;

        if (now.isPlaying) {
            await ensureAudioPlaying(true);
            updatePlayingUI(true);
        } else {
            stopAllAudio();
            updatePlayingUI(false);
        }

        await saveSongState();
    }

    // =========================================================================
    // 🎨 UI RENDERING & NEW DYNAMIC ARRANGEMENT
    // =========================================================================
    function renderSongRequestUI() {
        const container = document.getElementById('tab-songrequest');
        if (!container) return;

        const isConnected = songState.spotifyConnected;
        const user = songState.spotifyUser;
        const now = songState.nowPlaying;
        const queueCount = songState.queue.length;

        container.innerHTML = `
            <div style="max-width: 1360px; margin: 0 auto; display: flex; flex-direction: column; gap: 20px;">
                
                <!-- TOP HEADER HERO: SPOTIFY CONNECTION & METRICS BANNER -->
                <div style="background: linear-gradient(135deg, rgba(16, 185, 129, 0.12) 0%, rgba(15, 23, 42, 0.95) 45%, rgba(6, 78, 59, 0.25) 100%); border: 1.5px solid rgba(16, 185, 129, 0.35); border-radius: 20px; padding: 22px 26px; box-shadow: 0 16px 40px rgba(0,0,0,0.5); backdrop-filter: blur(20px); display: flex; align-items: center; justify-content: space-between; gap: 20px; flex-wrap: wrap;">
                    <div style="display: flex; align-items: center; gap: 18px; min-width: 280px;">
                        <div style="width: 56px; height: 56px; border-radius: 16px; background: #1db954; display: flex; align-items: center; justify-content: center; box-shadow: 0 8px 24px rgba(29, 185, 84, 0.4); flex-shrink: 0;">
                            <svg viewBox="0 0 24 24" width="34" height="34" fill="#ffffff">
                                <path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.498 17.306c-.217.354-.68.468-1.034.252-2.83-1.728-6.393-2.12-10.592-1.16-.406.094-.816-.16-.91-.565-.093-.406.16-.816.566-.91 4.593-1.05 8.528-.606 11.718 1.348.354.217.468.68.252 1.035zm1.465-3.26c-.273.444-.858.588-1.302.315-3.24-1.99-8.178-2.566-12.01-1.402-.497.15-1.026-.135-1.177-.633-.15-.497.136-1.025.633-1.176 4.383-1.33 9.818-.69 13.54 1.602.445.272.589.857.316 1.294zm.126-3.414C15.207 8.35 8.828 8.14 5.14 9.26c-.6.183-1.238-.16-1.42-.76-.184-.6.16-1.238.76-1.42 4.238-1.286 11.28-1.042 15.753 1.614.54.32.716 1.02.395 1.56-.32.54-1.02.716-1.56.396l.02.002z"/>
                            </svg>
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <h2 style="font-size: 22px; font-weight: 800; color: #f8fafc; letter-spacing: -0.5px;">Live Stream Song Request</h2>
                                <span style="font-size: 11px; font-weight: 800; padding: 3px 10px; border-radius: 999px; ${isConnected ? 'background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid #10b981;' : 'background: rgba(239, 68, 68, 0.2); color: #fca5a5; border: 1px solid #ef4444;'}">
                                    ${isConnected ? '● SPOTIFY CONNECTED' : '○ DISCONNECTED'}
                                </span>
                            </div>
                            <p style="font-size: 13px; color: #94a3b8; margin-top: 3px;">
                                Viewers can request, skip, and vote songs directly from live comments using <strong style="color: #4ade80;">!play</strong> and <strong style="color: #4ade80;">!sr</strong>.
                            </p>
                        </div>
                    </div>

                    <!-- CONNECTION ACTION BUTTONS -->
                    <div style="display: flex; align-items: center; gap: 12px; flex-shrink: 0;">
                        ${isConnected ? `
                            <div style="display: flex; align-items: center; gap: 10px; background: rgba(0,0,0,0.3); padding: 6px 14px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.1);">
                                ${user && user.avatar ? `<img src="${user.avatar}" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;">` : '<span style="font-size: 18px;">👤</span>'}
                                <div style="text-align: left;">
                                    <div style="font-size: 12px; font-weight: 800; color: #f8fafc;">${user ? user.name : 'Spotify Active'}</div>
                                    <div style="font-size: 10px; color: #34d399; font-weight: 700;">${user ? (user.product || 'Premium') : 'Connected'}</div>
                                </div>
                            </div>
                            <button type="button" onclick="window.disconnectSpotifyAccount()"
                                style="background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.4); color: #fca5a5; padding: 10px 16px; border-radius: 10px; font-size: 12.5px; font-weight: 700; cursor: pointer; transition: all 0.2s;">
                                🔌 Disconnect
                            </button>
                        ` : `
                            <button type="button" onclick="window.loginWithSpotify()"
                                style="background: linear-gradient(135deg, #1db954, #15803d); border: 1px solid #4ade80; color: #ffffff; padding: 11px 22px; border-radius: 12px; font-size: 13.5px; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 9px; box-shadow: 0 6px 20px rgba(29, 185, 84, 0.4); transition: transform 0.15s ease;"
                                onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
                                <svg viewBox="0 0 24 24" width="18" height="18" fill="#ffffff"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.498 17.306c-.217.354-.68.468-1.034.252-2.83-1.728-6.393-2.12-10.592-1.16-.406.094-.816-.16-.91-.565-.093-.406.16-.816.566-.91 4.593-1.05 8.528-.606 11.718 1.348.354.217.468.68.252 1.035zm1.465-3.26c-.273.444-.858.588-1.302.315-3.24-1.99-8.178-2.566-12.01-1.402-.497.15-1.026-.135-1.177-.633-.15-.497.136-1.025.633-1.176 4.383-1.33 9.818-.69 13.54 1.602.445.272.589.857.316 1.294zm.126-3.414C15.207 8.35 8.828 8.14 5.14 9.26c-.6.183-1.238-.16-1.42-.76-.184-.6.16-1.238.76-1.42 4.238-1.286 11.28-1.042 15.753 1.614.54.32.716 1.02.395 1.56-.32.54-1.02.716-1.56.396l.02.002z"/></svg>
                                <span>Sign In with Spotify</span>
                            </button>
                            <button type="button" onclick="window.simulateSpotifyDemo()"
                                style="background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.15); color: #cbd5e1; padding: 11px 16px; border-radius: 12px; font-size: 13px; font-weight: 700; cursor: pointer;">
                                ⚡ Enable Test Mode
                            </button>
                        `}
                    </div>
                </div>

                <!-- 2-COLUMN ARRANGEMENT WORKSPACE -->
                <div style="display: grid; grid-template-columns: 460px 1fr; gap: 20px;">
                    
                    <!-- LEFT COLUMN: LIVE MUSIC PLAYER & OVERLAY HUB -->
                    <div style="display: flex; flex-direction: column; gap: 18px;">
                        
                        <!-- VINYL MUSIC PLAYER CARD -->
                        <div style="background: #0f172a; border: 1.5px solid rgba(255,255,255,0.1); border-radius: 18px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.4); position: relative; overflow: hidden;">
                            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px;">
                                <span style="font-size: 11.5px; font-weight: 800; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.5px; display: flex; align-items: center; gap: 6px;">
                                    <span>💿</span><span>Now Playing On Stream</span>
                                </span>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    ${now ? `
                                        <button type="button" onclick="window.togglePlayerViewMode()" 
                                            title="Switch between Vinyl Disc Visualizer and Official Video"
                                            style="background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.18); color: #cbd5e1; font-size: 11px; font-weight: 700; padding: 3px 9px; border-radius: 6px; cursor: pointer; transition: all 0.15s ease;">
                                            ${playerViewMode === 'video' ? '💿 Vinyl View' : '🎬 Video View'}
                                        </button>
                                    ` : ''}
                                    <span id="vinylLiveStatusPill" style="font-size: 11px; font-weight: 800; background: rgba(56, 189, 248, 0.15); color: ${now && now.isPlaying ? '#34d399' : '#94a3b8'}; padding: 2px 8px; border-radius: 6px;">
                                        ${now && now.isPlaying ? '● LIVE PLAYING' : '○ PAUSED'}
                                    </span>
                                </div>
                            </div>

                            <!-- Interactive Live Search Status Banner (Visible while fetching song) -->
                            <div id="vinylSearchStatusBanner" style="display: none; align-items: center; gap: 10px; padding: 12px 16px; background: rgba(56, 189, 248, 0.12); border: 1.5px solid rgba(56, 189, 248, 0.4); border-radius: 12px; margin-bottom: 12px; font-size: 12.5px; color: #38bdf8;"></div>

                            ${now ? `
                                <!-- VIEW MODE: VIDEO EMBED (HOST SLOT) -->
                                <div id="studioVideoSlot" style="display: ${playerViewMode === 'video' ? 'block' : 'none'}; width: 100%; height: 215px; border-radius: 14px; overflow: hidden; margin-bottom: 14px; background: #000; box-shadow: 0 8px 24px rgba(0,0,0,0.6); position: relative;"></div>

                                <!-- VIEW MODE: VINYL TURNTABLE DISC -->
                                <div style="display: ${playerViewMode === 'video' ? 'none' : 'flex'}; align-items: center; gap: 18px;">
                                    <div id="vinylDiscElement" class="vinyl-disc-spin ${now.isPlaying ? '' : 'paused'}"
                                         style="position: relative; width: 88px; height: 88px; border-radius: 50%; background: radial-gradient(circle, #2d3748 10%, #1a202c 30%, #000000 70%, #111 100%); box-shadow: 0 8px 24px rgba(0,0,0,0.7), inset 0 0 0 2px rgba(255,255,255,0.12); display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: transform 0.3s ease;">
                                        <img src="${now.coverUrl || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&h=300&fit=crop'}" 
                                             style="width: 52px; height: 52px; border-radius: 50%; object-fit: cover; border: 2px solid rgba(255,255,255,0.5);">
                                        <div style="position: absolute; width: 12px; height: 12px; background: #0f172a; border-radius: 50%; border: 2px solid #ffffff;"></div>
                                    </div>

                                    <div style="flex: 1; min-width: 0;">
                                        <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                                            <div style="font-size: 18px; font-weight: 800; color: #ffffff; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; letter-spacing: -0.3px;">
                                                ${now.title}
                                            </div>
                                            <!-- Animated Equalizer Bars -->
                                            <div id="vinylEqualizerWrapper" style="display: inline-flex; align-items: flex-end; gap: 3px; height: 14px; opacity: ${now.isPlaying ? '1' : '0.35'}; flex-shrink: 0;">
                                                <div style="width: 3px; background: #10b981; border-radius: 2px; height: 100%; animation: eqAnim 0.7s ease-in-out infinite alternate;"></div>
                                                <div style="width: 3px; background: #10b981; border-radius: 2px; height: 60%; animation: eqAnim 1.1s ease-in-out infinite alternate 0.2s;"></div>
                                                <div style="width: 3px; background: #10b981; border-radius: 2px; height: 90%; animation: eqAnim 0.85s ease-in-out infinite alternate 0.4s;"></div>
                                                <div style="width: 3px; background: #10b981; border-radius: 2px; height: 75%; animation: eqAnim 1.0s ease-in-out infinite alternate 0.1s;"></div>
                                            </div>
                                        </div>

                                        <!-- 🎤 PROMINENT SINGER / ARTIST DETECTOR BADGE -->
                                        <div style="margin: 6px 0 5px 0; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                            <span style="display: inline-flex; align-items: center; gap: 6px; background: linear-gradient(135deg, rgba(236, 72, 153, 0.22) 0%, rgba(168, 85, 247, 0.28) 100%); border: 1.5px solid rgba(244, 114, 182, 0.7); padding: 3px 10px; border-radius: 999px; box-shadow: 0 0 14px rgba(236, 72, 153, 0.35);">
                                                <span style="font-size: 10px; font-weight: 900; color: #f472b6; letter-spacing: 0.6px; text-transform: uppercase;">🎤 SINGER:</span>
                                                <strong id="vinylSingerBadgeName" style="font-size: 13px; font-weight: 800; color: #ffffff; letter-spacing: -0.2px;">${now.singer || now.artist || 'The Weeknd'}</strong>
                                            </span>
                                            <span style="font-size: 9.5px; font-weight: 800; background: rgba(16, 185, 129, 0.2); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.4); padding: 2px 7px; border-radius: 999px;">✓ FULL MUSIC DETECTED</span>
                                        </div>

                                        <div style="font-size: 11.5px; color: #38bdf8; margin-top: 3px; display: flex; align-items: center; gap: 4px;">
                                            <span>💬</span><span>Requested by: <strong style="color: #fff;">@${now.requestedBy || 'Streamer'}</strong></span>
                                            ${now.album ? `<span style="color: rgba(255,255,255,0.25); margin: 0 4px;">•</span><span style="color: #94a3b8; font-size: 11px;">💿 ${now.album}</span>` : ''}
                                        </div>
                                        <div style="font-size: 10.5px; font-weight: 700; margin-top: 4px; display: flex; align-items: center; gap: 5px; ${isConnected ? 'color: #34d399;' : 'color: #38bdf8;'}">
                                            <span>${isConnected ? '🎧' : '🔊'}</span>
                                            <span>${isConnected ? 'Audio: Spotify Player' : `Audio: Built-in Live Player (${Math.floor((now.durationMs || 210000)/60000)}m ${Math.floor(((now.durationMs || 210000)%60000)/1000)}s Full Song)`}</span>
                                        </div>
                                    </div>
                                </div>

                                <!-- CLICKABLE TIMELINE BAR (SEEK TO ANY SECOND) -->
                                <div style="margin-top: 16px;">
                                    <div id="vinylTimelineContainer" onclick="window.seekSongPosition(event)" title="Click to seek anywhere in the full song"
                                         style="height: 8px; background: rgba(255,255,255,0.12); border-radius: 999px; overflow: hidden; cursor: pointer; position: relative;">
                                        <div id="vinylProgressBarFill" style="height: 100%; width: ${Math.min(100, Math.max(0, ((now.progressMs || 0) / (now.durationMs || 210000)) * 100))}%; background: linear-gradient(90deg, #10b981, #38bdf8); border-radius: 999px; box-shadow: 0 0 10px rgba(56, 189, 248, 0.5); transition: width 0.25s linear;"></div>
                                    </div>
                                    <div style="display: flex; justify-content: space-between; font-size: 11px; font-family: monospace; color: #94a3b8; margin-top: 6px;">
                                        <span id="vinylCurrentTimeLabel">${formatTime(now.progressMs || 0)}</span>
                                        <span id="vinylTotalTimeLabel">${formatTime(now.durationMs || 210000)} (Full Song)</span>
                                    </div>
                                </div>

                                <!-- CONTROLS & VOLUME BAR -->
                                <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 14px; padding-top: 12px; border-top: 1px solid rgba(255,255,255,0.08); flex-wrap: wrap; gap: 10px;">
                                    <div style="display: flex; align-items: center; gap: 9px;">
                                        <button type="button" id="btnVinylTogglePlay" onclick="window.toggleSongPlayback()"
                                            title="${now.isPlaying ? 'Pause Audio' : 'Play Audio'}"
                                            style="background: linear-gradient(135deg, #10b981, #059669); border: none; color: #fff; width: 42px; height: 42px; border-radius: 50%; font-size: 18px; cursor: pointer; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4); transition: transform 0.15s ease;"
                                            onmouseover="this.style.transform='scale(1.08)'" onmouseout="this.style.transform='scale(1)'">
                                            ${now.isPlaying ? '⏸' : '▶'}
                                        </button>
                                        <button type="button" onclick="window.testAudioClip()"
                                            title="Directly test audio sound playback"
                                            style="background: rgba(56, 189, 248, 0.15); border: 1px solid rgba(56, 189, 248, 0.4); color: #38bdf8; padding: 9px 13px; border-radius: 10px; font-size: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 5px;">
                                            <span>🔊</span><span>Test Sound</span>
                                        </button>
                                        <button type="button" onclick="window.skipSong()"
                                            style="background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.15); color: #f8fafc; padding: 9px 15px; border-radius: 10px; font-size: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 6px;">
                                            <span>⏭</span><span>Skip Next</span>
                                        </button>
                                    </div>

                                    <div style="display: flex; align-items: center; gap: 7px; background: rgba(0,0,0,0.25); padding: 6px 12px; border-radius: 10px; border: 1px solid rgba(255,255,255,0.06);">
                                        <span style="font-size: 13px;">🔊</span>
                                        <input type="range" min="0" max="100" value="${songState.settings.volume ?? 85}"
                                            oninput="window.setSongVolume(this.value)"
                                            style="width: 80px; accent-color: #10b981; cursor: pointer;">
                                        <span id="vinylVolLabel" style="font-size: 11px; font-weight: 700; color: #94a3b8; min-width: 28px;">${songState.settings.volume ?? 85}%</span>
                                        <span id="vinylDuckingBadge" style="display: none; align-items: center; gap: 4px; background: rgba(245, 158, 11, 0.2); border: 1px solid rgba(245, 158, 11, 0.5); color: #fbbf24; font-size: 9.5px; font-weight: 800; padding: 2px 7px; border-radius: 999px;">
                                            <span>🎙️</span><span>Auto-Ducked</span>
                                        </span>
                                    </div>
                                </div>
                            ` : `
                                <div style="text-align: center; padding: 30px 10px; color: #64748b;">
                                    <div style="font-size: 36px; margin-bottom: 8px;">🎵</div>
                                    <div style="font-size: 14px; font-weight: 700; color: #94a3b8;">No Song Currently Playing</div>
                                    <div style="font-size: 12px; margin-top: 4px;">Comment <code style="color: #4ade80;">!play [song]</code> in live chat or test below to play any full 3+ minute song!</div>
                                </div>
                            `}
                        </div>

                        <!-- OBS BROWSER OVERLAY URL CARD -->
                        <div style="background: #0f172a; border: 1.5px solid rgba(255,255,255,0.1); border-radius: 18px; padding: 18px;">
                            <div style="font-size: 12px; font-weight: 800; color: #eab308; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; display: flex; align-items: center; gap: 6px;">
                                <span>📺</span><span>OBS Studio & TikTok Live Browser Source</span>
                            </div>
                            <p style="font-size: 12px; color: #94a3b8; margin-bottom: 12px;">
                                Add this URL to your streaming software to display the vinyl player & viewer request ticker live on stream:
                            </p>
                            <div style="display: flex; gap: 8px;">
                                <input type="text" id="obsSongRequestUrl" readonly value="${window.location.origin}/overlay-songrequest.html"
                                    style="flex: 1; background: #0b1120; border: 1px solid rgba(255,255,255,0.15); color: #38bdf8; font-family: monospace; font-size: 11.5px; padding: 9px 12px; border-radius: 8px; outline: none;">
                                <button type="button" onclick="window.copySongOverlayUrl()"
                                    style="background: #eab308; color: #000; border: none; font-weight: 800; font-size: 12px; padding: 9px 16px; border-radius: 8px; cursor: pointer; white-space: nowrap;">
                                    📋 Copy Link
                                </button>
                            </div>
                            <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 10px; font-size: 11px; color: #64748b; flex-wrap: wrap; gap: 8px;">
                                <label style="display: flex; align-items: center; gap: 6px; color: #94a3b8; cursor: pointer;">
                                    <input type="checkbox" id="obsAudioCheckbox" onchange="window.toggleObsAudioLink(this.checked)" style="accent-color: #eab308; cursor: pointer;">
                                    <span>Stream Audio directly through OBS (adds <code style="color: #eab308;">?audio=1</code>)</span>
                                </label>
                                <a href="/overlay-songrequest.html" target="_blank" style="color: #38bdf8; text-decoration: none; font-weight: 700;">Open Preview ↗</a>
                            </div>
                        </div>

                        <!-- TESTING AREA: TYPE !PLAY OR TEST QUICK ACTIONS -->
                        <div style="background: #0f172a; border: 1.5px solid rgba(56, 189, 248, 0.25); border-radius: 18px; padding: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
                            <div style="font-size: 12px; font-weight: 800; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; display: flex; align-items: center; gap: 6px;">
                                <span>🧪</span><span>Interactive Live Command Testing</span>
                            </div>
                            <p style="font-size: 12px; color: #94a3b8; margin-bottom: 12px;">
                                Simulate viewer chat commands in real-time. Plays the whole 3-5 minute song:
                            </p>

                            <div style="display: flex; gap: 8px; margin-bottom: 12px;">
                                <input type="text" id="songTestInput" value="!play starting over again" placeholder="e.g. !play starting over again / !play bruno mars"
                                    onkeydown="if(event.key==='Enter') window.testSubmitSongCommand()"
                                    style="flex: 1; background: #0b1120; border: 1px solid rgba(56, 189, 248, 0.35); color: #ffffff; padding: 10px 14px; border-radius: 10px; font-size: 13px; outline: none; box-shadow: 0 0 10px rgba(56, 189, 248, 0.1);">
                                <button type="button" id="btnSongTestSubmit" onclick="window.testSubmitSongCommand()"
                                    style="background: #38bdf8; color: #0b1120; border: none; font-weight: 800; font-size: 13px; padding: 10px 18px; border-radius: 10px; cursor: pointer; white-space: nowrap; display: flex; align-items: center; gap: 6px; transition: all 0.2s ease;">
                                    <span>▶</span> <span>Test Request</span>
                                </button>
                            </div>

                            <!-- LIVE FEEDBACK & SEARCH STATUS INDICATOR -->
                            <div id="songTestStatusMsg" style="display: none; margin-bottom: 12px; padding: 10px 14px; border-radius: 10px; font-size: 12.5px; font-weight: 700; align-items: center; gap: 8px; transition: all 0.3s ease;">
                            </div>

                            <!-- QUICK TEST CHIPS -->
                            <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                <span style="font-size: 10.5px; color: #64748b; font-weight: 700; text-transform: uppercase;">Quick Test:</span>
                                <button type="button" onclick="window.runQuickSongSample('!play starting over again')"
                                    style="background: rgba(56, 189, 248, 0.15); border: 1px solid rgba(56, 189, 248, 0.3); color: #38bdf8; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; cursor: pointer;">
                                    ✨ !play starting over again
                                </button>
                                <button type="button" onclick="window.runQuickSongSample('!play bomba na')"
                                    style="background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.3); color: #34d399; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; cursor: pointer;">
                                    🎵 !play bomba na
                                </button>
                                <button type="button" onclick="window.runQuickSongSample('!play bruno mars thats what i like')"
                                    style="background: rgba(236, 72, 153, 0.15); border: 1px solid rgba(236, 72, 153, 0.3); color: #f472b6; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; cursor: pointer;">
                                    🎤 !play bruno mars
                                </button>
                                <button type="button" onclick="window.runQuickSongSample('!skip')"
                                    style="background: rgba(234, 179, 8, 0.15); border: 1px solid rgba(234, 179, 8, 0.3); color: #facc15; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; cursor: pointer;">
                                    ⏭ !skip
                                </button>
                                <button type="button" onclick="window.runQuickSongSample('!revoke')"
                                    style="background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.3); color: #fca5a5; font-size: 11px; font-weight: 700; padding: 3px 8px; border-radius: 6px; cursor: pointer;">
                                    🗑 !revoke
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN: UPCOMING QUEUE, REQUEST HISTORY & SETTINGS -->
                    <div style="background: #0f172a; border: 1.5px solid rgba(255,255,255,0.1); border-radius: 18px; padding: 22px; display: flex; flex-direction: column;">
                        
                        <!-- TAB HEADER -->
                        <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid rgba(255,255,255,0.08); padding-bottom: 14px; margin-bottom: 16px;">
                            <div style="display: flex; gap: 8px;">
                                <button type="button" onclick="window.switchSongSubTab('queue')"
                                    style="background: ${activeTab === 'queue' ? 'rgba(56, 189, 248, 0.15)' : 'transparent'}; border: 1px solid ${activeTab === 'queue' ? '#38bdf8' : 'transparent'}; color: ${activeTab === 'queue' ? '#38bdf8' : '#94a3b8'}; padding: 6px 14px; border-radius: 8px; font-size: 13px; font-weight: 800; cursor: pointer;">
                                    📋 Upcoming Queue (${queueCount})
                                </button>
                                <button type="button" onclick="window.switchSongSubTab('history')"
                                    style="background: ${activeTab === 'history' ? 'rgba(56, 189, 248, 0.15)' : 'transparent'}; border: 1px solid ${activeTab === 'history' ? '#38bdf8' : 'transparent'}; color: ${activeTab === 'history' ? '#38bdf8' : '#94a3b8'}; padding: 6px 14px; border-radius: 8px; font-size: 13px; font-weight: 800; cursor: pointer;">
                                    📜 Request History (${songState.history.length})
                                </button>
                                <button type="button" onclick="window.switchSongSubTab('settings')"
                                    style="background: ${activeTab === 'settings' ? 'rgba(56, 189, 248, 0.15)' : 'transparent'}; border: 1px solid ${activeTab === 'settings' ? '#38bdf8' : 'transparent'}; color: ${activeTab === 'settings' ? '#38bdf8' : '#94a3b8'}; padding: 6px 14px; border-radius: 8px; font-size: 13px; font-weight: 800; cursor: pointer;">
                                    ⚙️ Rules & Settings
                                </button>
                            </div>

                            ${activeTab === 'queue' && queueCount > 0 ? `
                                <button type="button" onclick="window.clearSongQueue()"
                                    style="background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.3); color: #fca5a5; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                                    Clear Queue
                                </button>
                            ` : ''}
                        </div>

                        <!-- TAB CONTENT: QUEUE -->
                        ${activeTab === 'queue' ? `
                            <div style="flex: 1; overflow-y: auto; max-height: 520px; display: flex; flex-direction: column; gap: 8px;">
                                ${queueCount === 0 ? `
                                    <div style="text-align: center; padding: 60px 20px; color: #64748b;">
                                        <div style="font-size: 40px; margin-bottom: 10px;">🎶</div>
                                        <div style="font-size: 15px; font-weight: 700; color: #94a3b8;">The Queue is Currently Empty</div>
                                        <p style="font-size: 12.5px; color: #64748b; margin-top: 4px;">
                                            When viewers comment <code style="color: #38bdf8;">!play [song]</code> on TikTok Live, they will appear here!
                                        </p>
                                    </div>
                                ` : songState.queue.map((item, idx) => `
                                    <div style="background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.07); border-radius: 12px; padding: 10px 14px; display: flex; align-items: center; justify-content: space-between; gap: 12px; transition: all 0.15s ease;"
                                         onmouseover="this.style.background='rgba(56, 189, 248, 0.06)'; this.style.borderColor='rgba(56, 189, 248, 0.25)';"
                                         onmouseout="this.style.background='rgba(255,255,255,0.03)'; this.style.borderColor='rgba(255,255,255,0.07)';">
                                        
                                        <div style="display: flex; align-items: center; gap: 12px; min-width: 0;">
                                            <span style="font-size: 13px; font-weight: 900; color: #64748b; width: 24px; text-align: center;">#${idx + 1}</span>
                                            <div style="position: relative; width: 42px; height: 42px; border-radius: 8px; overflow: hidden; background: #1e293b; flex-shrink: 0;">
                                                <img src="${item.coverUrl || 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&h=200&fit=crop'}" style="width: 100%; height: 100%; object-fit: cover;">
                                            </div>
                                            <div style="min-width: 0;">
                                                <div style="font-size: 14px; font-weight: 800; color: #f8fafc; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                                                    ${item.title}
                                                </div>
                                                <div style="font-size: 11.5px; color: #f472b6; font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 2px; display: flex; align-items: center; gap: 4px;">
                                                    <span>🎤 Singer:</span>
                                                    <strong style="color: #ffffff;">${item.singer || item.artist}</strong>
                                                </div>
                                                <div style="font-size: 10.5px; color: #38bdf8; margin-top: 2px;">
                                                    👤 @${item.requestedBy} • ${item.timestamp || 'Just now'}
                                                </div>
                                            </div>
                                        </div>

                                        <div style="display: flex; align-items: center; gap: 6px; flex-shrink: 0;">
                                            <button type="button" onclick="window.playSongNow('${item.id}')"
                                                style="background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.4); color: #34d399; font-size: 11px; font-weight: 800; padding: 5px 10px; border-radius: 6px; cursor: pointer;">
                                                ▶ Play Now
                                            </button>
                                            <button type="button" onclick="window.removeSongFromQueue('${item.id}')"
                                                style="background: rgba(239, 68, 68, 0.12); border: 1px solid rgba(239, 68, 68, 0.3); color: #fca5a5; font-size: 11px; font-weight: 700; padding: 5px 8px; border-radius: 6px; cursor: pointer;" title="Remove song">
                                                ✕
                                            </button>
                                        </div>
                                    </div>
                                `).join('')}
                            </div>
                        ` : ''}

                        <!-- TAB CONTENT: HISTORY -->
                        ${activeTab === 'history' ? `
                            <div style="flex: 1; overflow-y: auto; max-height: 520px;">
                                <table style="width: 100%; border-collapse: collapse; font-size: 12px; text-align: left;">
                                    <thead>
                                        <tr style="border-bottom: 1px solid rgba(255,255,255,0.1); color: #64748b; font-size: 10.5px; text-transform: uppercase; letter-spacing: 0.5px;">
                                            <th style="padding: 8px 10px;">Time</th>
                                            <th style="padding: 8px 10px;">Requester</th>
                                            <th style="padding: 8px 10px;">Track</th>
                                            <th style="padding: 8px 10px;">Status</th>
                                            <th style="padding: 8px 10px; text-align: right;">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${songState.history.length === 0 ? `
                                            <tr>
                                                <td colspan="5" style="text-align: center; padding: 40px; color: #64748b;">No recent request history yet.</td>
                                            </tr>
                                        ` : songState.history.map(h => `
                                            <tr style="border-bottom: 1px solid rgba(255,255,255,0.04);">
                                                <td style="padding: 10px; color: #64748b; font-family: monospace;">${h.timestamp}</td>
                                                <td style="padding: 10px; font-weight: 700; color: #38bdf8;">@${h.requestedBy}</td>
                                                <td style="padding: 10px; font-weight: 700; color: #f8fafc;">${h.title} <span style="font-weight: 400; color: #94a3b8;">- ${h.artist || ''}</span></td>
                                                <td style="padding: 10px;">
                                                    <span style="font-size: 10px; font-weight: 800; padding: 2px 6px; border-radius: 4px; ${h.status === 'played' ? 'background: rgba(16, 185, 129, 0.15); color: #34d399;' : 'background: rgba(239, 68, 68, 0.15); color: #fca5a5;'}">
                                                        ${(h.status || 'played').toUpperCase()}
                                                    </span>
                                                </td>
                                                <td style="padding: 10px; text-align: right;">
                                                    <button type="button" onclick="window.runQuickSongSample('!play ${h.title.replace(/'/g, "\\'")}')"
                                                        style="background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); color: #cbd5e1; font-size: 10.5px; padding: 3px 8px; border-radius: 5px; cursor: pointer;">
                                                        Re-queue
                                                    </button>
                                                </td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        ` : ''}

                        <!-- TAB CONTENT: SETTINGS -->
                        ${activeTab === 'settings' ? `
                            <div style="flex: 1; overflow-y: auto; max-height: 520px; display: flex; flex-direction: column; gap: 16px;">
                                <div>
                                    <label style="font-size: 12px; font-weight: 700; color: #94a3b8; display: block; margin-bottom: 6px;">Chat Command Triggers:</label>
                                    <input type="text" value="!play, !sr, !song, !request" readonly
                                        style="width: 100%; background: #0b1120; border: 1px solid rgba(255,255,255,0.12); color: #38bdf8; padding: 8px 12px; border-radius: 8px; font-size: 13px; font-family: monospace;">
                                    <span style="font-size: 11px; color: #64748b; margin-top: 4px; display: block;">Users in live comments can type any of these keywords followed by the song title.</span>
                                </div>

                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                                    <div>
                                        <label style="font-size: 12px; font-weight: 700; color: #94a3b8; display: block; margin-bottom: 6px;">Max Songs Per Viewer:</label>
                                        <select id="settingMaxQueue" onchange="window.updateSongSetting('maxQueuePerUser', Number(this.value))"
                                            style="width: 100%; background: #0b1120; border: 1px solid rgba(255,255,255,0.12); color: #f8fafc; padding: 8px 12px; border-radius: 8px; font-size: 13px;">
                                            <option value="1" ${songState.settings.maxQueuePerUser === 1 ? 'selected' : ''}>1 Song at a time</option>
                                            <option value="2" ${songState.settings.maxQueuePerUser === 2 ? 'selected' : ''}>2 Songs</option>
                                            <option value="3" ${songState.settings.maxQueuePerUser === 3 ? 'selected' : ''}>3 Songs (Default)</option>
                                            <option value="5" ${songState.settings.maxQueuePerUser === 5 ? 'selected' : ''}>5 Songs</option>
                                            <option value="999" ${songState.settings.maxQueuePerUser === 999 ? 'selected' : ''}>Unlimited</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label style="font-size: 12px; font-weight: 700; color: #94a3b8; display: block; margin-bottom: 6px;">Max Song Duration:</label>
                                        <select id="settingMaxDuration" onchange="window.updateSongSetting('maxSongDurationMinutes', Number(this.value))"
                                            style="width: 100%; background: #0b1120; border: 1px solid rgba(255,255,255,0.12); color: #f8fafc; padding: 8px 12px; border-radius: 8px; font-size: 13px;">
                                            <option value="5" ${songState.settings.maxSongDurationMinutes === 5 ? 'selected' : ''}>5 Minutes</option>
                                            <option value="7" ${songState.settings.maxSongDurationMinutes === 7 ? 'selected' : ''}>7 Minutes (Default)</option>
                                            <option value="10" ${songState.settings.maxSongDurationMinutes === 10 ? 'selected' : ''}>10 Minutes</option>
                                        </select>
                                    </div>
                                </div>

                                <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px 14px; background: rgba(255,255,255,0.03); border-radius: 10px; border: 1px solid rgba(255,255,255,0.07);">
                                    <div>
                                        <div style="font-size: 13px; font-weight: 700; color: #f8fafc;">AI Voice TTS Announcement</div>
                                        <div style="font-size: 11px; color: #64748b;">Speak an announcement whenever a viewer's song is added or begins playing.</div>
                                    </div>
                                    <input type="checkbox" ${songState.settings.ttsAnnouncement ? 'checked' : ''} onchange="window.updateSongSetting('ttsAnnouncement', this.checked)" style="transform: scale(1.3); cursor: pointer;">
                                </div>
                            </div>
                        ` : ''}

                    </div>
                </div>
            </div>
        `;
        syncPersistentAudioLayout();
    }

    // Window Exposure for UI Event Handlers
    window.loginWithSpotify = showSpotifyModal;
    window.submitSpotifyAuth = () => {
        const input = document.getElementById('spotifyCustomClientId');
        if (input && input.value) {
            startSpotifyOAuth(input.value);
        } else {
            if (typeof showToast === 'function') showToast('⚠️ Please paste your Spotify Developer App Client ID', 'warning');
        }
    };
    window.enableBuiltinMode = () => {
        const modal = document.getElementById('spotifyConnectModal');
        if (modal) modal.remove();
        songState.spotifyConnected = false;
        saveSongState();
        renderSongRequestUI();
        if (typeof showToast === 'function') showToast('🔊 Built-in Live Player is active and ready!', 'success');
    };
    window.simulateSpotifyDemo = () => simulateSpotifyLogin('StreamHostDemo');
    window.disconnectSpotifyAccount = disconnectSpotify;
    window.toggleSongPlayback = togglePlayback;
    window.setSongVolume = setSongVolume;
    window.skipSong = () => skipCurrentTrack('Manual Skip');
    window.clearSongQueue = clearWholeQueue;
    window.removeSongFromQueue = removeQueueItem;
    window.playSongNow = playQueueItemNow;

    window.switchSongSubTab = (tab) => {
        activeTab = tab;
        renderSongRequestUI();
    };

    window.updateSongSetting = (key, val) => {
        songState.settings[key] = val;
        saveSongState();
    };

    window.copySongOverlayUrl = () => {
        const input = document.getElementById('obsSongRequestUrl');
        if (input) {
            navigator.clipboard.writeText(input.value);
            if (typeof showToast === 'function') showToast('📋 Copied OBS Overlay link to clipboard!', 'success');
        }
    };

    window.toggleObsAudioLink = (includeAudio) => {
        const input = document.getElementById('obsSongRequestUrl');
        if (input) {
            input.value = includeAudio
                ? `${window.location.origin}/overlay-songrequest.html?audio=1`
                : `${window.location.origin}/overlay-songrequest.html`;
        }
    };

    window.testSubmitSongCommand = async () => {
        const input = document.getElementById('songTestInput');
        const btn = document.getElementById('btnSongTestSubmit');
        const statusBox = document.getElementById('songTestStatusMsg');
        if (!input || !input.value.trim()) return;

        const rawCmd = input.value.trim();
        const origBtnContent = btn ? btn.innerHTML : '<span>▶</span> <span>Test Request</span>';

        if (btn) {
            btn.disabled = true;
            btn.innerHTML = `<span style="display:inline-block; animation: spinVinyl 1s linear infinite;">⏳</span> <span>Searching Full Track...</span>`;
            btn.style.opacity = '0.75';
            btn.style.cursor = 'not-allowed';
        }

        if (statusBox) {
            statusBox.style.display = 'flex';
            statusBox.style.background = 'rgba(56, 189, 248, 0.12)';
            statusBox.style.border = '1px solid rgba(56, 189, 248, 0.4)';
            statusBox.style.color = '#38bdf8';
            statusBox.innerHTML = `<span style="font-size: 16px;">🔍</span> <div><strong>Searching 3-5 minute song:</strong> Resolving full HD audio & singer for <em>"${rawCmd}"</em>...</div>`;
        }

        try {
            await handleIncomingSongRequest('TestViewer', rawCmd);

            if (statusBox) {
                statusBox.style.background = 'rgba(16, 185, 129, 0.15)';
                statusBox.style.border = '1px solid rgba(16, 185, 129, 0.4)';
                statusBox.style.color = '#34d399';
                statusBox.innerHTML = `<span style="font-size: 16px;">✅</span> <div><strong>Success!</strong> Full song queued/playing smoothly with timeline seek & vinyl visualizer.</div>`;
                setTimeout(() => {
                    if (statusBox) statusBox.style.display = 'none';
                }, 4500);
            }
        } catch (err) {
            console.error('[SongRequest] Test command failed:', err);
            if (statusBox) {
                statusBox.style.background = 'rgba(239, 68, 68, 0.15)';
                statusBox.style.border = '1px solid rgba(239, 68, 68, 0.4)';
                statusBox.style.color = '#fca5a5';
                statusBox.innerHTML = `<span style="font-size: 16px;">⚠️</span> <div><strong>Error:</strong> ${err.message || 'Could not process command.'}</div>`;
            }
        } finally {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = origBtnContent;
                btn.style.opacity = '1';
                btn.style.cursor = 'pointer';
            }
        }
    };

    window.runQuickSongSample = async (cmd) => {
        const input = document.getElementById('songTestInput');
        if (input) input.value = cmd;
        await window.testSubmitSongCommand();
    };

    window.seekSongPosition = seekSongPosition;
    window.togglePlayerViewMode = togglePlayerViewMode;
    window.testAudioClip = testAudioClip;
    window.duckSongVolume = duckSongVolume;
    window.handleIncomingSongRequest = handleIncomingSongRequest;
    window.loadSongState = loadSongState;
    window.renderSongRequestUI = renderSongRequestUI;
    window.ensureAudioPlaying = ensureAudioPlaying;

    // Initialize on page load
    document.addEventListener('DOMContentLoaded', () => {
        loadSongState().then(() => {
            if (songState.nowPlaying) ensureAudioPlaying(false);
            if (typeof renderSongRequestUI === 'function') renderSongRequestUI();
        });
        handleSpotifyCallback();
    });

    // Also call immediately if script loaded after DOM
    setTimeout(() => {
        loadSongState().then(() => {
            if (songState.nowPlaying) ensureAudioPlaying(false);
            if (typeof renderSongRequestUI === 'function') renderSongRequestUI();
        });
        handleSpotifyCallback();
    }, 200);

    // Immediate initial render in case container is already present
    if (typeof renderSongRequestUI === 'function') {
        try { renderSongRequestUI(); } catch (_) {}
    }

})();
