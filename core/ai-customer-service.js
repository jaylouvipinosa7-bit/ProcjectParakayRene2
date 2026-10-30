/**
 * Studio AI Customer Support Assistant
 * Provides interactive customer service strictly answering questions about the Live Studio
 * applications, overlays, game integrations, commands, and setups with ZERO personal data.
 */
(function () {
    'use strict';

    // Application Knowledge Base (Public app documentation ONLY - Zero personal data)
    const APP_KNOWLEDGE_BASE = {
        name: "Live Studio Streaming Suite & Interactive Game Automation Platform",
        version: "4.2.0",
        summary: "An interactive live streaming and game automation platform that bridges live stream viewers directly into active PC gameplay. It turns live chat comments, TikTok gifts, likes, and lucky wheel spins into real-time in-game events, spells, summons, keystrokes, and interactive stream overlays.",
        coreIdentity: "The app is NOT just a single game mod or PvZ tool. It is a universal Live Stream Interactive Gaming Platform that connects viewer interactions (TikTok gifts, comments, likes) directly into PC gameplay via real-time automated commands, simulated keystrokes, coordinate clicks, and visual stream overlays for any supported game.",
        modules: [
            {
                name: "Real-Time Game Interaction & Automation",
                details: [
                    "Bridges live audience participation directly into PC games in real-time.",
                    "Gift-to-Action Mapping: Assign any live gift (Rose, Perfume, Heart, GG, etc.) to trigger in-game keystrokes, mouse clicks, unit summons, spells, or gameplay penalties/buffs.",
                    "Screen Calibration: Visually configure click targets or placement grids for any game window.",
                    "Multi-Game Compatibility: Compatible with any PC game via input automation and hotkeys, plus dedicated integrations for titles like Plants vs. Zombies (PvZ Fusion, PvZ Hybrid, PvZ Classic), Kingdom Siege, Zombie Tsunami, and custom PC games."
                ]
            },
            {
                name: "Overlays & Visualizers",
                details: [
                    "Wheel & Reel Overlay (overlay-spinner.html): Horizontal CS:GO style reel, Classic 2D Wheel of Fortune, 3D Slots, and 3D Gacha Box. Supports customizable prizes, weights, rarity colors, sounds, and avatar needles.",
                    "Live Gift Counter (overlay-counter.html): Visual progress bars and milestone tracker for live gifts (e.g. Roses, Perfumes, Hearts).",
                    "Side Overlay (overlay-side.html): Stream sidebar showing gift triggers, top gifters, live announcements, and instructions.",
                    "Team Battle (overlay-teambattle.html): Interactive Red vs Blue tug-of-war battle boosted by viewer likes and gifts.",
                    "Interactive Jar (overlay-jar.html): Physics-based falling coins, balls, and stars for tips and gifts.",
                    "Song Request Overlay (overlay-songrequest.html): Spinning vinyl player with album art, requester tag, audio visualizer, and upcoming queue."
                ]
            },
            {
                name: "Audience Engagement & Audio",
                details: [
                    "Song Request System: Allows live viewers to type !play <song> to queue music automatically with Spotify or local audio playback.",
                    "AI Voice TTS: Reads viewer questions aloud on stream using 8 distinct AI character personas (Adam Gamer, Robot X, Sakura Anime, Jenny Host, Ate May Pinay, Marcus Radio, Flash Speedrunner, Luna ASMR)."
                ]
            },
            {
                name: "OBS & TikTok Live Studio Setup",
                details: [
                    "Add Browser Source in OBS or TikTok Live Studio.",
                    "URL: http://localhost:8080/overlay-spinner.html (or overlay-counter.html, overlay-side.html, overlay-songrequest.html, etc.).",
                    "Recommended Canvas Size: 1080x1920 (Vertical 9:16 mobile stream) or 1920x1080 (Horizontal 16:9).",
                    "Make sure local server is running (port 8080)."
                ]
            },
            {
                name: "Troubleshooting FAQ",
                details: [
                    "Q: Overlay is blank or not connecting?\nA: Check that Launch_Studio.bat is running and listening on port 8080. Refresh browser source in OBS (right-click -> Refresh cache of current page).",
                    "Q: In-game actions/commands are not reacting?\nA: Verify the game window is active, screen calibration is aligned, and the game engine bridge is connected in the Studio top bar.",
                    "Q: How do I link a gift to a game command?\nA: Open the Studio Dashboard -> Gift Triggers tab -> select the gift (e.g. Perfume, Rose) and assign the game action or spinner to it."
                ]
            }
        ]
    };

    // System instruction strictly prohibiting personal data
    const SYSTEM_PROMPT = `You are the official Studio AI Customer Support Assistant for the Live Streaming Suite and Interactive Gaming System.
Your job is to answer customer questions accurately, politely, and clearly based ONLY on the application details, features, game integrations, overlay setups, and troubleshooting guides.

CORE APP DEFINITION & IDENTITY:
- IMPORTANT: When introducing the app or explaining what it does, NEVER describe it as just a "PvZ Fusion app". PvZ Fusion is merely one of multiple supported game titles.
- Always present the app as an **Interactive Live Stream Gaming & Automation Platform**: an application that empowers live stream viewers (on TikTok, Twitch, YouTube) to interact directly with the streamer's gameplay in real-time through chat commands, gifts, likes, spinning wheels, and live overlays.

STRICT PRIVACY POLICY & SAFETY RULES:
1. NEVER output or discuss any personal information, private usernames, personal emails, physical addresses, passwords, private stream keys, or sensitive credentials.
2. If asked about the system owner, developer personal info, or private account data, politely state that you only have access to public application technical features and guides.
3. Focus exclusively on technical help, overlay setup (OBS/TikTok Live Studio), game interaction commands, gift triggers, sound effects, and troubleshooting.
4. Keep answers friendly, well-formatted with markdown, bullet points, or numbered steps.`;

    // Local Storage Keys
    const STORAGE_KEY_SETTINGS = 'studio_ai_support_settings';
    const STORAGE_KEY_HISTORY = 'studio_ai_support_history';

    // State
    let aiSettings = {
        provider: 'gemini', // 'gemini' | 'openai'
        apiKey: '',
        model: 'gemini-2.5-flash' // default Gemini model
    };

    let chatHistory = [];
    let isAwaitingReply = false;

    // Load settings from localStorage
    function loadSettings() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY_SETTINGS);
            if (raw) {
                const parsed = JSON.parse(raw);
                aiSettings = { ...aiSettings, ...parsed };
            }
        } catch (e) {
            console.warn('[AI Support] Failed to load settings from storage:', e);
        }
    }

    function saveSettings() {
        try {
            localStorage.setItem(STORAGE_KEY_SETTINGS, JSON.stringify(aiSettings));
        } catch (e) {
            console.warn('[AI Support] Failed to save settings to storage:', e);
        }
    }

    function loadHistory() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY_HISTORY);
            if (raw) {
                chatHistory = JSON.parse(raw);
            }
        } catch (e) {
            chatHistory = [];
        }
        if (!chatHistory || chatHistory.length === 0) {
            chatHistory = [
                {
                    sender: 'bot',
                    text: "👋 **Hello! I'm your Studio AI Assistant.**\n\nHow can I help you today with **Interactive Game Controls, Overlays, TikTok Gifts, Song Requests, or AI Voice**?\n\n*🎮 Tip: Ask me \"What is this app?\" or \"How does it interact with games?\" to learn more!*"
                }
            ];
        }
    }

    function saveHistory() {
        try {
            // Keep last 30 messages max
            const trimmed = chatHistory.slice(-30);
            localStorage.setItem(STORAGE_KEY_HISTORY, JSON.stringify(trimmed));
        } catch (e) {}
    }

    // Offline Local Knowledge Matcher (Instant answers if API key is not yet set)
    function queryOfflineKnowledge(userQuery) {
        const q = userQuery.toLowerCase();

        if (q.includes('obs') || q.includes('tiktok live studio') || q.includes('browser source') || q.includes('add overlay')) {
            return `### 🎬 How to Add Overlays to OBS / TikTok Live Studio:\n\n1. Open **OBS** or **TikTok Live Studio**.\n2. In your Scenes panel, click **+ Add Source** and pick **Browser**.\n3. Enter the local URL of the overlay:\n   - **Wheel & Reel**: \`http://localhost:8080/overlay-spinner.html\`\n   - **Live Gift Counter**: \`http://localhost:8080/overlay-counter.html\`\n   - **Side Overlay**: \`http://localhost:8080/overlay-side.html\`\n   - **Gacha Machine**: \`http://localhost:8080/overlay-gacha.html\`\n   - **Song Request**: \`http://localhost:8080/overlay-songrequest.html\`\n   - **Team Battle**: \`http://localhost:8080/overlay-teambattle.html\`\n4. Recommended Resolution:\n   - **Vertical (Mobile 9:16)**: \`1080\` width × \`1920\` height\n   - **Horizontal (16:9)**: \`1920\` width × \`1080\` height\n5. Make sure the Studio server is running on **port 8080**!`;
        }

        if (q.includes('what is') || q.includes('introduce') || q.includes('about') || q.includes('concept') || q.includes('overview') || q.includes('ano') || q.includes('feature') || q.includes('app')) {
            return `### 🎮 Live Stream Interactive Gaming & Automation Platform:\n\n**What is this app?**\nThis platform is an **Interactive Live Stream Gaming & Automation Suite** that turns your live stream viewers into active participants in your gameplay!\n\n**Core Interactive Features:**\n- 🎁 **Viewer Actions to In-Game Events**: TikTok gifts, likes, and milestones trigger instant in-game actions, spells, summons, keyboard inputs, and coordinate clicks in real-time.\n- 💬 **Live Chat Commands**: Viewers can request songs with \`!play <song name>\`, ask questions that AI speaks aloud via Voice TTS, or vote on gameplay choices.\n- 🎡 **Dynamic Stream Overlays**: Add live CS:GO-style reels, 2D wheels of fortune, 3D slots, gift counters, and physics jars directly into OBS.\n- 🕹️ **Universal Game Compatibility**: Works with any PC game via input automation and screen calibration, plus direct integrations for games like Plants vs. Zombies (PvZ Fusion/Hybrid), Kingdom Siege, and custom games.\n- 🎵 **Spotify Music & Vinyl Overlay**: Live song request queue with a spinning vinyl record player overlay for your stream.`;
        }

        if (q.includes('interact') || q.includes('game') || q.includes('command') || q.includes('automation') || q.includes('keybind') || q.includes('hotkey')) {
            return `### 🕹️ How the App Interacts with Games:\n\n**The Concept: Real-Time Audience-to-Game Gameplay**\nThe Studio is an intelligent automation bridge between your live audience and your PC games:\n\n1. **Live Stream Event Listener**: Captures viewer gifts, likes, shares, and chat comments in real-time with 0ms latency.\n2. **Action Automation Engine**:\n   - **Simulated Keystrokes & Hotkeys**: Automatically presses keys (e.g. 1, 2, Q, Space) to cast abilities or deploy cards.\n   - **Coordinate Clicks**: Uses the built-in **Screen Calibration** tool to click exact tiles or UI buttons inside your running game.\n   - **In-Game Summons & Mod Bridges**: Directly spawns allies, enemies, or challenges based on viewer gifts.\n3. **Gift-to-Action Mapping**: In the **Gifts & Triggers** dashboard, customize which gift triggers which game action or wheel spin.\n4. **Universal Compatibility**: Works with any PC game running on your system (including PvZ Fusion, PvZ Hybrid, Kingdom Siege, Zombie Tsunami, and other PC titles).`;
        }

        if (q.includes('pvz') || q.includes('plants vs zombies') || q.includes('fusion') || q.includes('hybrid') || q.includes('gargantuar') || q.includes('doom')) {
            return `### 🧟 Plants vs. Zombies Game Integration:\n\n- **Supported Editions**: PvZ Fusion, PvZ Hybrid, and PvZ Classic.\n- **In-Game Spawns**: Automatically deploys custom plants (Nuclear Doom Cherry, Cattail, Gatling) or zombies (Titan Gargantuar, Jackson Zombie) when gifts or wheel spins trigger.\n- **Connection Status**: Check the top header of the Studio dashboard. If the indicator is green (• WORKING & CONNECTED), game commands execute with 0ms latency.\n- **Screen Calibration**: Use the Screen Calibration tool in the dashboard to align in-game grid placement with your lawn coordinates.`;
        }

        if (q.includes('gift') || q.includes('trigger') || q.includes('rose') || q.includes('perfume')) {
            return `### 🎁 How TikTok Gifts Work with Studio:\n\n- When viewers send gifts during your TikTok Live, the Studio's TikTok connector bridge captures the event in real-time.\n- **Mapping**: In the Studio Dashboard, each gift (e.g., Perfume, Rose, Heart) can be linked to:\n  1. **Spinning the Lucky Wheel or Reel**\n  2. **Triggering in-game actions/summons** (e.g. spells, abilities, or enemy spawns)\n  3. **Adding coins to the Interactive Jar**\n  4. **Progressing the Gift Counter milestone bar**\n- You can customize which gift triggers what in the **Gifts & Triggers** dashboard tab.`;
        }

        if (q.includes('spinner') || q.includes('wheel') || q.includes('reel') || q.includes('slot') || q.includes('gacha') || q.includes('mode')) {
            return `### 🎡 Lucky Wheel & Spinner Modes:\n\nThe Studio features multiple visualizer styles:\n1. **Horizontal Reel**: CS:GO-style horizontal scrolling ticker.\n2. **Classic Wheel**: High-precision 2D Wheel of Fortune with sound effects.\n3. **3D Slot Machine**: Vegas-style 3-reel slot spinner.\n4. **3D Gacha Box**: Japanese capsule toy machine with drop animations.\n\nTo switch or edit, go to the **Wheel & Gacha Overlay** card in the dashboard or click the quick mode selector pills!`;
        }

        if (q.includes('music') || q.includes('song') || q.includes('spotify') || q.includes('!play') || q.includes('queue')) {
            return `### 🎶 Song Request & Spotify Music System:\n\n- **Live Chat Requests**: Viewers type \`!play <song name>\` or \`!sr <song name>\` in chat to request music.\n- **Spotify Integration**: Connect your Spotify account to automatically add requested songs to your real Spotify queue.\n- **OBS Vinyl Overlay**: Add \`http://localhost:8080/overlay-songrequest.html\` to OBS to display an animated 33 RPM spinning vinyl record, album artwork, and upcoming queue.\n- **Chat Controls**: Streamers can skip songs (\`!skip\`), revoke requests (\`!revoke\`), or configure limits in the **Song Request** dashboard tab.`;
        }

        if (q.includes('offline') || q.includes('not working') || q.includes('blank') || q.includes('disconnect') || q.includes('fix') || q.includes('error')) {
            return `### 🔧 Troubleshooting Guide:\n\n1. **Overlay is Blank**: Ensure \`Launch_Studio.bat\` is active. Verify \`http://localhost:8080\` is accessible in your browser. In OBS, right-click the Browser source and select *'Refresh cache of current page'*.\n2. **Game Commands Not Executing**: Ensure your game is running in windowed or borderless mode and the game engine bridge is connected.\n3. **TikTok Disconnect**: Verify the username is entered correctly in the stream command bar and that your TikTok stream is currently LIVE.`;
        }

        if (q.includes('privacy') || q.includes('data') || q.includes('personal')) {
            return `### 🔒 Privacy Guarantee:\n\nThis Customer Support Assistant is strictly sandboxed to technical application guides, overlay setups, game integrations, and troubleshooting. It **NEVER** stores, transmits, or accesses any personal account details, private keys, or passwords.`;
        }

        return `### 💡 Studio Assistant:\n\nI can help with all technical questions regarding the **Interactive Live Stream & Game Automation Suite**:\n- 🎮 **Game Interactions**: How gifts, chat, and commands control your game in real-time.\n- 🎬 **OBS & Stream Overlays**: Setting up wheels, reels, gacha machines, gift counters, and jar overlays.\n- 🎶 **Song Requests & Spotify**: Viewer music queues and live vinyl player overlay.\n- 🤖 **AI Voice TTS**: Setting up live viewer question reading with 8 AI character personas.\n- 🔧 **Troubleshooting**: Fixing connection, display, or keybind issues.\n\n*(Tip: Click the ⚙️ Settings button at the top of this window to connect your Gemini or OpenAI API key for full AI conversational responses!)*`;
    }

    // Call Gemini API directly (client-side)
    async function callGeminiAPI(userQuery, apiKey, model = 'gemini-2.5-flash') {
        const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

        const contents = [];

        // Build conversation history for context
        const contextMessages = chatHistory.slice(-6).map(m => ({
            role: m.sender === 'user' ? 'user' : 'model',
            parts: [{ text: m.text }]
        }));

        contents.push(...contextMessages);
        contents.push({
            role: 'user',
            parts: [{ text: userQuery }]
        });

        const requestBody = {
            systemInstruction: {
                parts: [{ text: `${SYSTEM_PROMPT}\n\nDETAILED APP KNOWLEDGE BASE:\n${JSON.stringify(APP_KNOWLEDGE_BASE, null, 2)}` }]
            },
            contents: contents,
            generationConfig: {
                temperature: 0.4,
                maxOutputTokens: 1024
            }
        };

        const res = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        });

        if (!res.ok) {
            const errJson = await res.json().catch(() => ({}));
            const errMsg = errJson?.error?.message || `HTTP ${res.status} ${res.statusText}`;
            throw new Error(errMsg);
        }

        const data = await res.json();
        const reply = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!reply) throw new Error("Empty response from Gemini API");
        return reply;
    }

    // Call OpenAI API
    async function callOpenAIAPI(userQuery, apiKey, model = 'gpt-4o-mini') {
        const endpoint = `https://api.openai.com/v1/chat/completions`;

        const messages = [
            {
                role: 'system',
                content: `${SYSTEM_PROMPT}\n\nDETAILED APP KNOWLEDGE BASE:\n${JSON.stringify(APP_KNOWLEDGE_BASE, null, 2)}`
            }
        ];

        const recent = chatHistory.slice(-6).map(m => ({
            role: m.sender === 'user' ? 'user' : 'assistant',
            content: m.text
        }));
        messages.push(...recent);
        messages.push({ role: 'user', content: userQuery });

        const res = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`
            },
            body: JSON.stringify({
                model: model || 'gpt-4o-mini',
                messages: messages,
                temperature: 0.4,
                max_tokens: 1024
            })
        });

        if (!res.ok) {
            const errJson = await res.json().catch(() => ({}));
            const errMsg = errJson?.error?.message || `HTTP ${res.status} ${res.statusText}`;
            throw new Error(errMsg);
        }

        const data = await res.json();
        const reply = data?.choices?.[0]?.message?.content;
        if (!reply) throw new Error("Empty response from OpenAI API");
        return reply;
    }

    // Simple Markdown Renderer
    function renderMarkdown(text) {
        if (!text) return '';
        let escaped = text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');

        // Headers
        escaped = escaped.replace(/^### (.*$)/gim, '<h4 style="margin: 8px 0 4px; color: #38bdf8; font-size: 13.5px; font-weight: 700;">$1</h4>');
        escaped = escaped.replace(/^## (.*$)/gim, '<h3 style="margin: 10px 0 4px; color: #facc15; font-size: 14px; font-weight: 800;">$1</h3>');
        escaped = escaped.replace(/^# (.*$)/gim, '<h2 style="margin: 12px 0 6px; color: #ffffff; font-size: 15px; font-weight: 800;">$1</h2>');

        // Bold and Italic
        escaped = escaped.replace(/\*\*(.*?)\*\*/g, '<strong style="color: #ffffff;">$1</strong>');
        escaped = escaped.replace(/\*(.*?)\*/g, '<em style="color: #cbd5e1;">$1</em>');

        // Inline Code
        escaped = escaped.replace(/`([^`]+)`/g, '<code style="background: rgba(0,0,0,0.4); color: #38bdf8; padding: 2px 5px; border-radius: 4px; font-size: 11.5px; font-family: monospace; border: 1px solid rgba(56,189,248,0.25);">$1</code>');

        // Lists
        escaped = escaped.replace(/^\s*-\s+(.*$)/gim, '<li style="margin-left: 18px; margin-bottom: 3px; color: #e2e8f0;">$1</li>');
        escaped = escaped.replace(/^\s*\d+\.\s+(.*$)/gim, '<li style="margin-left: 18px; margin-bottom: 3px; color: #e2e8f0; list-style-type: decimal;">$1</li>');

        // Line breaks
        escaped = escaped.replace(/\n\n/g, '<div style="height: 6px;"></div>');
        escaped = escaped.replace(/\n/g, '<br/>');

        return escaped;
    }

    // Build the UI DOM Elements
    function injectSupportWidgetUI() {
        if (document.getElementById('studioAiSupportRoot')) return;

        const root = document.createElement('div');
        root.id = 'studioAiSupportRoot';
        root.innerHTML = `
            <!-- FLOATING LAUNCHER BUTTON -->
            <button id="btnAiSupportLauncher" type="button" title="Open AI Customer Support"
                style="position: fixed; bottom: 22px; right: 24px; z-index: 99999; display: flex; align-items: center; gap: 8px; background: linear-gradient(135deg, #0284c7 0%, #0369a1 50%, #1d4ed8 100%); color: #ffffff; border: 1.5px solid rgba(56, 189, 248, 0.6); padding: 10px 18px; border-radius: 9999px; font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif; font-size: 13px; font-weight: 700; cursor: pointer; box-shadow: 0 10px 25px rgba(2, 132, 199, 0.45), 0 0 18px rgba(56, 189, 248, 0.35); transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);">
                <span style="font-size: 16px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.4));">💬</span>
                <span>AI Support</span>
                <span id="aiSupportPulseDot" style="width: 8px; height: 8px; border-radius: 50%; background: #22c55e; box-shadow: 0 0 8px #22c55e; display: inline-block;"></span>
            </button>

            <!-- CHAT PANEL WINDOW -->
            <div id="aiSupportWindow"
                style="position: fixed; bottom: 80px; right: 24px; width: 420px; max-width: calc(100vw - 32px); height: 600px; max-height: calc(100vh - 100px); background: linear-gradient(180deg, rgba(15, 23, 42, 0.98) 0%, rgba(10, 15, 26, 0.99) 100%); border: 1.5px solid rgba(56, 189, 248, 0.3); border-radius: 18px; box-shadow: 0 25px 60px rgba(0, 0, 0, 0.85), 0 0 35px rgba(2, 132, 199, 0.25); z-index: 99999; display: none; flex-direction: column; overflow: hidden; backdrop-filter: blur(16px); font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif;">
                
                <!-- HEADER BAR -->
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; background: rgba(30, 41, 59, 0.7); border-bottom: 1px solid rgba(255, 255, 255, 0.08);">
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <div style="width: 34px; height: 34px; border-radius: 10px; background: linear-gradient(135deg, #0284c7, #2563eb); display: flex; align-items: center; justify-content: center; font-size: 17px; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4);">
                            🤖
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 6px;">
                                <span style="color: #ffffff; font-weight: 800; font-size: 14px; letter-spacing: -0.2px;">Studio AI Support</span>
                                <span id="aiActiveModelBadge" style="background: rgba(56, 189, 248, 0.18); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.35); font-size: 9.5px; font-weight: 700; padding: 1px 6px; border-radius: 9999px;">Gemini</span>
                            </div>
                            <div style="color: #94a3b8; font-size: 11px; display: flex; align-items: center; gap: 5px;">
                                <span style="width: 6px; height: 6px; border-radius: 50%; background: #22c55e;"></span>
                                <span>Online • App Details Only</span>
                            </div>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <button id="btnAiOpenSettings" type="button" title="Configure AI API Key"
                            style="background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.1); color: #94a3b8; width: 30px; height: 30px; border-radius: 8px; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 13px; transition: all 0.15s ease;">
                            ⚙️
                        </button>
                        <button id="btnAiCloseWindow" type="button" title="Close Support"
                            style="background: rgba(255, 255, 255, 0.06); border: 1px solid rgba(255, 255, 255, 0.1); color: #94a3b8; width: 30px; height: 30px; border-radius: 8px; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; transition: all 0.15s ease;">
                            ✕
                        </button>
                    </div>
                </div>

                <!-- PRIVACY BADGE -->
                <div style="background: rgba(16, 185, 129, 0.1); border-bottom: 1px solid rgba(16, 185, 129, 0.2); padding: 5px 12px; display: flex; align-items: center; justify-content: space-between; font-size: 10.5px; color: #34d399;">
                    <span style="display: flex; align-items: center; gap: 5px;">
                        <span>🔒</span> <strong>Zero Personal Data:</strong> Only public app guides are shared.
                    </span>
                    <button id="btnAiClearChat" type="button" title="Clear Chat History"
                        style="background: none; border: none; color: #94a3b8; font-size: 10px; cursor: pointer; text-decoration: underline;">
                        Clear Chat
                    </button>
                </div>

                <!-- QUICK TOPIC CHIPS -->
                <div style="padding: 8px 12px 6px; display: flex; gap: 6px; overflow-x: auto; background: rgba(15, 23, 42, 0.6); border-bottom: 1px solid rgba(255, 255, 255, 0.05); scrollbar-width: none;">
                    <button class="ai-quick-chip" data-query="What is this app and how does it interact with games?"
                        style="flex-shrink: 0; background: rgba(16, 185, 129, 0.12); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 700; cursor: pointer;">
                        🎮 What is this App?
                    </button>
                    <button class="ai-quick-chip" data-query="How does the app interact with games in real-time?"
                        style="flex-shrink: 0; background: rgba(56, 189, 248, 0.1); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🕹️ Game Interaction
                    </button>
                    <button class="ai-quick-chip" data-query="How do I add overlays to OBS or TikTok Live Studio?"
                        style="flex-shrink: 0; background: rgba(56, 189, 248, 0.1); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🎬 OBS Overlays Setup
                    </button>
                    <button class="ai-quick-chip" data-query="How do TikTok gifts connect to game commands?"
                        style="flex-shrink: 0; background: rgba(245, 158, 11, 0.1); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🎁 TikTok Gifts Link
                    </button>
                    <button class="ai-quick-chip" data-query="How does the Song Request and Spotify system work?"
                        style="flex-shrink: 0; background: rgba(34, 197, 94, 0.1); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🎶 Song Request
                    </button>
                    <button class="ai-quick-chip" data-query="How do Lucky Wheels and Spinners work?"
                        style="flex-shrink: 0; background: rgba(168, 85, 247, 0.1); color: #c084fc; border: 1px solid rgba(168, 85, 247, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🎡 Spinners & Modes
                    </button>
                    <button class="ai-quick-chip" data-query="How to fix overlay not working or disconnected?"
                        style="flex-shrink: 0; background: rgba(239, 68, 68, 0.1); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.25); border-radius: 9999px; padding: 3px 9px; font-size: 10.5px; font-weight: 600; cursor: pointer;">
                        🔧 Troubleshooting
                    </button>
                </div>

                <!-- MESSAGES STREAM CONTAINER -->
                <div id="aiSupportMessageList"
                    style="flex: 1; overflow-y: auto; padding: 14px 14px 10px; display: flex; flex-direction: column; gap: 12px; scroll-behavior: smooth;">
                </div>

                <!-- TYPING INDICATOR -->
                <div id="aiTypingIndicator"
                    style="display: none; align-items: center; gap: 8px; padding: 6px 16px; background: rgba(30, 41, 59, 0.4); border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 11px; color: #94a3b8;">
                    <span style="display: inline-flex; gap: 4px;">
                        <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%;"></span>
                        <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%; animation-delay: 0.2s;"></span>
                        <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%; animation-delay: 0.4s;"></span>
                    </span>
                    <span>AI Assistant is researching app details...</span>
                </div>

                <!-- INPUT AREA -->
                <div style="padding: 10px 12px; background: rgba(15, 23, 42, 0.95); border-top: 1px solid rgba(255, 255, 255, 0.08); display: flex; gap: 8px; align-items: flex-end;">
                    <textarea id="aiSupportInput" rows="1" placeholder="Ask anything about the app, overlays, or games..."
                        style="flex: 1; background: rgba(30, 41, 59, 0.8); border: 1.5px solid rgba(255, 255, 255, 0.12); border-radius: 10px; padding: 9px 12px; color: #ffffff; font-family: inherit; font-size: 12.5px; line-height: 1.4; resize: none; max-height: 110px; outline: none; transition: border-color 0.2s ease;"></textarea>
                    <button id="btnAiSupportSend" type="button" title="Send message"
                        style="background: linear-gradient(135deg, #0284c7, #2563eb); color: #ffffff; border: none; width: 38px; height: 38px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 14px; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4); flex-shrink: 0; transition: transform 0.15s ease;">
                        ➤
                    </button>
                </div>

                <!-- SETTINGS DRAWER / MODAL -->
                <div id="aiSupportSettingsModal"
                    style="position: absolute; inset: 0; background: rgba(10, 15, 26, 0.97); z-index: 10; display: none; flex-direction: column; padding: 18px; backdrop-filter: blur(12px);">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
                        <h3 style="margin: 0; font-size: 15px; font-weight: 800; color: #ffffff; display: flex; align-items: center; gap: 6px;">
                            ⚙️ AI Support Settings
                        </h3>
                        <button id="btnAiCloseSettings" type="button"
                            style="background: none; border: none; color: #94a3b8; font-size: 16px; cursor: pointer;">✕</button>
                    </div>

                    <div style="font-size: 11.5px; color: #94a3b8; margin-bottom: 16px; line-height: 1.4;">
                        Connect your own <strong>Gemini API Key</strong> or <strong>OpenAI API Key</strong> for full conversational answers. The key is stored locally on your device.
                    </div>

                    <!-- PROVIDER SELECTOR -->
                    <label style="font-size: 11px; font-weight: 700; color: #cbd5e1; margin-bottom: 4px; display: block;">AI Provider</label>
                    <select id="aiSettingProvider"
                        style="background: #1e293b; border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 8px; color: #ffffff; padding: 8px 10px; font-size: 12px; margin-bottom: 12px; width: 100%; outline: none;">
                        <option value="gemini">Google Gemini (Recommended - Free Tier Available)</option>
                        <option value="openai">OpenAI (ChatGPT / GPT-4o-mini)</option>
                    </select>

                    <!-- MODEL SELECTOR -->
                    <label style="font-size: 11px; font-weight: 700; color: #cbd5e1; margin-bottom: 4px; display: block;">Model</label>
                    <select id="aiSettingModel"
                        style="background: #1e293b; border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 8px; color: #ffffff; padding: 8px 10px; font-size: 12px; margin-bottom: 12px; width: 100%; outline: none;">
                        <option value="gemini-2.5-flash">gemini-2.5-flash (Fast & Accurate)</option>
                        <option value="gemini-1.5-flash">gemini-1.5-flash (Stable)</option>
                        <option value="gpt-4o-mini">gpt-4o-mini (OpenAI)</option>
                    </select>

                    <!-- API KEY INPUT -->
                    <label style="font-size: 11px; font-weight: 700; color: #cbd5e1; margin-bottom: 4px; display: block;">
                        API Key
                    </label>
                    <div style="position: relative; margin-bottom: 16px;">
                        <input id="aiSettingApiKey" type="password" placeholder="AIzaSy... or sk-..."
                            style="background: #1e293b; border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 8px; color: #ffffff; padding: 8px 36px 8px 10px; font-size: 12px; width: 100%; box-sizing: border-box; outline: none;" />
                        <button id="btnAiToggleKeyVisibility" type="button" title="Show/Hide Key"
                            style="position: absolute; right: 8px; top: 50%; transform: translateY(-50%); background: none; border: none; color: #94a3b8; font-size: 12px; cursor: pointer;">
                            👁️
                        </button>
                    </div>

                    <!-- TEST & SAVE -->
                    <div style="display: flex; gap: 8px; margin-top: auto;">
                        <button id="btnAiSaveSettings" type="button"
                            style="flex: 1; background: linear-gradient(135deg, #0284c7, #2563eb); color: #ffffff; border: none; border-radius: 8px; padding: 10px; font-size: 12px; font-weight: 700; cursor: pointer; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4);">
                            💾 Save & Apply
                        </button>
                        <button id="btnAiTestConnection" type="button"
                            style="background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.15); color: #ffffff; border-radius: 8px; padding: 10px 14px; font-size: 12px; font-weight: 600; cursor: pointer;">
                            ⚡ Test
                        </button>
                    </div>
                    <div id="aiSettingsStatusMsg" style="margin-top: 8px; font-size: 11px; text-align: center; min-height: 16px;"></div>
                </div>
            </div>
        `;

        document.body.appendChild(root);

        // Inject keyframes style
        const style = document.createElement('style');
        style.textContent = `
            @keyframes aiPulseDot {
                0%, 100% { opacity: 1; transform: scale(1); }
                50% { opacity: 0.4; transform: scale(0.85); }
            }
            .ai-dot-pulse {
                animation: aiPulseDot 1.2s infinite ease-in-out;
            }
            #btnAiSupportLauncher:hover {
                transform: translateY(-2px);
                box-shadow: 0 14px 30px rgba(2, 132, 199, 0.55), 0 0 24px rgba(56, 189, 248, 0.45);
            }
            .ai-quick-chip:hover {
                background: rgba(56, 189, 248, 0.2) !important;
                border-color: #38bdf8 !important;
            }
            #aiSupportInput:focus {
                border-color: #38bdf8 !important;
                box-shadow: 0 0 10px rgba(56, 189, 248, 0.25);
            }
        `;
        document.head.appendChild(style);

        bindWidgetEvents();
        renderMessages();
    }

    // Render Chat Messages in both the Window and Tab View
    function renderMessages() {
        const renderListContent = (list) => {
            if (!list) return;
            list.innerHTML = chatHistory.map((msg, idx) => {
                const isBot = msg.sender === 'bot';
                return `
                    <div style="display: flex; gap: 8px; align-items: flex-start; justify-content: ${isBot ? 'flex-start' : 'flex-end'};">
                        ${isBot ? `
                            <div style="width: 28px; height: 28px; border-radius: 8px; background: linear-gradient(135deg, #0284c7, #2563eb); display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0; box-shadow: 0 2px 8px rgba(2, 132, 199, 0.35);">
                                🤖
                            </div>
                        ` : ''}
                        <div style="max-width: 84%; background: ${isBot ? 'rgba(30, 41, 59, 0.85)' : 'linear-gradient(135deg, #0284c7, #1d4ed8)'}; border: 1px solid ${isBot ? 'rgba(255, 255, 255, 0.08)' : 'rgba(56, 189, 248, 0.4)'}; border-radius: ${isBot ? '4px 14px 14px 14px' : '14px 4px 14px 14px'}; padding: 10px 14px; color: #ffffff; font-size: 13px; line-height: 1.5; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3); word-break: break-word;">
                            ${isBot ? renderMarkdown(msg.text) : msg.text.replace(/</g, '&lt;').replace(/>/g, '&gt;')}
                            ${isBot && idx > 0 ? `
                                <div style="margin-top: 8px; padding-top: 6px; border-top: 1px solid rgba(255,255,255,0.06); display: flex; justify-content: flex-end;">
                                    <button type="button" onclick="navigator.clipboard.writeText('${msg.text.replace(/'/g, "\\'").replace(/\n/g, '\\n')}'); if(window.showToast) window.showToast('📋 Copied answer');"
                                        style="background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); color: #cbd5e1; font-size: 10.5px; border-radius: 4px; padding: 2px 8px; cursor: pointer;">
                                        📋 Copy Answer
                                    </button>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                `;
            }).join('');
            list.scrollTop = list.scrollHeight;
        };

        renderListContent(document.getElementById('aiSupportMessageList'));
        renderListContent(document.getElementById('aiTabMessageList'));
    }

    // Send Message Handler
    async function handleUserSendMessage(overrideText = null) {
        if (isAwaitingReply) return;

        const floatInput = document.getElementById('aiSupportInput');
        const tabInput = document.getElementById('aiTabInput');
        const text = (overrideText || (tabInput && tabInput.value) || (floatInput && floatInput.value) || '').trim();
        if (!text) return;

        // Clear inputs and reset heights
        if (floatInput) {
            floatInput.value = '';
            floatInput.style.height = 'auto';
        }
        if (tabInput) {
            tabInput.value = '';
            tabInput.style.height = 'auto';
        }

        // Add user message
        chatHistory.push({ sender: 'user', text: text });
        saveHistory();
        renderMessages();

        // Show typing indicators
        const indFloat = document.getElementById('aiTypingIndicator');
        const indTab = document.getElementById('aiTabTypingIndicator');
        if (indFloat) indFloat.style.display = 'flex';
        if (indTab) indTab.style.display = 'flex';
        isAwaitingReply = true;

        let replyText = '';

        try {
            if (aiSettings.apiKey && aiSettings.apiKey.trim().length > 5) {
                // Use online AI Provider
                if (aiSettings.provider === 'openai') {
                    replyText = await callOpenAIAPI(text, aiSettings.apiKey, aiSettings.model);
                } else {
                    replyText = await callGeminiAPI(text, aiSettings.apiKey, aiSettings.model);
                }
            } else {
                // Simulate smart typing delay for offline knowledge base
                await new Promise(r => setTimeout(r, 650));
                replyText = queryOfflineKnowledge(text);
            }
        } catch (err) {
            console.error('[AI Support Error]:', err);
            // Fall back to offline knowledge base if API fails
            const offlineAns = queryOfflineKnowledge(text);
            replyText = `⚠️ **API Notice:** ${err.message}\n\n*Falling back to local application knowledge base:*\n\n${offlineAns}`;
        } finally {
            isAwaitingReply = false;
            if (indFloat) indFloat.style.display = 'none';
            if (indTab) indTab.style.display = 'none';

            chatHistory.push({ sender: 'bot', text: replyText });
            saveHistory();
            renderMessages();
        }
    }

    // Bind Widget Interactive Events
    function bindWidgetEvents() {
        const launcher = document.getElementById('btnAiSupportLauncher');
        const win = document.getElementById('aiSupportWindow');
        const closeBtn = document.getElementById('btnAiCloseWindow');
        const settingsBtn = document.getElementById('btnAiOpenSettings');
        const closeSettingsBtn = document.getElementById('btnAiCloseSettings');
        const settingsModal = document.getElementById('aiSupportSettingsModal');
        const sendBtn = document.getElementById('btnAiSupportSend');
        const input = document.getElementById('aiSupportInput');
        const clearBtn = document.getElementById('btnAiClearChat');

        // Toggle window
        if (launcher && win) {
            launcher.addEventListener('click', () => {
                const isOpen = win.style.display === 'flex';
                win.style.display = isOpen ? 'none' : 'flex';
                if (!isOpen && input) {
                    setTimeout(() => input.focus(), 100);
                }
            });
        }

        if (closeBtn && win) {
            closeBtn.addEventListener('click', () => {
                win.style.display = 'none';
            });
        }

        // Settings modal
        if (settingsBtn && settingsModal) {
            settingsBtn.addEventListener('click', () => {
                // Populate current settings
                const pSel = document.getElementById('aiSettingProvider');
                const mSel = document.getElementById('aiSettingModel');
                const kInp = document.getElementById('aiSettingApiKey');
                if (pSel) pSel.value = aiSettings.provider || 'gemini';
                if (mSel) mSel.value = aiSettings.model || 'gemini-2.5-flash';
                if (kInp) kInp.value = aiSettings.apiKey || '';
                settingsModal.style.display = 'flex';
            });
        }

        if (closeSettingsBtn && settingsModal) {
            closeSettingsBtn.addEventListener('click', () => {
                settingsModal.style.display = 'none';
            });
        }

        // Toggle key visibility
        const toggleKey = document.getElementById('btnAiToggleKeyVisibility');
        if (toggleKey) {
            toggleKey.addEventListener('click', () => {
                const kInp = document.getElementById('aiSettingApiKey');
                if (kInp) {
                    kInp.type = kInp.type === 'password' ? 'text' : 'password';
                }
            });
        }

        // Save Settings
        const saveSettingsBtn = document.getElementById('btnAiSaveSettings');
        if (saveSettingsBtn) {
            saveSettingsBtn.addEventListener('click', () => {
                const pSel = document.getElementById('aiSettingProvider');
                const mSel = document.getElementById('aiSettingModel');
                const kInp = document.getElementById('aiSettingApiKey');
                const status = document.getElementById('aiSettingsStatusMsg');

                aiSettings.provider = pSel?.value || 'gemini';
                aiSettings.model = mSel?.value || 'gemini-2.5-flash';
                aiSettings.apiKey = kInp?.value?.trim() || '';

                saveSettings();

                const badge = document.getElementById('aiActiveModelBadge');
                if (badge) {
                    badge.innerText = aiSettings.provider === 'openai' ? 'OpenAI' : 'Gemini';
                }

                if (status) {
                    status.style.color = '#34d399';
                    status.innerText = '✅ Settings saved successfully!';
                    setTimeout(() => {
                        if (settingsModal) settingsModal.style.display = 'none';
                        status.innerText = '';
                    }, 800);
                }
            });
        }

        // Test Connection
        const testBtn = document.getElementById('btnAiTestConnection');
        if (testBtn) {
            testBtn.addEventListener('click', async () => {
                const pSel = document.getElementById('aiSettingProvider');
                const mSel = document.getElementById('aiSettingModel');
                const kInp = document.getElementById('aiSettingApiKey');
                const status = document.getElementById('aiSettingsStatusMsg');

                const prov = pSel?.value || 'gemini';
                const mod = mSel?.value || 'gemini-2.5-flash';
                const key = kInp?.value?.trim() || '';

                if (!key) {
                    if (status) {
                        status.style.color = '#f87171';
                        status.innerText = '⚠️ Please enter an API key first.';
                    }
                    return;
                }

                if (status) {
                    status.style.color = '#38bdf8';
                    status.innerText = 'Testing connection...';
                }

                try {
                    if (prov === 'openai') {
                        await callOpenAIAPI("Ping", key, mod);
                    } else {
                        await callGeminiAPI("Ping", key, mod);
                    }
                    if (status) {
                        status.style.color = '#34d399';
                        status.innerText = '✨ Connection successful! Model ready.';
                    }
                } catch (e) {
                    if (status) {
                        status.style.color = '#f87171';
                        status.innerText = `❌ Error: ${e.message}`;
                    }
                }
            });
        }

        // Send triggers
        if (sendBtn) {
            sendBtn.addEventListener('click', () => handleUserSendMessage());
        }

        if (input) {
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleUserSendMessage();
                }
            });

            // Auto resize input
            input.addEventListener('input', () => {
                input.style.height = 'auto';
                input.style.height = Math.min(input.scrollHeight, 110) + 'px';
            });
        }

        // Clear chat
        if (clearBtn) {
            clearBtn.addEventListener('click', () => {
                chatHistory = [
                    {
                        sender: 'bot',
                        text: "🧹 **Chat cleared.** How can I assist you with your Studio streaming apps or game overlays?"
                    }
                ];
                saveHistory();
                renderMessages();
            });
        }

        // Quick topic chip clicks
        document.querySelectorAll('.ai-quick-chip').forEach(chip => {
            chip.addEventListener('click', () => {
                const q = chip.getAttribute('data-query');
                if (q) handleUserSendMessage(q);
            });
        });
    }

    // Render Full AI Support Tab Pane (#tab-support)
    function renderAiSupportTab() {
        const container = document.getElementById('tab-support');
        if (!container) return;

        container.innerHTML = `
            <div style="max-width: 1360px; margin: 0 auto; display: flex; flex-direction: column; gap: 20px;">
                <!-- HERO BANNER -->
                <div style="background: linear-gradient(135deg, rgba(2, 132, 199, 0.16) 0%, rgba(15, 23, 42, 0.95) 50%, rgba(30, 58, 138, 0.28) 100%); border: 1.5px solid rgba(56, 189, 248, 0.45); border-radius: 20px; padding: 22px 26px; box-shadow: 0 16px 40px rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: space-between; gap: 20px; flex-wrap: wrap;">
                    <div style="display: flex; align-items: center; gap: 16px;">
                        <div style="width: 58px; height: 58px; border-radius: 16px; background: linear-gradient(135deg, #0284c7, #2563eb); display: flex; align-items: center; justify-content: center; font-size: 28px; box-shadow: 0 8px 24px rgba(2, 132, 199, 0.45); flex-shrink: 0;">
                            🤖
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                                <h2 style="font-size: 22px; font-weight: 800; color: #fff; margin: 0;">Studio AI Customer Support & Assistant</h2>
                                <span style="background: rgba(34, 197, 94, 0.2); color: #4ade80; border: 1px solid #22c55e; font-size: 10.5px; font-weight: 800; padding: 3px 10px; border-radius: 999px;">● 24/7 ONLINE</span>
                                <span style="background: rgba(56, 189, 248, 0.15); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.35); font-size: 10.5px; font-weight: 800; padding: 3px 10px; border-radius: 999px;">🔒 ZERO PERSONAL DATA</span>
                            </div>
                            <p style="font-size: 13px; color: #94a3b8; margin-top: 4px; margin-bottom: 0;">
                                Instant answers for game interactions, OBS overlays, TikTok gift mapping, song requests, and lucky wheel configurations.
                            </p>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <button type="button" class="btn btn-secondary btn-sm" onclick="window.toggleAiSupportSettingsModal()"
                            style="background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.18); color: #cbd5e1; display: flex; align-items: center; gap: 6px; padding: 9px 15px; border-radius: 10px; font-weight: 700; cursor: pointer;">
                            ⚙️ Configure AI API Key
                        </button>
                        <button type="button" class="btn btn-primary btn-sm" onclick="window.openStudioAiSupport()"
                            style="background: linear-gradient(135deg, #0284c7, #2563eb); border: 1px solid #38bdf8; color: #fff; display: flex; align-items: center; gap: 6px; padding: 9px 18px; border-radius: 10px; font-weight: 800; cursor: pointer; box-shadow: 0 4px 14px rgba(2, 132, 199, 0.4);">
                            💬 Floating Popout
                        </button>
                    </div>
                </div>

                <!-- 2-COLUMN ARRANGEMENT -->
                <div style="display: grid; grid-template-columns: 360px 1fr; gap: 20px;">
                    
                    <!-- LEFT COLUMN: QUICK KNOWLEDGE CATEGORIES & TOPICS -->
                    <div style="display: flex; flex-direction: column; gap: 12px;">
                        <div style="font-size: 12px; font-weight: 800; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px; display: flex; align-items: center; gap: 6px;">
                            <span>📚</span><span>Quick Help Topics</span>
                        </div>

                        <!-- TOPIC 1 -->
                        <div onclick="window.askStudioAiDirect('What is this app and how does it interact with games?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🎮</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">What is this Platform?</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Interactive audience-to-game streaming suite overview.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 2 -->
                        <div onclick="window.askStudioAiDirect('How does the app interact with games in real-time?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🕹️</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">Game Interaction Engine</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Simulated keystrokes, coordinate clicks & mod bridge.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 3 -->
                        <div onclick="window.askStudioAiDirect('How do I add overlays to OBS or TikTok Live Studio?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🎬</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">OBS & Stream Overlays</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Browser source URLs, canvas size & setup guide.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 4 -->
                        <div onclick="window.askStudioAiDirect('How do TikTok gifts connect to game commands?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🎁</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">TikTok Gifts to Spawns</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Link gifts (Rose, Perfume, Heart) to in-game actions.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 5 -->
                        <div onclick="window.askStudioAiDirect('How does the Song Request and Spotify system work?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🎶</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">Song Requests & Vinyl</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Viewer !play commands, Spotify queue & vinyl overlay.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 6 -->
                        <div onclick="window.askStudioAiDirect('How do Lucky Wheels, 3D Slots and 3D Claw visualizers work?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(56, 189, 248, 0.1)'; this.style.borderColor='#38bdf8';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🎡</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fff;">Wheels & 3D Claw Machine</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Reel, 2D Wheel, Vegas Slot & UFO Catcher modes.</div>
                                </div>
                            </div>
                        </div>

                        <!-- TOPIC 7 -->
                        <div onclick="window.askStudioAiDirect('How to fix overlay not working or disconnected?')"
                            style="cursor: pointer; background: rgba(15, 23, 42, 0.85); border: 1px solid rgba(239, 68, 68, 0.25); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                            onmouseover="this.style.background='rgba(239, 68, 68, 0.12)'; this.style.borderColor='#ef4444';"
                            onmouseout="this.style.background='rgba(15, 23, 42, 0.85)'; this.style.borderColor='rgba(239, 68, 68, 0.25)';">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="font-size: 20px;">🔧</span>
                                <div>
                                    <div style="font-size: 13px; font-weight: 800; color: #fca5a5;">Troubleshooting & Fixes</div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">Connection recovery, refresh cache, and game ports.</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN: INTERACTIVE CHAT CONSOLE -->
                    <div style="background: #0f172a; border: 1.5px solid rgba(56, 189, 248, 0.3); border-radius: 18px; display: flex; flex-direction: column; height: 620px; overflow: hidden; box-shadow: 0 12px 36px rgba(0,0,0,0.4);">
                        
                        <!-- CHAT CONSOLE HEADER -->
                        <div style="padding: 14px 18px; background: rgba(30, 41, 59, 0.7); border-bottom: 1px solid rgba(255, 255, 255, 0.08); display: flex; align-items: center; justify-content: space-between;">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="width: 8px; height: 8px; border-radius: 50%; background: #22c55e; box-shadow: 0 0 8px #22c55e;"></span>
                                <span style="font-size: 14px; font-weight: 800; color: #fff;">Interactive AI Support Console</span>
                                <span style="font-size: 10.5px; color: #94a3b8;">• Strictly technical guidance</span>
                            </div>
                            <button type="button" onclick="window.clearStudioAiChatHistory()"
                                style="background: none; border: 1px solid rgba(255,255,255,0.15); color: #94a3b8; font-size: 11px; border-radius: 6px; padding: 4px 10px; cursor: pointer;">
                                🧹 Clear Chat
                            </button>
                        </div>

                        <!-- MESSAGES LIST -->
                        <div id="aiTabMessageList"
                            style="flex: 1; overflow-y: auto; padding: 16px; display: flex; flex-direction: column; gap: 12px; scroll-behavior: smooth;">
                        </div>

                        <!-- TYPING INDICATOR -->
                        <div id="aiTabTypingIndicator"
                            style="display: none; align-items: center; gap: 8px; padding: 6px 18px; background: rgba(30, 41, 59, 0.4); border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 11.5px; color: #94a3b8;">
                            <span style="display: inline-flex; gap: 4px;">
                                <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%;"></span>
                                <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%; animation-delay: 0.2s;"></span>
                                <span class="ai-dot-pulse" style="width: 5px; height: 5px; background: #38bdf8; border-radius: 50%; animation-delay: 0.4s;"></span>
                            </span>
                            <span>AI Assistant is researching app details...</span>
                        </div>

                        <!-- CHAT INPUT AREA -->
                        <div style="padding: 12px 14px; background: rgba(15, 23, 42, 0.98); border-top: 1px solid rgba(255, 255, 255, 0.08); display: flex; gap: 10px; align-items: flex-end;">
                            <textarea id="aiTabInput" rows="1" placeholder="Type any question about the studio, game controls, or stream overlays (Press Enter to Send)..."
                                onkeydown="if(event.key==='Enter' && !event.shiftKey){ event.preventDefault(); window.sendStudioAiChatMessage(); }"
                                style="flex: 1; background: rgba(30, 41, 59, 0.85); border: 1.5px solid rgba(255, 255, 255, 0.15); border-radius: 10px; padding: 10px 14px; color: #ffffff; font-family: inherit; font-size: 13px; line-height: 1.4; resize: none; max-height: 110px; outline: none;"></textarea>
                            <button type="button" onclick="window.sendStudioAiChatMessage()"
                                style="background: linear-gradient(135deg, #0284c7, #2563eb); color: #ffffff; border: none; padding: 10px 20px; border-radius: 10px; font-weight: 800; font-size: 13px; cursor: pointer; display: flex; align-items: center; gap: 6px; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4); flex-shrink: 0;">
                                <span>Send</span> <span>➤</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        renderMessages();
    }

    // Window Exposure
    window.askStudioAiDirect = function(question) {
        handleUserSendMessage(question);
    };

    window.sendStudioAiChatMessage = function() {
        handleUserSendMessage();
    };

    window.clearStudioAiChatHistory = function() {
        chatHistory = [
            {
                sender: 'bot',
                text: "🧹 **Chat cleared.** How can I assist you with your Studio streaming apps, game overlays, or TikTok commands?"
            }
        ];
        saveHistory();
        renderMessages();
    };

    window.toggleAiSupportSettingsModal = function() {
        const modal = document.getElementById('aiSupportSettingsModal');
        const win = document.getElementById('aiSupportWindow');
        if (win) win.style.display = 'flex';
        if (modal) modal.style.display = 'flex';
    };

    window.renderAiSupportTab = renderAiSupportTab;

    // Initialization
    function init() {
        loadSettings();
        loadHistory();
        injectSupportWidgetUI();
        if (document.getElementById('tab-support')) {
            renderAiSupportTab();
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.openStudioAiSupport = function (initialQuestion = '') {
        const win = document.getElementById('aiSupportWindow');
        if (win) win.style.display = 'flex';
        if (initialQuestion) {
            handleUserSendMessage(initialQuestion);
        }
    };
})();
