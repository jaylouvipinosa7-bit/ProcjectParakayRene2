/**
 * ==============================================================================
 * RENEarn Command & Game Engine Architecture
 * ==============================================================================
 * Standardized command execution, global branding, and extensible game adapters.
 * All existing and future games inherit from BaseRENEarnGameAdapter to ensure
 * unified output format, embed title, and "RENEarn" branding across all modes.
 */

(function (window) {
    'use strict';

    // Base Extensible Game Adapter
    class BaseRENEarnGameAdapter {
        constructor(config) {
            this.id = config.id;
            this.name = config.name;
            this.badge = config.badge || 'READY';
            this.badgeClass = config.badgeClass || 'badge-ready';
            this.icon = config.icon || '🎮';
            this.iconColor = config.iconColor || '#38bdf8';
            this.tag = config.tag || 'Game • Ready';
            this.endpoint = config.endpoint || '/api/games/execute';
            this.port = config.port || 55001;
            this.supportsZombies = config.supportsZombies ?? true;
            this.supportsPlants = config.supportsPlants ?? true;
            this.customCommands = config.customCommands || [];
        }

        /**
         * Standardized Command Execution Wrapper
         * Enforces global "RENEarn" branding and structured response across all games.
         */
        formatResponse(command, payload = {}, status = 'success', rawOutput = null) {
            return {
                brand: "RENEarn",
                embedTitle: `RENEarn Interactive Stream Engine • ${this.name}`,
                sender: "RENEarn",
                gameId: this.id,
                gameName: this.name,
                command: command,
                status: status,
                timestamp: Date.now(),
                payload: payload,
                output: rawOutput || `[RENEarn] Command ${command} dispatched to ${this.name}`,
                metadata: {
                    engine: "RENEarn Core v4.0",
                    port: this.port
                }
            };
        }

        async execute(command, payload = {}) {
            try {
                const res = await fetch('/api/test', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        gameId: this.id,
                        command: command,
                        actionType: payload.actionType || 'game_action',
                        amount: payload.amount || 1,
                        username: payload.username || 'RENEarn',
                        branding: 'RENEarn',
                        label: payload.label || command,
                        isTest: true,
                        noJarDrop: true,
                        noOverlayCount: true
                    })
                });

                const data = res.ok ? await res.json() : null;
                return this.formatResponse(command, payload, 'success', data);
            } catch (err) {
                return this.formatResponse(command, payload, 'error', { error: err.message });
            }
        }
    }

    // Concrete Game Adapters
    class PvZFusionAdapter extends BaseRENEarnGameAdapter {
        constructor() {
            super({
                id: 'pvz_fusion_4',
                name: 'Plants vs. Zombies: Fusion 4.0',
                badge: 'CONNECTED',
                badgeClass: 'badge-connected',
                icon: '🧟',
                iconColor: '#22c55e',
                tag: 'Official Game • Live Ready',
                port: 55001
            });
        }
    }

    class PvZHybridAdapter extends BaseRENEarnGameAdapter {
        constructor() {
            super({
                id: 'pvz_hybrid',
                name: 'PvZ: Hybrid Edition (杂交版)',
                badge: 'READY',
                badgeClass: 'badge-ready',
                icon: '🧬',
                iconColor: '#38bdf8',
                tag: 'Hybrid Edition • Ready',
                port: 55001
            });
        }
    }

    class PvZClassicAdapter extends BaseRENEarnGameAdapter {
        constructor() {
            super({
                id: 'pvz_classic',
                name: 'PvZ: Original / GOTY Edition',
                badge: 'READY',
                badgeClass: 'badge-ready',
                icon: '🌻',
                iconColor: '#eab308',
                tag: 'Classic PvZ1 • Ready',
                port: 55001
            });
        }
    }

    class UniversalGameAdapter extends BaseRENEarnGameAdapter {
        constructor() {
            super({
                id: 'universal_stream',
                name: 'Custom / Universal Game Stream',
                badge: 'UNIVERSAL',
                badgeClass: 'badge-universal',
                icon: '🕹️',
                iconColor: '#a855f7',
                tag: 'Universal Stream • Ready',
                port: 8080
            });
        }
    }

    class ZombieTsunamiAdapter extends BaseRENEarnGameAdapter {
        constructor() {
            super({
                id: 'zombie_tsunami',
                name: 'Zombie Tsunami (Interactive PC)',
                badge: 'LIVE READY',
                badgeClass: 'badge-connected',
                icon: '🌊',
                iconColor: '#06b6d4',
                tag: 'Interactive Web & Overlay • Ready',
                port: 8080,
                supportsZombies: true,
                supportsPlants: false,
                customCommands: [
                    { id: 'spawn_zombie', label: 'Add Zombie (+1)', type: 'zombie' },
                    { id: 'tsunami_wave', label: 'Mega Tsunami Wave', type: 'power' },
                    { id: 'giant_laser', label: 'Giant Laser Zombie', type: 'power' },
                    { id: 'ufo_clone', label: 'UFO Abduction', type: 'power' },
                    { id: 'gold_rush', label: 'Gold Rush Mode', type: 'power' },
                    { id: 'jump', label: 'Horde Jump', type: 'action' }
                ]
            });
        }
    }

    // Master RENEarn Command & Game Engine
    class RENEarnGameEngine {
        constructor() {
            this.brand = "RENEarn";
            this.embedTitle = "RENEarn Interactive Stream Controller";
            this.games = new Map();
            this.activeGameId = 'pvz_fusion_4';
            this.activeSetupName = 'PvZ Fusion 4.0 • Custom Setup';
            this.presets = new Map();
            this.listeners = new Set();

            this.registerDefaultGames();
            this.registerDefaultPresets();
            this.loadStoredState();
        }

        registerDefaultGames() {
            this.registerGame(new PvZFusionAdapter());
            this.registerGame(new PvZHybridAdapter());
            this.registerGame(new PvZClassicAdapter());
            this.registerGame(new UniversalGameAdapter());
            this.registerGame(new ZombieTsunamiAdapter());
        }

        registerDefaultPresets() {
            this.presets.set('zombie_tsunami_live', {
                id: 'zombie_tsunami_live',
                title: 'Zombie Tsunami Live Stream Pack',
                badge: 'LIVE READY',
                badgeClass: 'badge-connected',
                author: 'By RENEarn • Official Setup',
                triggersCount: 30,
                tags: ['Zombie Tsunami', 'Shared'],
                status: 'Ready to use'
            });
            this.presets.set('classic_streamer', {
                id: 'classic_streamer',
                title: 'Classic Streamer Pack',
                badge: 'OFFICIAL',
                badgeClass: 'badge-official',
                author: 'By Admin • Shared Setup',
                triggersCount: 64,
                tags: ['Shared'],
                status: 'Ready to use'
            });

            this.presets.set('zombie_invasion', {
                id: 'zombie_invasion',
                title: 'Zombie Invasion Challenge',
                badge: 'HARDCORE',
                badgeClass: 'badge-hardcore',
                author: 'By Admin • Shared Setup',
                triggersCount: 45,
                tags: ['Shared'],
                status: 'Ready to use'
            });

            this.presets.set('coop_protectors', {
                id: 'coop_protectors',
                title: 'Co-op Plant Protectors',
                badge: 'CO-OP',
                badgeClass: 'badge-coop',
                author: 'By Admin • Shared Setup',
                triggersCount: 48,
                tags: ['Shared'],
                status: 'Ready to use'
            });

            this.presets.set('lucky_wheel', {
                id: 'lucky_wheel',
                title: 'Lucky Wheel & Spinners',
                badge: 'ROULETTE',
                badgeClass: 'badge-roulette',
                author: 'By Admin • Shared Setup',
                triggersCount: 32,
                tags: ['Shared'],
                status: 'Ready to use'
            });
        }

        /**
         * Extensibility API: Register any new game easily!
         * Future games automatically inherit standardized RENEarn formatting.
         */
        registerGame(gameAdapter) {
            if (!(gameAdapter instanceof BaseRENEarnGameAdapter)) {
                gameAdapter = new BaseRENEarnGameAdapter(gameAdapter);
            }
            this.games.set(gameAdapter.id, gameAdapter);
            this.notifyStateChange();
            return gameAdapter;
        }

        getActiveGame() {
            return this.games.get(this.activeGameId) || this.games.get('pvz_fusion_4');
        }

        /**
         * Switch the active streaming game with immediate feedback and state sync.
         */
        async switchGame(gameId) {
            if (!this.games.has(gameId)) return false;
            this.activeGameId = gameId;
            const game = this.games.get(gameId);

            // Update setup label
            this.activeSetupName = `${game.name} • Custom Setup`;

            // Persist locally and notify server
            try {
                localStorage.setItem('renearn_active_game_id', gameId);
                fetch('/api/games/active', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ gameId: gameId, brand: 'RENEarn' })
                }).catch(() => {});
            } catch (e) {}

            this.notifyStateChange();
            return true;
        }

        /**
         * Apply a Universal Streamer Preset
         */
        async applyPreset(presetId) {
            const preset = this.presets.get(presetId);
            if (!preset) return false;

            this.activeSetupName = `${preset.title} • Active`;
            try {
                localStorage.setItem('renearn_active_preset_id', presetId);
                fetch('/api/presets/apply', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ presetId: presetId, brand: 'RENEarn' })
                }).catch(() => {});
            } catch (e) {}

            this.notifyStateChange();
            return preset;
        }

        /**
         * Universal command execution: Guaranteed RENEarn branding
         */
        async executeCommand(command, payload = {}) {
            const game = this.getActiveGame();
            return await game.execute(command, {
                ...payload,
                brand: 'RENEarn',
                embedTitle: this.embedTitle
            });
        }

        loadStoredState() {
            try {
                const stored = localStorage.getItem('renearn_active_game_id');
                if (stored && this.games.has(stored)) {
                    this.activeGameId = stored;
                }
            } catch (e) {}
        }

        subscribe(callback) {
            this.listeners.add(callback);
            return () => this.listeners.delete(callback);
        }

        notifyStateChange() {
            const state = {
                activeGameId: this.activeGameId,
                activeGame: this.getActiveGame(),
                activeSetupName: this.activeSetupName,
                games: Array.from(this.games.values()),
                presets: Array.from(this.presets.values())
            };
            this.listeners.forEach(cb => {
                try { cb(state); } catch (e) { console.error(e); }
            });
        }
    }

    // Expose Global Singleton
    window.RENEarnEngine = new RENEarnGameEngine();
    window.BaseRENEarnGameAdapter = BaseRENEarnGameAdapter;

})(window);
