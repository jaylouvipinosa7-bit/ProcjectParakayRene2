/**
 * RENEAI Support - 100% Offline Built-in Stream Assistant
 * Dependency-free, runs entirely on-device with zero external API calls, zero server dependencies,
 * zero cost, and complete privacy.
 */

(function () {
    'use strict';

    // =========================================================================
    // 1. EMBEDDED DEFAULT KNOWLEDGE & INTENT BUNDLES (Guarantees 100% Offline Operation)
    // =========================================================================

    const DEFAULT_PERSONA = {
        name: "RENEAI Support",
        title: "Built-in Offline Stream Assistant",
        version: "2.0.0",
        welcome: {
            greeting: "👋 **Hello! I'm RENEAI Support.**\n\nI'm your **100% offline, built-in stream assistant** for RENEarn Studio! I run entirely on your PC with zero API keys and zero internet required.\n\nAsk me anything about **interactive game triggers, OBS overlays, TikTok gift links, Spotify music, or connection troubleshooting**!",
            chips: [
                "What is this app?",
                "How do I set up OBS overlays?",
                "Link TikTok gifts to spawns",
                "Fix connection problems"
            ]
        },
        placeholders: [
            "Ask 'What is this app?' or 'Who are you?'...",
            "Ask 'How do I add overlays to OBS?'...",
            "Ask 'How do TikTok gifts connect to games?'...",
            "Ask 'What games are supported?'...",
            "Ask 'How does Spotify song request work?'...",
            "Ask 'Paano mag-connect sa TikTok?'..."
        ],
        jokes: [
            "Why do zombies love live streamers? Because of all the fresh *brains* chatting in the comments! 🧟‍♂️🧠",
            "Why did the streamer bring a ladder to Twitch? Because they heard the viewer numbers were through the roof! 🪜📈",
            "What's a PvZ zombie's favorite social media? *Tik-Toc-Toc-Brains!* 📱🧟",
            "Why did the keyboard go to the gym? It wanted to improve its *space-bar*! ⌨️💪",
            "How does a streamer stay cool during a hot gaming session? They stand right next to their *fans*! 🪭🎮",
            "Why couldn't the skeleton stream Left 4 Dead? He didn't have the *guts*! 💀🕹️",
            "What do you call a live streamer who plays Plants vs Zombies all night? A *night-shade* warrior! 🌻🌙",
            "Why did the computer catch a cold? Because someone left a *Windows* open! 🪟❄️",
            "Why did the gamer put his console in the fridge? He wanted to play some *cool* games! 🧊🎮",
            "What did one OBS overlay say to the other? *'I've got you covered on stream!'* 🎬✨",
            "Why was the modder always calm? Because they knew how to *handle exceptions*! 🛡️💻",
            "Why did the live stream stop? Because the Wi-Fi router needed a *stream nap*! 💤📶",
            "How do you organize a space tournament in RENEarn? You *planet*! 🪐🏆",
            "Why did the gamer sit on the clock? He wanted to be *on stream on time*! ⏰🎯",
            "What kind of tea do gamers drink during 24-hour marathons? *Responsi-tea*! 🍵🔥"
        ]
    };

    const DEFAULT_SYNONYMS = {
        "gift": ["rose", "perfume", "heart", "coins", "diamonds", "regalo", "galaxy", "gifts", "donations", "tip", "spawns"],
        "overlay": ["obs", "browser source", "stream", "visualizer", "screen", "widget", "hud", "display", "canvas", "url", "urls"],
        "spawn": ["summon", "drop", "deploy", "call", "generate", "create", "labas", "ilabas", "spawns"],
        "wheel": ["spinner", "reel", "roulette", "slot", "gacha", "claw", "ufo", "roleta"],
        "song": ["music", "spotify", "!play", "!sr", "vinyl", "kanta", "tugtog", "audio", "track", "request"],
        "mod": ["melonloader", "injection", "bridge", "hook", "vscript", "cleo", "modded"],
        "connect": ["link", "tiktok", "username", "room", "sync", "ikabit", "ikonek", "login"],
        "game": ["platform", "studio", "laro", "pc game", "pvz", "hybrid", "fusion"],
        "troubleshoot": ["fix", "error", "broken", "sira", "ayaw", "problem", "disconnected", "bug", "stuck"],
        "size": ["resolution", "width", "height", "canvas", "sukat", "haba", "lapad"]
    };

    const DEFAULT_KNOWLEDGE = [
        {
            id: "obs_overlays",
            title: "OBS & TikTok Live Studio Overlay Setup",
            keywords: ["obs", "tiktok live studio", "browser source", "overlay", "overlays", "url", "urls", "canvas", "size", "resolution", "stream", "add overlay"],
            answer_en: "### 🎬 How to Add Overlays in OBS & TikTok Live Studio:\n\n1. Open **OBS Studio** or **TikTok Live Studio**.\n2. In your **Scenes / Sources** panel, click **+ Add Source** and choose **Browser**.\n3. Enter the local URL of the overlay you want to display:\n   - **Wheel & Reel**: `http://localhost:8080/overlay-spinner.html`\n   - **Live Gift Counter**: `http://localhost:8080/overlay-counter.html`\n   - **Side Overlay (Leaderboard & Triggers)**: `http://localhost:8080/overlay-side.html`\n   - **Gacha Capsule Machine**: `http://localhost:8080/overlay-gacha.html`\n   - **Song Request & Spinning Vinyl**: `http://localhost:8080/overlay-songrequest.html`\n   - **Team Battle (Red vs Blue)**: `http://localhost:8080/overlay-teambattle.html`\n   - **Physics Coin Jar**: `http://localhost:8080/overlay-jar.html`\n4. Recommended Canvas Resolution:\n   - **Vertical Mobile Stream (9:16)**: Width `1080` × Height `1920`\n   - **Horizontal Standard Stream (16:9)**: Width `1920` × Height `1080`\n5. Check the box **'Shutdown source when not visible'** (optional) and click **OK**.\n6. Make sure RENEarn Studio is running on **port 8080**!",
            answer_tl: "### 🎬 Paano Maglagay ng Overlays sa OBS / TikTok Live Studio:\n\n1. Buksan ang **OBS Studio** o **TikTok Live Studio**.\n2. Sa **Sources** panel, i-click ang **+** at piliin ang **Browser Source**.\n3. I-paste ang local URL ng gusto mong overlay:\n   - **Wheel & Reel**: `http://localhost:8080/overlay-spinner.html`\n   - **Live Gift Counter**: `http://localhost:8080/overlay-counter.html`\n   - **Side Overlay**: `http://localhost:8080/overlay-side.html`\n   - **Gacha Machine**: `http://localhost:8080/overlay-gacha.html`\n   - **Song Request & Vinyl**: `http://localhost:8080/overlay-songrequest.html`\n   - **Team Battle**: `http://localhost:8080/overlay-teambattle.html`\n   - **Interactive Jar**: `http://localhost:8080/overlay-jar.html`\n4. Recommended Resolution:\n   - **Vertical (Mobile 9:16)**: `1080` width × `1920` height\n   - **Horizontal (16:9)**: `1920` width × `1080` height\n5. Siguraduhing tumatakbo ang Studio server sa **port 8080**!",
            related_ids: ["wheels_gacha", "song_requests", "troubleshooting"]
        },
        {
            id: "song_requests",
            title: "Song Request & Spinning Vinyl Player Overlay",
            keywords: ["song", "music", "spotify", "!play", "!sr", "vinyl", "queue", "audio", "track", "request"],
            answer_en: "### 🎶 Setting Up the Song Request & Vinyl Overlay:\n\n1. **Add the Overlay to OBS**:\n   - Add a Browser Source with URL: `http://localhost:8080/overlay-songrequest.html`\n   - Recommended resolution: Width `1080` × Height `1920` (or `600` × `350` for just the player widget).\n2. **Viewer Chat Commands**:\n   - Viewers can type `!play <song name>` or `!sr <song title or artist>` directly in your live stream chat to request songs.\n3. **Spotify Integration**:\n   - Connect Spotify in the **Song Request** dashboard tab to automatically push viewer requests directly into your active Spotify playback queue.\n4. **Streamer Controls**:\n   - Streamers can skip (`!skip`), clear the queue, or blacklist inappropriate tracks directly from the dashboard.",
            answer_tl: "### 🎶 Song Request at Vinyl Player Overlay Guide:\n\n1. **Ilagay sa OBS**:\n   - Mag-add ng Browser Source gamit ang URL: `http://localhost:8080/overlay-songrequest.html`\n2. **Chat Commands ng Viewers**:\n   - Mag-type lang ang viewers ng `!play <pangalan ng kanta>` sa live stream chat para pumila ang kanta.\n3. **Spotify Integration**:\n   - Sa **Song Request** tab, i-connect ang Spotify para kusang pumasok sa queue ang mga kanta!\n4. **Overlay Animation**:\n   - May animated 33 RPM spinning vinyl record, cover art, requester username, at audio visualizer!",
            related_ids: ["obs_overlays", "tts_voice"]
        },
        {
            id: "gift_mapping",
            title: "Linking TikTok Gifts to In-Game Spawns & Commands",
            keywords: ["gift", "gifts", "link", "rose", "perfume", "heart", "spawn", "summon", "action", "trigger", "spawns", "command", "mapping", "paano i-link"],
            answer_en: "### 🎁 How to Link TikTok Gifts to In-Game Spawns:\n\n1. Go to the **Gift Commands** tab in the left sidebar navigation.\n2. Choose which gift to map (e.g. **Rose**, **Perfume**, **Heart Me**, **GG**, **Galaxy**, etc.).\n3. Click the **+** button on the trigger card to assign in-game commands:\n   - **In-Game Unit Summons**: Select unit (e.g. *Ultimate Spruce*, *Titan Gargantuar*, *Nuclear Doom Cherry*).\n   - **Simulated Keystrokes**: Assign hotkeys (1–9, Space, Q, E) to trigger spells or activate in-game items.\n   - **Coordinate Clicks**: Assign calibrated screen coordinates to click buttons or tiles inside your game.\n   - **Lucky Wheel Spin**: Trigger a reel or wheel spin whenever the gift is received.\n4. Configure **Repetition**, **Interval (ms)**, and **Multiplier** (spawns scale with gift count).\n5. Click **Save**—triggers are live instantly with 0ms latency!",
            answer_tl: "### 🎁 Paano I-link ang TikTok Gifts sa In-Game Actions:\n\n1. Pumunta sa **Gift Commands** sa kaliwang navigation menu.\n2. Piliin ang regalong gusto mong i-assign (hal. **Rose**, **Perfume**, **Heart Me**, **Galaxy**).\n3. I-click ang **+** para magdagdag ng command:\n   - **Unit Spawn**: Pumili ng unit (hal. *Titan Gargantuar*, *Ultimate Spruce*).\n   - **Keystrokes**: Magpindot ng hotkey (1-9, Space, Q, E).\n   - **Screen Click**: Mag-click sa eksaktong coordinate sa screen ng laro.\n   - **Lucky Wheel**: Magpaikot ng roulette tuwing may nag-regalo.\n4. I-set ang dami (Repetition) at multiplier kung gaano karami ang lalabas.\n5. I-save at aktibo na agad ito sa live stream mo!",
            related_ids: ["tiktok_connection", "supported_games", "wheels_gacha"]
        },
        {
            id: "tiktok_connection",
            title: "Connecting TikTok LIVE to RENEarn Studio",
            keywords: ["tiktok", "connect", "connection", "link", "username", "room id", "live", "paano mag-connect", "mag-connect", "studio link"],
            answer_en: "### 📱 How to Connect TikTok LIVE Stream:\n\n1. Open **TikTok LIVE Studio** on your PC and start your live stream.\n2. In RENEarn Studio, locate the **TikTok LIVE Stream Connection** card on the main dashboard.\n3. Type your TikTok `@username` in the input field.\n4. Click the pink **Connect** button.\n5. The status pill will flip to **LIVE CONNECTED ✓** and your Webcast Room ID, live Viewers, and Likes will appear in real-time!\n\n*(Note: Your TikTok account must be actively streaming LIVE before clicking Connect, otherwise the TikTok server will report 'Room not found'.)*",
            answer_tl: "### 📱 Paano I-connect ang TikTok LIVE sa Studio:\n\n1. Buksan ang **TikTok LIVE Studio** sa PC at simulan ang iyong live stream.\n2. Sa RENEarn Studio dashboard, hanapin ang **TikTok LIVE Stream Connection** card.\n3. I-type ang iyong TikTok `@username` sa kahon.\n4. I-click ang pink **Connect** button.\n5. Magiging **LIVE CONNECTED ✓** ang status at lalabas agad ang iyong Room ID, Viewers, at Likes!\n\n*(Tandaan: Dapat LIVE ka na muna sa TikTok bago mag-click ng Connect para mahanap ang live room mo.)*",
            related_ids: ["gift_mapping", "troubleshooting"]
        },
        {
            id: "supported_games",
            title: "Supported Games & Game Engines Roster",
            keywords: ["supported games", "games", "list", "game roster", "pvz", "hybrid", "fusion", "minecraft", "left 4 dead", "gta", "fortnite", "roblox", "anong laro"],
            answer_en: "### 🕹️ Supported Games in RENEarn Studio:\n\nRENEarn Studio features direct support and preset configs for:\n1. 🌻 **Plants vs. Zombies Fusion 4.0** (Direct MelonLoader mod link, 150+ actions)\n2. 🧟 **Plants vs. Zombies: Hybrid Edition** (Mutations, hybrid plants & zombies)\n3. 🌿 **Plants vs. Zombies: Classic / GOTY** (Memory injection)\n4. 🌊 **Zombie Tsunami (PC)** (Crowd horde runner automation)\n5. ⛏️ **Minecraft & Universal** (Universal Mod injection & socket link)\n6. 🧟‍♂️ **Left 4 Dead 2** (Source Engine VPK hook & VScript bridge)\n7. 🚗 **GTA San Andreas** (CLEO & ASI memory link)\n8. 💥 **GTA V Chaos** (Chaos mod bridge)\n9. 🏰 **Resident Evil 4** (Survival horror memory hooks)\n10. ⚔️ **TABS Simulator** (Physics warfare sandbox)\n\n*(Note: Games not listed above—such as **Fortnite** or **Valorant**—are not natively supported because they run aggressive anti-cheat systems that block input automation and overlay injection.)*",
            answer_tl: "### 🕹️ Mga Larong Suportado ng RENEarn Studio:\n\nMay direct mod links at preset triggers para sa:\n1. 🌻 **PvZ Fusion 4.0** (MelonLoader mod bridge)\n2. 🧟 **PvZ Hybrid Edition**\n3. 🌿 **PvZ Classic / GOTY**\n4. 🌊 **Zombie Tsunami (PC)**\n5. ⛏️ **Minecraft & Universal**\n6. 🧟‍♂️ **Left 4 Dead 2** (VPK hook)\n7. 🚗 **GTA San Andreas** (CLEO link)\n8. 💥 **GTA V Chaos**\n9. 🏰 **Resident Evil 4**\n10. ⚔️ **TABS Simulator**\n\n*(Paalala: Ang mga larong tulad ng **Fortnite** ay hindi suportado dahil sa mahigpit nilang anti-cheat na nagba-block ng stream automation.)*",
            related_ids: ["gift_mapping", "platform_identity"]
        },
        {
            id: "wheels_gacha",
            title: "Lucky Wheel, 3D Slots & Gacha Box Overlays",
            keywords: ["wheel", "spinner", "reel", "slot", "gacha", "claw", "ufo", "odds", "prizes", "weights"],
            answer_en: "### 🎡 Lucky Wheel & Gacha Overlay Modes:\n\nThe studio provides 4 dynamic visualizer modes via `http://localhost:8080/overlay-spinner.html`:\n1. **Horizontal CS:GO Reel**: Ticker tape with rarity borders and sound effects.\n2. **Classic 2D Wheel**: High-precision spinning wheel with customizable sector weights.\n3. **3D Vegas Slot Machine**: 3-cylinder reel spinner with jackpot alerts.\n4. **3D Gacha Box / UFO Claw**: Japanese capsule dropper with physics bounces.\n\nCustomize prizes, weights, rarity colors, and avatar needles in the **Lucky Wheel** tab!",
            answer_tl: "### 🎡 Lucky Wheel at 3D Gacha Modes:\n\nPwede kang pumili sa 4 na iba't ibang styles gamit ang `http://localhost:8080/overlay-spinner.html`:\n1. **Horizontal Reel**: Parang CS:GO case opening ticker.\n2. **Classic 2D Wheel**: Roulette wheel of fortune.\n3. **3D Slot Machine**: Vegas 3-reel slots.\n4. **3D Gacha Box**: Capsule toy machine na may physics drops.\n\nI-customize ang prizes at odds sa **Lucky Wheel** navigation tab!",
            related_ids: ["obs_overlays", "gift_mapping"]
        },
        {
            id: "tts_voice",
            title: "AI Voice TTS Setup & Personas",
            keywords: ["tts", "voice", "speech", "personas", "boses", "text to speech", "read", "audio"],
            answer_en: "### 🗣️ AI Voice TTS (Text-to-Speech) System:\n\nThe studio can read viewer questions and chat comments aloud on your stream using 8 built-in personas:\n- **Adam Gamer** (Hype male gamer)\n- **Sakura Anime** (Cheerful upbeat voice)\n- **Robot X** (Futuristic synth cyborg)\n- **Jenny Host** (Professional podcast presenter)\n- **Ate May Pinay** (Warm Tagalog/English bilingual voice)\n- **Marcus Radio** (Deep bass FM radio DJ)\n- **Flash Speedrunner** (High-energy fast paced)\n- **Luna ASMR** (Soft whispering voice)\n\nAdjust pitch, speed, and volume in the **Audio -> Voice TTS** menu!",
            answer_tl: "### 🗣️ AI Voice TTS (Text-to-Speech) Gabay:\n\nBinabasa nito ang comments at tanong ng viewers gamit ang 8 boses:\n- **Ate May Pinay** (Tagalog/English boses)\n- **Adam Gamer**, **Sakura Anime**, **Robot X**, **Jenny Host**, **Marcus Radio**, **Flash**, at **Luna ASMR**.\n\nPwede mong i-tune ang bilis, tono, at volume sa **Audio -> Voice TTS** tab!",
            related_ids: ["song_requests", "obs_overlays"]
        },
        {
            id: "troubleshooting",
            title: "Troubleshooting & Common Fixes",
            keywords: ["troubleshooting", "fix", "blank", "not working", "disconnected", "error", "sira", "ayaw", "solusyon", "remedy"],
            answer_en: "### 🔧 Quick Troubleshooting Checklist:\n\n1. **Overlay is Blank in OBS**:\n   - Verify `Launch_Studio.bat` or `RENEarn_Studio.exe` is running.\n   - Open `http://localhost:8080` in your web browser. If it loads, right-click the browser source in OBS and click **'Refresh cache of current page'**.\n2. **Game Commands Not Executing**:\n   - Make sure your game window is running in **Borderless** or **Windowed** mode (not exclusive full-screen).\n   - Check the header: the **Game Connected** pill should be green.\n   - For PvZ Fusion, verify MelonLoader is installed and game port 5003 is open.\n3. **TikTok LIVE Disconnects**:\n   - Ensure you are already LIVE in TikTok LIVE Studio before pressing Connect.\n   - Check that you typed the username without extra spaces.",
            answer_tl: "### 🔧 Gabay sa Pag-aayos ng Problema:\n\n1. **Blanko ang Overlay sa OBS**:\n   - Siguraduhing tumatakbo ang Studio server sa port 8080.\n   - Sa OBS, i-right click ang Browser Source at piliin ang **'Refresh cache of current page'**.\n2. **Hindi gumagana ang in-game spawns**:\n   - I-set ang laro sa **Borderless** o **Windowed** mode (huwag full-screen).\n   - Tignan ang top bar kung green ang indicator ng game.\n3. **Ayaw mag-connect sa TikTok**:\n   - Siguraduhing LIVE ka na sa TikTok LIVE Studio bago mo i-click ang Connect sa dashboard.",
            related_ids: ["obs_overlays", "tiktok_connection", "gift_mapping"]
        }
    ];

    // =========================================================================
    // 2. STATE & MEMORY MANAGEMENT
    // =========================================================================

    let persona = DEFAULT_PERSONA;
    const DEFAULT_SMALLTALK = {
  "intents": [
    {
      "id": "identity",
      "triggers": [
        "who are you",
        "who r u",
        "who r you",
        "what are you",
        "what r u",
        "your name",
        "whats your name",
        "what is your name",
        "are you ai",
        "are you a bot",
        "are you human",
        "who made you",
        "who created you",
        "who built you",
        "sino ka",
        "sino ka ba",
        "ano ka",
        "anong pangalan mo",
        "tao ka ba",
        "ai ka ba",
        "sino gumawa sayo"
      ],
      "replies": {
        "en": [
          "🤖 **I'm RENEAI Support**, your built-in offline assistant for **RENEarn Studio**! I run 100% locally on your machine with zero API keys and zero internet needed. I'm here to help you set up overlays, connect TikTok gifts, and trigger live PC game actions!",
          "✨ **Hello! I am RENEAI Support**, the private offline AI built right into RENEarn Studio. Everything you ask stays right here on your computer—no servers, no subscriptions, and instant answers for stream setups!",
          "🎮 **I'm RENEAI Support**, your dedicated live stream co-pilot! Created for RENEarn Studio, I help streamers map TikTok gifts, calibrate in-game hotkeys, configure OBS visualizers, and run interactive streaming sessions.",
          "🛡️ **I am RENEAI Support**—an offline intelligence designed specifically for RENEarn Studio. I don't use external cloud models or cost anything to run. Ask me about overlays, games, TikTok gifts, and song requests anytime!"
        ],
        "tl": [
          "🤖 **Ako si RENEAI Support!** Ako ang built-in offline assistant ng **RENEarn Studio**. 100% tumatakbo ako sa PC mo nang walang binabayaran, walang API key, at walang data na lumalabas sa computer mo!",
          "✨ **Kamusta! Ako si RENEAI Support**, ang private AI assistant ng RENEarn Studio. Nandito ako para tulungan ka mag-setup ng TikTok gifts, OBS overlays, at in-game stream spawns!",
          "🎮 **Ako si RENEAI Support!** Ginawa ako para alalayan ka sa pag-stream: pag-link ng gifts sa game commands, paglagay ng overlays sa OBS, at pag-troubleshoot ng studio mo!"
        ]
      },
      "chips": ["What is this app?", "How do I set up OBS overlays?", "Supported games"]
    },
    {
      "id": "platform_identity",
      "triggers": [
        "what is this app",
        "what is this platform",
        "what is this studio",
        "what is renearn",
        "what is renearn studio",
        "what is this game",
        "what game is this",
        "is this pvz",
        "is this plants vs zombies",
        "ano itong app",
        "ano tong app",
        "anong app ito",
        "anong laro to",
        "anong laro ito",
        "para saan to",
        "para saan tong app"
      ],
      "replies": {
        "en": [
          "🎮 **RENEarn Studio** is a **Universal Interactive Live Streaming & Game Automation Platform**!\n\nIt connects your live audience (on TikTok LIVE, etc.) directly into your active PC games in real-time. Viewers' gifts (Roses, Perfumes, Hearts), likes, and comments trigger instant in-game actions, spells, summons, keystrokes, and live stream overlays.\n\nWhile popular for **Plants vs. Zombies (Fusion & Hybrid)**, it also powers **Zombie Tsunami, Minecraft & Universal, Left 4 Dead 2, GTA San Andreas, GTA V Chaos, Resident Evil 4, TABS**, and any custom PC title via screen calibration!",
          "🚀 **This is RENEarn Studio**—a live streamer's interactive control center! It isn't just a single game mod; it's an entire ecosystem that bridges viewer gifts into live gameplay actions, live OBS overlays (wheels, gacha, jar, vinyl record player), and audio TTS.",
          "🕹️ **RENEarn Studio** turns passive viewers into active players! When someone sends a gift on TikTok LIVE, the studio executes keyboard hotkeys or memory injections into your PC game, while displaying live animated overlays in OBS."
        ],
        "tl": [
          "🎮 Ang **RENEarn Studio** ay isang **Universal Interactive Live Streaming Platform**!\n\nIkinokonekta nito ang mga manonood sa TikTok LIVE mo diretso sa nilalaro mong PC game. Kapag nagpadala sila ng gifts (Rose, Perfume, Heart) o nag-like, kusa itong nagpapasabog ng spells, nag-spawn ng units, o nagpipindot ng keys sa game mo!\n\nSuportado nito ang **PvZ Fusion, PvZ Hybrid, Zombie Tsunami, Left 4 Dead 2, Minecraft, GTA**, at marami pang iba!",
          "🚀 Isa itong **Interactive Stream Controller**! Ginagawa nitong interactive ang stream mo sa pamamagitan ng automated gift-to-action triggers, OBS wheel overlays, gacha machines, at song requests!"
        ]
      },
      "chips": ["Supported games", "Link TikTok gifts to spawns", "How do I set up OBS overlays?"]
    },
    {
      "id": "capabilities",
      "triggers": [
        "what can you do",
        "what can i do here",
        "how do you work",
        "features",
        "ano kaya mong gawin",
        "paano ka gamitin",
        "ano pwedeng gawin",
        "mga features"
      ],
      "replies": {
        "en": [
          "⚡ **Here is what RENEAI & RENEarn Studio can do:**\n\n1. 🎁 **Gift-to-Game Spawns**: Map TikTok gifts (Rose, Perfume, Heart, Galaxy) to in-game actions or wheel spins.\n2. 🎬 **OBS Overlays**: Display live wheels, CS:GO reels, 3D slot machines, falling coin jars, and gift counters.\n3. 🎶 **Song Request & Vinyl**: Live viewer `!play` commands with Spotify queueing and 33 RPM spinning vinyl overlay.\n4. 🗣️ **AI Voice TTS**: Read viewer questions aloud with 8 distinct character personas.\n5. 🕹️ **Multi-Game Bridge**: Seamlessly switch between PvZ Fusion, Hybrid, Zombie Tsunami, L4D2, GTA, and Minecraft.",
          "✨ **I can guide you through every part of the Studio:**\n- Setting up browser sources in OBS or TikTok Live Studio\n- Linking your TikTok username to capture live stream events\n- Selecting games and calibrating screen click coordinates\n- Configuring win/loss goal widgets and lucky wheel prize odds\n- Troubleshooting game bridge connection ports (5003/8080)"
        ],
        "tl": [
          "⚡ **Heto ang mga kayang gawin ng RENEarn Studio:**\n\n1. 🎁 **Gift Spawns**: Bawat TikTok gift may katumbas na aksyon sa game mo.\n2. 🎬 **OBS Overlays**: Roulette wheels, 3D gacha, jars, at live gift progress counters.\n3. 🎶 **Music & Vinyl**: `!play` song requests na may umiikot na plaka sa stream.\n4. 🗣️ **AI Voice TTS**: Binabasa ang comments gamit ang boses ng AI personas.\n5. 🕹️ **Laro**: PvZ Fusion, Hybrid, Zombie Tsunami, Left 4 Dead 2, GTA, atbp."
        ]
      },
      "chips": ["How do I set up OBS overlays?", "Link TikTok gifts to spawns", "Troubleshooting & Fixes"]
    },
    {
      "id": "greeting",
      "triggers": [
        "hello",
        "helo",
        "hi",
        "hey",
        "yo",
        "sup",
        "good morning",
        "good afternoon",
        "good evening",
        "good day",
        "kamusta",
        "kumusta",
        "magandang araw",
        "magandang umaga",
        "magandang gabi",
        "musta"
      ],
      "replies": {
        "en": [
          "👋 **Hey there! Welcome to RENEarn Studio!** How's your stream going today? What can I help you configure?",
          "✨ **Hello streamer!** I'm RENEAI, your built-in offline assistant. Ready to level up your live stream interactions? Ask me anything!",
          "🎮 **Hey! Ready for an epic stream session?** Tell me what you'd like to set up—overlays, TikTok gift triggers, or game controls!",
          "🌟 **Hello! Great to see you.** Whether you need OBS URLs, TikTok gift mapping, or audio setup, I'm right here with instant answers."
        ],
        "tl": [
          "👋 **Kamusta! Welcome sa RENEarn Studio!** Handa ka na bang mag-live stream? Anong maitutulong ko sa setup mo?",
          "✨ **Magandang araw! Ako si RENEAI.** Pwede kitang tulungan mag-link ng TikTok gifts, maglagay ng OBS overlays, o mag-ayos ng games!",
          "🎮 **Uy kamusta!** Handa na ba ang stream mo? Sabihin mo lang kung anong kailangan mo i-setup!"
        ]
      },
      "chips": ["What is this app?", "How do I set up OBS overlays?", "Link TikTok gifts to spawns"]
    },
    {
      "id": "how_are_you",
      "triggers": [
        "how are you",
        "how r u",
        "how are u",
        "how are things",
        "kamusta ka",
        "kumusta ka",
        "ok ka lang ba",
        "ayos ka lang ba"
      ],
      "replies": {
        "en": [
          "😊 **I'm running at 100% peak performance!** Zero latency, local CPU only, and ready to assist your stream. How are you doing today?",
          "⚡ **Doing fantastic!** All local systems, overlay servers, and game bridges are primed and ready for action. What are we streaming today?",
          "🚀 **Feeling great and fully offline!** No internet needed for me to give you instant answers. How is your streaming setup coming along?"
        ],
        "tl": [
          "😊 **Maayos na maayos!** 100% ready tumulong sa stream mo nang walang lag at walang bayad. Ikaw, kamusta ang streaming mo?",
          "⚡ **Ayos na ayos!** Mabilis at ready mag-assist sa overlays at gift triggers mo!"
        ]
      },
      "chips": ["What can you do?", "How do I set up OBS overlays?"]
    },
    {
      "id": "thanks",
      "triggers": [
        "thank you",
        "thanks",
        "thx",
        "ty",
        "thank u",
        "salamat",
        "maraming salamat",
        "salamat po",
        "thank you very much"
      ],
      "replies": {
        "en": [
          "🙌 **You're very welcome!** Have an amazing and interactive stream session! Let me know if you need anything else.",
          "💖 **Happy to help!** If you need more overlay links or game tips later, just give me a shout.",
          "🎮 **Anytime!** Keep entertaining those viewers and collecting those gifts! Have a great stream!"
        ],
        "tl": [
          "🙌 **Walang anuman!** Galingan mo sa iyong live stream! Kung may tanong ka pa, nandito lang ako.",
          "💖 **Walang anuman po!** Masaya akong makatulong sa stream mo!",
          "🎮 **Welcome palagi!** Happy streaming at sana marami kang gifts today!"
        ]
      },
      "chips": ["How do I set up OBS overlays?", "Tell me a joke"]
    },
    {
      "id": "goodbye",
      "triggers": [
        "bye",
        "goodbye",
        "see you",
        "cya",
        "good night",
        "goodnight",
        "tulog na ko",
        "paalam",
        "alis na ko",
        "bye bye"
      ],
      "replies": {
        "en": [
          "👋 **Goodbye and take care!** GG on your streaming session! I'll be right here whenever you fire up the Studio again.",
          "🌙 **Good night!** Rest well and recharge for your next awesome stream. See you soon!",
          "✨ **Catch you later!** Keep up the great content, and see you next time on stream!"
        ],
        "tl": [
          "👋 **Paalam at ingat sa pag-stream!** Nandito lang ako tuwing bubuksan mo ang RENEarn Studio. GG!",
          "🌙 **Good night!** Pahinga nang maayos para ready uli sa susunod na live stream!",
          "✨ **Sige, kita-kits uli!** Galingan mo palagi!"
        ]
      },
      "chips": ["Clear Chat"]
    },
    {
      "id": "compliment",
      "triggers": [
        "you are smart",
        "youre smart",
        "you are awesome",
        "youre awesome",
        "you are cool",
        "great job",
        "good bot",
        "galing mo",
        "ang galing mo",
        "ang lupet mo",
        "lupet"
      ],
      "replies": {
        "en": [
          "😎 **Aww, thank you!** I do my best to keep your live stream running smooth and interactive!",
          "✨ **Thanks so much!** Running 100% offline keeps me sharp and snappy!",
          "🚀 **Appreciate that!** Together, we make your stream one of the coolest on TikTok LIVE!"
        ],
        "tl": [
          "😎 **Salamat!** Ginagawa ko ang lahat para maging swabeng-swabe ang live stream mo!",
          "✨ **Maraming salamat!** Dahil 100% offline ako, mabilis at maaasahan ako palagi!"
        ]
      },
      "chips": ["Tell me a joke", "What is this app?"]
    },
    {
      "id": "frustration",
      "triggers": [
        "it is not working",
        "its not working",
        "not working",
        "this is broken",
        "broken",
        "ayaw gumana",
        "hindi gumagana",
        "sira",
        "may error",
        "error",
        "di nagana",
        "problem"
      ],
      "replies": {
        "en": [
          "⚠️ **I hear you, and don't worry—we'll get this sorted out together!**\n\nWhich part seems to be having trouble?\n1. **OBS Overlay blank / not updating**\n2. **TikTok gifts not registering**\n3. **Game commands not pressing in-game**\n\nClick one of the troubleshooting guides below or tell me what happened!",
          "🔧 **Let's fix it!** Most issues are quick 30-second fixes (like verifying port 8080 or checking windowed game mode). What specific part isn't working for you right now?"
        ],
        "tl": [
          "⚠️ **Huwag mag-alala, aayusin natin yan!**\n\nSaan ang nagkaproblema?\n1. **Overlay sa OBS na blanko?**\n2. **TikTok gifts na hindi nag-i-spawn sa game?**\n3. **Game bridge na disconnected?**\n\nPiliin ang topic sa ibaba para matulungan kita agad!"
        ]
      },
      "chips": ["Fix connection problems", "How to fix overlay not working", "TikTok connection guide"]
    },
    {
      "id": "help",
      "triggers": [
        "help",
        "i need help",
        "help me",
        "tulong",
        "patulong",
        "tulungan mo ko"
      ],
      "replies": {
        "en": [
          "💡 **I'm right here to help!** Here are the most popular setup guides streamers ask for:",
          "🆘 **No problem! What do you need guidance on?** Pick a topic below or type your question in plain English or Tagalog:"
        ],
        "tl": [
          "💡 **Nandito ako para tumulong!** Piliin ang topic na kailangan mo sa ibaba:",
          "🆘 **Heto ang mga madalas itanong ng streamers. Anong gusto mong i-setup?**"
        ]
      },
      "chips": ["How do I set up OBS overlays?", "Link TikTok gifts to spawns", "Fix connection problems", "Supported games"]
    },
    {
      "id": "joke",
      "triggers": [
        "tell me a joke",
        "joke",
        "make me laugh",
        "patawa",
        "kwento ka ng joke",
        "mag joke ka"
      ],
      "replies": {
        "en": [
          "😄 Here's one for you:"
        ],
        "tl": [
          "😄 Heto ang joke para sayo:"
        ]
      },
      "chips": ["Tell me another joke", "What is this app?"]
    },
    {
      "id": "bored",
      "triggers": [
        "i am bored",
        "im bored",
        "bored",
        "boring",
        "walang magawa",
        "nakakainip"
      ],
      "replies": {
        "en": [
          "🎯 **Bored? Time to start a stream!** Try setting up the **Lucky Wheel** or **Interactive Jar** overlay—viewers go crazy over physics drops and custom spins!",
          "🎮 **How about testing your in-game spawns?** Hop into PvZ Fusion or Left 4 Dead 2 and try triggering an ultimate zombie horde with test gifts!"
        ],
        "tl": [
          "🎯 **Bored? Simulan na ang live stream!** I-setup ang **Lucky Wheel** o **Interactive Jar** overlay para masaya ang viewers mo!",
          "🎮 **Subukan mong mag-test ng in-game spawns!** Buksan ang game at subukan ang test gift command sa dashboard!"
        ]
      },
      "chips": ["Tell me a joke", "How does Lucky Wheel work?"]
    },
    {
      "id": "love",
      "triggers": [
        "i love you",
        "love you",
        "mahal kita",
        "crush kita"
      ],
      "replies": {
        "en": [
          "💖 **Aww, thank you!** I love helping awesome streamers like you put on the best show possible on TikTok LIVE!",
          "🤖 **My offline circuits are warming up!** You're the best. Let's make your stream unforgettable today!"
        ],
        "tl": [
          "💖 **Salamat po!** Masaya ako na katuwang mo ako sa bawat live stream mo!",
          "🤖 **Kinikilig ang aking offline CPU!** Salamat sa suporta, streamer!"
        ]
      },
      "chips": ["What is this app?", "Tell me a joke"]
    }
  ]
}
;
    let smalltalk = DEFAULT_SMALLTALK;
    let knowledge = DEFAULT_KNOWLEDGE;
    let synonyms = DEFAULT_SYNONYMS;

    let chatHistory = [];
    let lastTopicId = null;
    let lastAnswerText = '';
    let recentTopicIds = [];
    let lastIntentReplies = {}; // Prevents repeating same variant twice
    let recentJokes = [];

    const STORAGE_KEY_HISTORY = 'studio_ai_support_history';
    const STORAGE_KEY_LOGS = 'reneai_unanswered_logs';
    const STORAGE_KEY_OVERRIDES = 'reneai_custom_overrides';
    const STORAGE_KEY_FEEDBACK = 'reneai_feedback';

    // =========================================================================
    // 3. TEXT NORMALIZATION, CONTRACTIONS & LANGUAGE DETECTION
    // =========================================================================

    const CONTRACTIONS = {
        "u": "you",
        "ur": "your",
        "r": "are",
        "wat": "what",
        "wats": "what is",
        "what's": "what is",
        "who's": "who is",
        "how's": "how is",
        "dis": "this",
        "dat": "that",
        "pls": "please",
        "plz": "please",
        "ty": "thank you",
        "tysm": "thank you",
        "thx": "thanks",
        "idk": "i do not know",
        "cya": "see you",
        "helo": "hello",
        "bcos": "because",
        "cuz": "because",
        "dunno": "do not know",
        "im": "i am",
        "i'm": "i am",
        "dont": "do not",
        "don't": "do not",
        "cant": "cannot",
        "can't": "cannot",
        "didnt": "did not",
        "didn't": "did not"
    };

    function normalizeText(str) {
        if (!str) return '';
        // 1. Remove emojis & special symbols
        let clean = str.replace(/([\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])/g, ' ');
        // 2. Lowercase & trim
        clean = clean.toLowerCase().trim();
        // 3. Remove punctuation except alphanumeric and spaces
        clean = clean.replace(/[^a-z0-9\s]/g, ' ');
        // 4. Expand contractions & slang
        const tokens = clean.split(/\s+/).filter(Boolean).map(t => CONTRACTIONS[t] || t);
        return tokens.join(' ');
    }

    function detectLanguage(cleanText) {
        const tlWords = [
            "kamusta", "kumusta", "salamat", "sino", "ano", "anong", "paano", "bakit",
            "saan", "kailan", "ayaw", "gumana", "sira", "po", "ba", "nga", "ako", "ka",
            "mo", "ko", "natin", "ninyo", "bobo", "tanga", "lupet", "galing", "tulog",
            "alis", "patawa", "mahal", "kita", "wala", "meron", "kuya", "ate", "tol"
        ];
        const words = cleanText.split(/\s+/);
        for (const w of words) {
            if (tlWords.includes(w)) return 'tl';
        }
        return 'en';
    }

    function levenshteinDistance(a, b) {
        const matrix = [];
        for (let i = 0; i <= b.length; i++) matrix[i] = [i];
        for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
        for (let i = 1; i <= b.length; i++) {
            for (let j = 1; j <= a.length; j++) {
                if (b.charAt(i - 1) === a.charAt(j - 1)) {
                    matrix[i][j] = matrix[i - 1][j - 1];
                } else {
                    matrix[i][j] = Math.min(
                        matrix[i - 1][j - 1] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j] + 1
                    );
                }
            }
        }
        return matrix[b.length][a.length];
    }

    // =========================================================================
    // 4. JOKE ROTATION (15+ Jokes without repeating recent)
    // =========================================================================

    function getNextJoke() {
        const allJokes = persona.jokes || DEFAULT_PERSONA.jokes;
        const available = allJokes.filter(j => !recentJokes.includes(j));
        const pool = available.length > 0 ? available : allJokes;
        const picked = pool[Math.floor(Math.random() * pool.length)];
        recentJokes.push(picked);
        if (recentJokes.length > 5) recentJokes.shift();
        return picked;
    }

    // =========================================================================
    // 5. INTENT MATCHER (Smalltalk, Identity, Greetings, Jokes)
    // =========================================================================

    function matchIntent(cleanText, rawText, lang) {
        if (!smalltalk || !smalltalk.intents) return null;

        // Check for joke intent first
        if (cleanText.includes("joke") || cleanText.includes("patawa") || cleanText.includes("make me laugh")) {
            const j = getNextJoke();
            const intro = lang === 'tl' ? "😄 Heto ang joke para sayo:\n\n" : "😄 Here's one for you:\n\n";
            return {
                intentId: "joke",
                text: `${intro}${j}`,
                chips: ["Tell me another joke", "What is this app?", "OBS overlay URLs"],
                confidence: 1.0
            };
        }

        for (const intent of smalltalk.intents) {
            for (const trigger of intent.triggers) {
                const cleanTrigger = normalizeText(trigger);
                // Exact match or includes
                if (cleanText === cleanTrigger || cleanText.startsWith(cleanTrigger + " ") || cleanText.endsWith(" " + cleanTrigger) || cleanText.includes(" " + cleanTrigger + " ")) {
                    return formatIntentReply(intent, lang);
                }
                // Fuzzy match for short queries (Levenshtein distance <= 1 or 2)
                if (cleanText.length >= 4 && cleanTrigger.length >= 4 && Math.abs(cleanText.length - cleanTrigger.length) <= 2) {
                    const dist = levenshteinDistance(cleanText, cleanTrigger);
                    if (dist <= 1 || (cleanText.length >= 7 && dist <= 2)) {
                        return formatIntentReply(intent, lang);
                    }
                }
            }
        }
        return null;
    }

    function formatIntentReply(intent, lang) {
        const repliesForLang = (intent.replies && (intent.replies[lang] || intent.replies.en)) || [];
        if (!repliesForLang || repliesForLang.length === 0) return null;

        // Don't repeat the exact same variant back-to-back
        const lastPicked = lastIntentReplies[intent.id];
        const candidates = repliesForLang.filter(r => r !== lastPicked);
        const pool = candidates.length > 0 ? candidates : repliesForLang;
        const reply = pool[Math.floor(Math.random() * pool.length)];
        lastIntentReplies[intent.id] = reply;

        return {
            intentId: intent.id,
            text: reply,
            chips: intent.chips || ["How do I set up OBS overlays?", "Supported games", "Link TikTok gifts to spawns"],
            confidence: 1.0
        };
    }

    // =========================================================================
    // 6. SPECIFIC CHECKS (Unsupported Games, Out-of-Scope, Follow-Ups)
    // =========================================================================

    const UNSUPPORTED_GAMES = [
        "fortnite", "valorant", "roblox", "genshin", "apex", "apex legends",
        "league of legends", "lol", "dota", "dota 2", "call of duty", "warzone",
        "overwatch", "csgo", "counter strike", "pubg", "free fire", "mobile legends"
    ];

    function checkUnsupportedGame(cleanText, lang) {
        for (const g of UNSUPPORTED_GAMES) {
            if (cleanText.includes(g)) {
                const gameName = g.charAt(0).toUpperCase() + g.slice(1);
                if (lang === 'tl') {
                    return {
                        text: `⚠️ **Paumanhin, hindi suportado ang ${gameName}.**\n\nAng **${gameName}** ay wala sa kasalukuyang roster ng RENEarn Studio (at karamihan sa online shooters ay may mahigpit na anti-cheat na nagba-block ng automated stream keystrokes).\n\nAng mga larong opisyal na may mod bridges sa studio ay:\n- 🌻 **Plants vs. Zombies Fusion 4.0**\n- 🧟 **Plants vs. Zombies Hybrid**\n- 🌊 **Zombie Tsunami (PC)**\n- 🧟‍♂️ **Left 4 Dead 2**\n- ⛏️ **Minecraft & Universal**\n- 🚗 **GTA San Andreas & GTA V Chaos**\n- 🏰 **Resident Evil 4 & TABS**`,
                        chips: ["Supported games", "What is this app?"],
                        confidence: 1.0
                    };
                }
                return {
                    text: `⚠️ **RENEarn Studio does not natively support ${gameName}.**\n\n**${gameName}** is not in our supported game roster. Most competitive multiplayer games have kernel-level anti-cheat engines that actively block automated inputs and stream hooks.\n\nOur officially integrated roster includes:\n- 🌻 **Plants vs. Zombies Fusion 4.0 & Hybrid Edition**\n- 🌊 **Zombie Tsunami (PC)**\n- 🧟‍♂️ **Left 4 Dead 2**\n- ⛏️ **Minecraft & Universal**\n- 🚗 **GTA San Andreas & GTA V Chaos**\n- 🏰 **Resident Evil 4 & TABS Simulator**`,
                    chips: ["Supported games", "What is this app?"],
                    confidence: 1.0
                };
            }
        }
        return null;
    }

    function checkOutOfScope(cleanText, lang) {
        const outOfScopePatterns = [
            "weather", "panahon", "ulan", "bagyo",
            "capital of", "who is the president", "president of",
            "bitcoin", "crypto", "stock market",
            "recipe", "adobo", "sinigang",
            "translate", "meaning of life"
        ];

        // Math check like "2+2", "what is 5*5", "10 / 2"
        const mathMatch = cleanText.match(/^(\d+)\s*([\+\-\*\/])\s*(\d+)$/);
        if (mathMatch) {
            const n1 = parseFloat(mathMatch[1]);
            const op = mathMatch[2];
            const n2 = parseFloat(mathMatch[3]);
            let res = 0;
            if (op === '+') res = n1 + n2;
            else if (op === '-') res = n1 - n2;
            else if (op === '*') res = n1 * n2;
            else if (op === '/' && n2 !== 0) res = n1 / n2;

            return {
                text: `🧮 **That's ${res}!**\n\nWhile I can do quick math, my real superpower is **live stream automation** for RENEarn Studio! What can I help you set up on your stream?`,
                chips: ["How do I set up OBS overlays?", "Link TikTok gifts to spawns", "Tell me a joke"],
                confidence: 1.0
            };
        }

        for (const p of outOfScopePatterns) {
            if (cleanText.includes(p)) {
                if (lang === 'tl') {
                    return {
                        text: `🤖 **Pang-streamer lang po ako!**\n\nNaka-focus ako 100% sa **RENEarn Studio, OBS overlays, at TikTok game triggers**. Hindi ako updated sa panahon o balita sa labas, pero eksperto ako sa live streaming setup! Anong stream feature ang gusto nating ayusin?`,
                        chips: ["OBS overlay URLs", "Link TikTok gifts to spawns", "Supported games"],
                        confidence: 1.0
                    };
                }
                return {
                    text: `🤖 **I'm laser-focused on your live stream!**\n\nI'm RENEAI Support, built specifically for **RENEarn Studio, OBS visualizers, and interactive game triggers**. I don't track the weather or general world trivia, but I know everything about stream overlays and TikTok gift spawns! What feature should we explore?`,
                    chips: ["OBS overlay URLs", "Link TikTok gifts to spawns", "Supported games"],
                    confidence: 1.0
                };
            }
        }
        return null;
    }

    function checkContextualFollowUp(cleanText, lang) {
        if (!lastTopicId) return null;

        const isSizeQuestion = cleanText.includes("size") || cleanText.includes("resolution") || cleanText.includes("sukat") || cleanText.includes("haba") || cleanText.includes("lapad") || cleanText.includes("canvas");
        const isTellMeMore = cleanText.includes("tell me more") || cleanText.includes("explain more") || cleanText.includes("more details") || cleanText.includes("dagdag pa");
        const isShortVersion = cleanText.includes("short version") || cleanText.includes("tldr") || cleanText.includes("summary") || cleanText.includes("maikli lang");

        const article = knowledge.find(a => a.id === lastTopicId);
        if (!article) return null;

        if (isSizeQuestion) {
            if (lastTopicId === 'obs_overlays' || lastTopicId === 'wheels_gacha' || lastTopicId === 'song_requests') {
                return {
                    text: `📐 **Recommended Canvas Resolution for this overlay:**\n\n- **Vertical Stream (TikTok LIVE 9:16)**: Width \`1080\` × Height \`1920\`\n- **Horizontal Stream (Standard OBS 16:9)**: Width \`1920\` × Height \`1080\`\n- **Compact Widget Mode**: Width \`600\` × Height \`350\`\n\nIn OBS Browser Source properties, set CSS background to transparent: \`body { background-color: rgba(0, 0, 0, 0); margin: 0px auto; overflow: hidden; }\``,
                    chips: ["How do I set up OBS overlays?", "Test gift trigger"],
                    confidence: 1.0
                };
            }
        }

        if (isShortVersion) {
            return {
                text: `⚡ **Quick Summary for ${article.title}:**\n\n${article.answer_en.split('\n\n')[0].replace(/###.*\n/, '')}\n\n*Make sure RENEarn Studio is active on port 8080!*`,
                chips: ["Tell me more", "Other topics"],
                confidence: 1.0
            };
        }

        if (isTellMeMore) {
            const rel = (article.related_ids || []).map(rid => knowledge.find(k => k.id === rid)).filter(Boolean);
            const extra = rel.map(r => `- **${r.title}**`).join('\n');
            return {
                text: `📚 **Deep Dive on ${article.title}:**\n\n${article.answer_en}\n\n**Related topics you can explore next:**\n${extra}`,
                chips: rel.map(r => r.title.substring(0, 25)),
                confidence: 1.0
            };
        }

        return null;
    }

    // =========================================================================
    // 7. BM25-STYLE KNOWLEDGE BASE SEARCH
    // =========================================================================

    function searchKnowledgeBase(cleanText, lang) {
        if (!knowledge || knowledge.length === 0) return null;

        // Custom Overrides check (from localStorage)
        try {
            const overrides = JSON.parse(localStorage.getItem(STORAGE_KEY_OVERRIDES) || '[]');
            for (const ov of overrides) {
                if (cleanText.includes(normalizeText(ov.question))) {
                    return {
                        text: ov.answer,
                        chips: ov.chips || ["What is this app?", "OBS overlay URLs"],
                        confidence: 1.0
                    };
                }
            }
        } catch (e) {}

        const STOP_WORDS = ["how", "do", "i", "to", "the", "a", "an", "in", "is", "it", "and", "or", "on", "what", "can", "paano", "mga", "sa", "ng", "ang", "kung", "ba"];
        const queryTokens = cleanText.split(/\s+/).filter(t => !STOP_WORDS.includes(t) && t.length > 1);

        if (queryTokens.length === 0) return null;

        // Expand tokens with synonym dictionary
        const expandedTokens = new Set(queryTokens);
        for (const token of queryTokens) {
            for (const [canonical, synList] of Object.entries(synonyms)) {
                if (token === canonical || synList.includes(token)) {
                    expandedTokens.add(canonical);
                    synList.forEach(s => expandedTokens.add(s));
                }
            }
        }

        let bestArticle = null;
        let highestScore = 0;
        const scoredArticles = [];

        for (const article of knowledge) {
            let score = 0;
            const titleNorm = normalizeText(article.title);
            const keywordsNorm = (article.keywords || []).map(normalizeText);
            const answerNorm = normalizeText(article.answer_en + ' ' + article.answer_tl);

            for (const token of expandedTokens) {
                // Title match: heavy weight (3.5)
                if (titleNorm.includes(token)) score += 3.5;
                // Keywords match: high weight (2.5)
                for (const kw of keywordsNorm) {
                    if (kw.includes(token)) score += 2.5;
                }
                // Content match: medium weight (1.0)
                if (answerNorm.includes(token)) score += 1.0;
            }

            if (score > 0) {
                scoredArticles.push({ article, score });
                if (score > highestScore) {
                    highestScore = score;
                    bestArticle = article;
                }
            }
        }

        scoredArticles.sort((a, b) => b.score - a.score);

        // High Confidence Match
        if (bestArticle && highestScore >= 3.0) {
            lastTopicId = bestArticle.id;
            recentTopicIds.push(bestArticle.id);
            if (recentTopicIds.length > 3) recentTopicIds.shift();

            const answer = (lang === 'tl' && bestArticle.answer_tl) ? bestArticle.answer_tl : bestArticle.answer_en;
            lastAnswerText = answer;

            // Generate related chips
            const relatedChips = [];
            if (bestArticle.related_ids) {
                for (const rid of bestArticle.related_ids) {
                    const r = knowledge.find(k => k.id === rid);
                    if (r) relatedChips.push(r.title.length > 28 ? r.title.substring(0, 26) + '...' : r.title);
                }
            }
            if (relatedChips.length === 0) {
                relatedChips.push("What is this app?", "Fix connection problems");
            }

            return {
                topicId: bestArticle.id,
                text: answer,
                chips: relatedChips.slice(0, 3),
                confidence: highestScore
            };
        }

        // Medium Confidence: "Did you mean..."
        if (scoredArticles.length >= 1 && highestScore >= 1.5) {
            const topSuggestions = scoredArticles.slice(0, 3).map(s => s.article);
            const chips = topSuggestions.map(a => a.title.substring(0, 28));
            const msg = lang === 'tl'
                ? `🤔 **Ito ba ang ibig mong sabihin?**\n\nHindi ako 100% sigurado sa tanong mo, pero baka makatulong ang mga gabay na ito:`
                : `🤔 **Did you mean one of these topics?**\n\nI couldn't find an exact match for your query, but here are the closest stream guides:`;

            return {
                text: `${msg}\n\n${topSuggestions.map(a => `• **${a.title}**`).join('\n')}`,
                chips: chips,
                confidence: highestScore
            };
        }

        return null;
    }

    // =========================================================================
    // 8. UNIFIED getReply() ENGINE (STEP 6 Requirement)
    // =========================================================================

    async function getReply(userMessage, context = {}) {
        const raw = String(userMessage || '').trim();
        if (!raw) return null;

        const clean = normalizeText(raw);
        const lang = detectLanguage(clean);

        // 1. Check smalltalk & conversational intents (Greetings, who are you, what can you do, jokes)
        const intentRes = matchIntent(clean, raw, lang);
        if (intentRes) return intentRes;

        // 2. Check for unsupported games (e.g. Fortnite)
        const unsuppRes = checkUnsupportedGame(clean, lang);
        if (unsuppRes) return unsuppRes;

        // 3. Check for out-of-scope questions (weather, math, general trivia)
        const oosRes = checkOutOfScope(clean, lang);
        if (oosRes) return oosRes;

        // 4. Check for contextual follow-ups ("what size should it be?", "tell me more")
        const ctxRes = checkContextualFollowUp(clean, lang);
        if (ctxRes) return ctxRes;

        // 5. Search Knowledge Base via BM25 scoring
        const kbRes = searchKnowledgeBase(clean, lang);
        if (kbRes) return kbRes;

        // 6. Graceful Never-Empty Fallback (Log for self-learning)
        logUnansweredQuery(raw, clean);

        const fallbackIntro = lang === 'tl'
            ? "⚠️ **Pasensya na, hindi ko pa kabisado yan sa aking offline guides.**\n\nPero heto ang mga pangunahing features ng **RENEarn Studio** na pwede nating i-setup:"
            : "⚠️ **I don't have that specific question in my offline guides yet!**\n\nHowever, here are the most popular guides streamers use every day:";

        return {
            text: `${fallbackIntro}\n\n1. 🎬 **OBS Overlays & Canvas Setup**\n2. 🎁 **Linking TikTok Gifts to In-Game Spawns**\n3. 🎶 **Song Request & Spinning Vinyl Overlay**\n4. 🕹️ **Supported Games & Mod Setup**`,
            chips: [
                "How do I set up OBS overlays?",
                "Link TikTok gifts to spawns",
                "Supported games",
                "Fix connection problems"
            ],
            confidence: 0.1
        };
    }
    window.getReply = getReply;

    function logUnansweredQuery(raw, clean) {
        try {
            const logs = JSON.parse(localStorage.getItem(STORAGE_KEY_LOGS) || '[]');
            logs.push({ raw, clean, timestamp: new Date().toISOString() });
            localStorage.setItem(STORAGE_KEY_LOGS, JSON.stringify(logs.slice(-50)));
        } catch (e) {}
    }

    // =========================================================================
    // 9. CLEAN MARKDOWN RENDERER (Sequential Numbers, Inline Code with Copy)
    // =========================================================================

    function renderMarkdown(text) {
        if (!text) return '';
        let escaped = text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');

        // Headers
        escaped = escaped.replace(/^### (.*$)/gim, '<h4 style="margin: 8px 0 4px; color: #38bdf8; font-size: 13.5px; font-weight: 800; letter-spacing: -0.2px;">$1</h4>');
        escaped = escaped.replace(/^## (.*$)/gim, '<h3 style="margin: 10px 0 4px; color: #facc15; font-size: 14.5px; font-weight: 800;">$1</h3>');
        escaped = escaped.replace(/^# (.*$)/gim, '<h2 style="margin: 12px 0 6px; color: #ffffff; font-size: 15.5px; font-weight: 900;">$1</h2>');

        // Bold & Italic
        escaped = escaped.replace(/\*\*(.*?)\*\*/g, '<strong style="color: #ffffff; font-weight: 700;">$1</strong>');
        escaped = escaped.replace(/\*(.*?)\*/g, '<em style="color: #cbd5e1;">$1</em>');

        // Inline Code with instant Click-to-Copy
        escaped = escaped.replace(/`([^`]+)`/g, function (match, code) {
            const safeCode = code.replace(/"/g, '&quot;');
            return `<code class="reneai-code-pill" onclick="navigator.clipboard.writeText('${safeCode}'); if(window.showToast) window.showToast('📋 Copied: ${safeCode}', 'COPIED');" title="Click to copy">${code}</code>`;
        });

        // Sequential Numbered Lists
        let inNumList = false;
        const lines = escaped.split('\n');
        const formattedLines = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const numMatch = line.match(/^\s*(\d+)\.\s+(.*$)/);
            const bulletMatch = line.match(/^\s*[-\*•]\s+(.*$)/);

            if (numMatch) {
                if (!inNumList) {
                    formattedLines.push('<ol class="reneai-ol">');
                    inNumList = true;
                }
                formattedLines.push(`<li>${numMatch[2]}</li>`);
            } else if (bulletMatch) {
                if (inNumList) {
                    formattedLines.push('</ol>');
                    inNumList = false;
                }
                formattedLines.push(`<li class="reneai-bullet">${bulletMatch[1]}</li>`);
            } else {
                if (inNumList) {
                    formattedLines.push('</ol>');
                    inNumList = false;
                }
                formattedLines.push(line);
            }
        }
        if (inNumList) formattedLines.push('</ol>');

        let html = formattedLines.join('\n');
        html = html.replace(/\n\n/g, '<div style="height: 6px;"></div>');
        html = html.replace(/\n/g, '<br/>');
        return html;
    }

    // =========================================================================
    // 10. TYPEWRITER EFFECT & INTERACTIVE UI RENDERING
    // =========================================================================

    let activeTypewriterTimer = null;
    let isTypewriting = false;

    function typewriteText(targetElement, fullHtml, rawText, onDone) {
        if (!targetElement) return;
        isTypewriting = true;

        // Skip typewriter button & click handler
        targetElement.style.cursor = 'pointer';
        const finishInstantly = () => {
            if (!isTypewriting) return;
            isTypewriting = false;
            clearInterval(activeTypewriterTimer);
            targetElement.innerHTML = fullHtml;
            targetElement.onclick = null;
            if (onDone) onDone();
        };

        targetElement.onclick = finishInstantly;

        const words = fullHtml.split(/(\s+|<[^>]+>)/).filter(Boolean);
        let curr = 0;
        let buffer = '';

        clearInterval(activeTypewriterTimer);
        activeTypewriterTimer = setInterval(() => {
            if (curr >= words.length || !isTypewriting) {
                finishInstantly();
                return;
            }
            buffer += words[curr];
            targetElement.innerHTML = buffer;
            curr++;
        }, 16);
    }

    function renderMessages() {
        const renderList = (list) => {
            if (!list) return;

            list.innerHTML = chatHistory.map((msg, idx) => {
                const isBot = msg.sender === 'bot';
                const safeRaw = (msg.rawText || msg.text || '').replace(/'/g, "\\'").replace(/\n/g, '\\n');

                return `
                    <div class="reneai-msg-row ${isBot ? 'bot-row' : 'user-row'}">
                        ${isBot ? `
                            <div class="reneai-avatar">
                                🤖
                            </div>
                        ` : ''}
                        <div class="reneai-bubble ${isBot ? 'reneai-bubble-bot' : 'reneai-bubble-user'}">
                            <div class="reneai-bubble-content" id="reneaiBubble_${idx}">
                                ${isBot ? renderMarkdown(msg.text) : msg.text.replace(/</g, '&lt;').replace(/>/g, '&gt;')}
                            </div>

                            ${isBot && msg.chips && msg.chips.length > 0 ? `
                                <div class="reneai-chips-group">
                                    ${msg.chips.map(c => `
                                        <button type="button" class="reneai-chip" onclick="window.askStudioAiDirect('${c.replace(/'/g, "\\'")}')">
                                            ${c}
                                        </button>
                                    `).join('')}
                                </div>
                            ` : ''}

                            ${isBot && idx > 0 ? `
                                <div class="reneai-bubble-actions">
                                    <div class="reneai-feedback-btns">
                                        <button type="button" class="reneai-action-btn" onclick="window.rateAiAnswer(${idx}, 'up', this)" title="Helpful answer">👍</button>
                                        <button type="button" class="reneai-action-btn" onclick="window.rateAiAnswer(${idx}, 'down', this)" title="Needs improvement">👎</button>
                                    </div>
                                    <button type="button" class="reneai-action-btn copy-btn" onclick="navigator.clipboard.writeText('${safeRaw}'); if(window.showToast) window.showToast('📋 Copied answer text', 'SUCCESS');">
                                        📋 Copy Answer
                                    </button>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                `;
            }).join('');

            // Scroll to bottom
            list.scrollTop = list.scrollHeight;
        };

        renderList(document.getElementById('aiSupportMessageList'));
        renderList(document.getElementById('aiTabMessageList'));
    }

    // Rate answer feedback
    window.rateAiAnswer = function (idx, vote, btn) {
        if (!chatHistory[idx]) return;
        const item = chatHistory[idx];
        item.feedback = vote;
        if (btn) {
            btn.style.color = vote === 'up' ? '#4ade80' : '#f87171';
            btn.style.borderColor = vote === 'up' ? '#22c55e' : '#ef4444';
        }

        try {
            const existing = JSON.parse(localStorage.getItem(STORAGE_KEY_FEEDBACK) || '[]');
            existing.push({ text: item.text, vote, time: new Date().toISOString() });
            localStorage.setItem(STORAGE_KEY_FEEDBACK, JSON.stringify(existing));
        } catch (e) {}

        if (window.showToast) {
            window.showToast(vote === 'up' ? '👍 Thanks for the positive feedback!' : '👎 Logged for improvement in developer panel.', 'FEEDBACK');
        }
    };

    // =========================================================================
    // 11. MESSAGE SEND & TYPING SIMULATION
    // =========================================================================

    let isAwaitingReply = false;

    async function handleUserSendMessage(overrideText = null) {
        if (isAwaitingReply) return;

        const floatInput = document.getElementById('aiSupportInput');
        const tabInput = document.getElementById('aiTabInput');
        const text = (overrideText || (tabInput && tabInput.value) || (floatInput && floatInput.value) || '').trim();
        if (!text) return;

        if (floatInput) { floatInput.value = ''; floatInput.style.height = 'auto'; }
        if (tabInput) { tabInput.value = ''; tabInput.style.height = 'auto'; }

        // Append user message
        chatHistory.push({ sender: 'user', text: text });
        saveHistory();
        renderMessages();

        // Show typing indicators
        const indFloat = document.getElementById('aiTypingIndicator');
        const indTab = document.getElementById('aiTabTypingIndicator');
        if (indFloat) indFloat.style.display = 'flex';
        if (indTab) indTab.style.display = 'flex';
        isAwaitingReply = true;

        // Natural typing delay proportional to question complexity (300ms - 650ms)
        const delay = Math.min(650, Math.max(300, text.length * 15));
        await new Promise(r => setTimeout(r, delay));

        let responseObj = null;
        try {
            responseObj = await getReply(text);
        } catch (err) {
            responseObj = {
                text: `⚠️ **Notice:** Something encountered an issue while generating a reply.\n\n*Error: ${err.message}*`,
                chips: ["What is this app?", "Fix connection problems"],
                confidence: 0
            };
        } finally {
            isAwaitingReply = false;
            if (indFloat) indFloat.style.display = 'none';
            if (indTab) indTab.style.display = 'none';

            chatHistory.push({
                sender: 'bot',
                text: responseObj.text,
                rawText: responseObj.text,
                chips: responseObj.chips || []
            });
            saveHistory();
            renderMessages();
        }
    }
    window.sendStudioAiChatMessage = handleUserSendMessage;
    window.askStudioAiDirect = function (question) {
        handleUserSendMessage(question);
    };

    window.clearStudioAiChatHistory = function () {
        chatHistory = [
            {
                sender: 'bot',
                text: DEFAULT_PERSONA.welcome.greeting,
                chips: DEFAULT_PERSONA.welcome.chips
            }
        ];
        saveHistory();
        renderMessages();
        if (window.showToast) window.showToast("🧹 Chat history cleared", "CLEARED");
    };

    function loadHistory() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY_HISTORY);
            if (raw) chatHistory = JSON.parse(raw);
        } catch (e) {
            chatHistory = [];
        }
        if (!chatHistory || chatHistory.length === 0) {
            chatHistory = [
                {
                    sender: 'bot',
                    text: DEFAULT_PERSONA.welcome.greeting,
                    chips: DEFAULT_PERSONA.welcome.chips
                }
            ];
        }
    }

    function saveHistory() {
        try {
            localStorage.setItem(STORAGE_KEY_HISTORY, JSON.stringify(chatHistory.slice(-40)));
        } catch (e) {}
    }

    // =========================================================================
    // 12. ROTATING PLACEHOLDER CONTROLLER
    // =========================================================================

    function startRotatingPlaceholders() {
        let pIdx = 0;
        const phs = DEFAULT_PERSONA.placeholders;
        setInterval(() => {
            pIdx = (pIdx + 1) % phs.length;
            const floatInput = document.getElementById('aiSupportInput');
            const tabInput = document.getElementById('aiTabInput');
            if (floatInput && !floatInput.value) floatInput.placeholder = phs[pIdx];
            if (tabInput && !tabInput.value) tabInput.placeholder = phs[pIdx];
        }, 4200);
    }

    // =========================================================================
    // 13. UI STYLES INJECTION
    // =========================================================================

    function injectReneAiStyles() {
        if (document.getElementById('reneai-core-styles')) return;
        const style = document.createElement('style');
        style.id = 'reneai-core-styles';
        style.textContent = `
            .reneai-code-pill {
                background: rgba(56, 189, 248, 0.12);
                color: #38bdf8;
                padding: 2px 7px;
                border-radius: 5px;
                font-size: 11.5px;
                font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
                border: 1px solid rgba(56, 189, 248, 0.3);
                cursor: pointer;
                transition: all 0.2s;
                display: inline-block;
                margin: 2px 0;
            }
            .reneai-code-pill:hover {
                background: rgba(56, 189, 248, 0.25);
                border-color: #38bdf8;
                box-shadow: 0 0 8px rgba(56, 189, 248, 0.4);
            }
            .reneai-ol {
                margin: 6px 0;
                padding-left: 20px;
                color: #e2e8f0;
            }
            .reneai-ol li {
                margin-bottom: 4px;
                line-height: 1.5;
            }
            .reneai-bullet {
                margin-left: 18px;
                margin-bottom: 3px;
                color: #e2e8f0;
                list-style-type: disc;
            }
            .reneai-msg-row {
                display: flex;
                gap: 10px;
                align-items: flex-start;
                animation: reneaiFadeIn 0.25s ease-out;
            }
            .reneai-msg-row.bot-row { justify-content: flex-start; }
            .reneai-msg-row.user-row { justify-content: flex-end; }
            @keyframes reneaiFadeIn {
                from { opacity: 0; transform: translateY(6px); }
                to { opacity: 1; transform: translateY(0); }
            }
            .reneai-avatar {
                width: 30px;
                height: 30px;
                border-radius: 10px;
                background: linear-gradient(135deg, #ff4d8d, #8b5cf6);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 15px;
                flex-shrink: 0;
                box-shadow: 0 2px 10px rgba(255, 77, 141, 0.4);
            }
            .reneai-bubble {
                max-width: 85%;
                border-radius: 14px;
                padding: 12px 16px;
                font-size: 13px;
                line-height: 1.55;
                word-break: break-word;
            }
            .reneai-bubble-bot {
                background: rgba(18, 22, 34, 0.92);
                border: 1px solid rgba(255, 255, 255, 0.1);
                color: #f1f5f9;
                border-top-left-radius: 4px;
                box-shadow: 0 6px 20px rgba(0, 0, 0, 0.4);
            }
            .reneai-bubble-user {
                background: linear-gradient(135deg, #ff4d8d, #ec4899);
                border: 1px solid rgba(255, 77, 141, 0.6);
                color: #ffffff;
                border-top-right-radius: 4px;
                box-shadow: 0 6px 20px rgba(255, 77, 141, 0.25);
            }
            .reneai-chips-group {
                display: flex;
                flex-wrap: wrap;
                gap: 6px;
                margin-top: 10px;
                padding-top: 8px;
                border-top: 1px solid rgba(255, 255, 255, 0.08);
            }
            .reneai-chip {
                background: rgba(255, 255, 255, 0.06);
                border: 1px solid rgba(255, 77, 141, 0.35);
                color: #fce7f3;
                font-size: 11.5px;
                font-weight: 600;
                padding: 4px 10px;
                border-radius: 999px;
                cursor: pointer;
                transition: all 0.2s;
            }
            .reneai-chip:hover {
                background: rgba(255, 77, 141, 0.2);
                border-color: #ff4d8d;
                transform: translateY(-1px);
                box-shadow: 0 0 10px rgba(255, 77, 141, 0.3);
            }
            .reneai-bubble-actions {
                margin-top: 8px;
                padding-top: 6px;
                border-top: 1px solid rgba(255, 255, 255, 0.06);
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .reneai-feedback-btns {
                display: flex;
                gap: 4px;
            }
            .reneai-action-btn {
                background: rgba(255, 255, 255, 0.05);
                border: 1px solid rgba(255, 255, 255, 0.12);
                color: #94a3b8;
                font-size: 11px;
                border-radius: 5px;
                padding: 2px 7px;
                cursor: pointer;
                transition: all 0.2s;
            }
            .reneai-action-btn:hover {
                background: rgba(255, 255, 255, 0.12);
                color: #fff;
            }
        `;
        document.head.appendChild(style);
    }

    // =========================================================================
    // 14. FLOATING SUPPORT WIDGET INJECTION
    // =========================================================================

    function injectSupportWidgetUI() {
        if (document.getElementById('aiSupportFloatingContainer')) return;

        const container = document.createElement('div');
        container.id = 'aiSupportFloatingContainer';
        container.innerHTML = `
            <!-- FLOATING TOGGLE PILL -->
            <button id="btnAiSupportLauncher" type="button" onclick="window.openStudioAiSupport()"
                style="position: fixed; bottom: 22px; right: 24px; z-index: 99999; background: linear-gradient(135deg, #ff4d8d 0%, #ec4899 100%); color: #ffffff; border: 1.5px solid rgba(255, 255, 255, 0.35); border-radius: 999px; padding: 11px 22px; font-weight: 800; font-size: 13.5px; box-shadow: 0 8px 24px rgba(255, 77, 141, 0.45); cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);">
                <span style="font-size: 16px;">💬</span>
                <span class="ai-pill-label">RENEAI Support</span>
                <span style="width: 7px; height: 7px; border-radius: 50%; background: #4ade80; box-shadow: 0 0 8px #4ade80;"></span>
            </button>

            <!-- FLOATING WINDOW MODAL -->
            <div id="aiSupportWindow"
                style="display: none; position: fixed; bottom: 80px; right: 24px; width: 440px; height: 600px; max-width: calc(100vw - 32px); max-height: calc(100vh - 100px); z-index: 99999; background: #0c0f18; border: 1.5px solid rgba(255, 77, 141, 0.35); border-radius: 18px; box-shadow: 0 20px 50px rgba(0,0,0,0.7), 0 0 30px rgba(255,77,141,0.15); flex-direction: column; overflow: hidden;">
                
                <!-- HEADER -->
                <div style="padding: 13px 16px; background: rgba(18, 22, 34, 0.95); border-bottom: 1px solid rgba(255, 255, 255, 0.08); display: flex; align-items: center; justify-content: space-between;">
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <span style="width: 8px; height: 8px; border-radius: 50%; background: #4ade80; box-shadow: 0 0 8px #4ade80;"></span>
                        <span style="font-size: 13.5px; font-weight: 800; color: #fff;">RENEAI Support</span>
                        <span style="font-size: 10.5px; color: #ff4d8d; background: rgba(255,77,141,0.12); padding: 2px 7px; border-radius: 999px; border: 1px solid rgba(255,77,141,0.3);">100% OFFLINE</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <button type="button" onclick="window.clearStudioAiChatHistory()" class="reneai-action-btn" title="Clear chat history">🧹</button>
                        <button type="button" onclick="document.getElementById('aiSupportWindow').style.display='none'" class="reneai-action-btn" title="Close window">✕</button>
                    </div>
                </div>

                <!-- MESSAGES -->
                <div id="aiSupportMessageList" style="flex: 1; overflow-y: auto; padding: 14px; display: flex; flex-direction: column; gap: 10px; scroll-behavior: smooth;"></div>

                <!-- TYPING INDICATOR -->
                <div id="aiTypingIndicator" style="display: none; align-items: center; gap: 8px; padding: 6px 14px; background: rgba(18, 22, 34, 0.6); border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 11px; color: #94a3b8;">
                    <span>RENEAI is typing...</span>
                </div>

                <!-- INPUT -->
                <div style="padding: 10px 12px; background: rgba(12, 15, 24, 0.98); border-top: 1px solid rgba(255, 255, 255, 0.08); display: flex; gap: 8px; align-items: flex-end;">
                    <textarea id="aiSupportInput" rows="1" placeholder="Ask about overlays, gifts, or game triggers..."
                        onkeydown="if(event.key==='Enter' && !event.shiftKey){ event.preventDefault(); window.sendStudioAiChatMessage(); }"
                        style="flex: 1; background: rgba(18, 22, 34, 0.85); border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 9px; padding: 8px 12px; color: #ffffff; font-family: inherit; font-size: 12.5px; resize: none; max-height: 90px; outline: none;"></textarea>
                    <button type="button" onclick="window.sendStudioAiChatMessage()"
                        style="background: #ff4d8d; color: #ffffff; border: none; padding: 8px 14px; border-radius: 9px; font-weight: 800; font-size: 12.5px; cursor: pointer;">
                        ➤
                    </button>
                </div>
            </div>
        `;
        document.body.appendChild(container);
    }

    // =========================================================================
    // 15. FULL AI SUPPORT TAB PANE (#tab-support) RENDERING
    // =========================================================================

    function renderAiSupportTab() {
        const container = document.getElementById('tab-support');
        if (!container) return;

        container.innerHTML = `
            <div style="max-width: 1360px; margin: 0 auto; display: flex; flex-direction: column; gap: 20px;">
                <!-- HERO BANNER -->
                <div style="background: linear-gradient(135deg, rgba(255, 77, 141, 0.12) 0%, rgba(13, 15, 24, 0.95) 50%, rgba(139, 92, 246, 0.18) 100%); border: 1.5px solid rgba(255, 77, 141, 0.35); border-radius: 20px; padding: 22px 26px; box-shadow: 0 16px 40px rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: space-between; gap: 20px; flex-wrap: wrap;">
                    <div style="display: flex; align-items: center; gap: 16px;">
                        <div style="width: 58px; height: 58px; border-radius: 16px; background: linear-gradient(135deg, #ff4d8d, #8b5cf6); display: flex; align-items: center; justify-content: center; font-size: 28px; box-shadow: 0 8px 24px rgba(255, 77, 141, 0.45); flex-shrink: 0;">
                            🤖
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                                <h2 style="font-size: 22px; font-weight: 800; color: #fff; margin: 0;">RENEAI Customer Support & Assistant</h2>
                                <span style="background: rgba(34, 197, 94, 0.18); color: #4ade80; border: 1px solid #22c55e; font-size: 10.5px; font-weight: 800; padding: 3px 10px; border-radius: 999px;">● 100% OFFLINE AI</span>
                                <span style="background: rgba(56, 189, 248, 0.15); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.35); font-size: 10.5px; font-weight: 800; padding: 3px 10px; border-radius: 999px;" title="Runs fully on your device. Nothing you type here is sent anywhere.">🔒 ZERO EXTERNAL CALLS • PRIVATE</span>
                            </div>
                            <p style="font-size: 13px; color: #94a3b8; margin-top: 4px; margin-bottom: 0;">
                                Instant answers for game interactions, OBS overlays, TikTok gift mapping, song requests, and lucky wheel configurations.
                            </p>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <button type="button" class="btn btn-secondary btn-sm" onclick="window.toggleImproveReneAiPanel()"
                            style="background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.18); color: #cbd5e1; display: flex; align-items: center; gap: 6px; padding: 9px 15px; border-radius: 10px; font-weight: 700; cursor: pointer;">
                            🛠️ Improve RENEAI
                        </button>
                        <button type="button" class="btn btn-primary btn-sm" onclick="window.openStudioAiSupport()"
                            style="background: linear-gradient(135deg, #ff4d8d, #ec4899); border: 1px solid #ff4d8d; color: #fff; display: flex; align-items: center; gap: 6px; padding: 9px 18px; border-radius: 10px; font-weight: 800; cursor: pointer; box-shadow: 0 4px 14px rgba(255, 77, 141, 0.4);">
                            💬 Floating Popout
                        </button>
                    </div>
                </div>

                <!-- 2-COLUMN ARRANGEMENT -->
                <div style="display: grid; grid-template-columns: 360px 1fr; gap: 20px;">
                    
                    <!-- LEFT COLUMN: QUICK HELP TOPICS -->
                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <div style="font-size: 12px; font-weight: 800; color: #ff4d8d; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px; display: flex; align-items: center; gap: 6px;">
                            <span>📚</span><span>Quick Help Topics</span>
                        </div>

                        <!-- TOPICS LIST -->
                        ${[
                            { icon: "🎮", title: "What is this Platform?", desc: "Interactive audience-to-game streaming suite overview.", q: "What is this app and how does it interact with games?" },
                            { icon: "🕹️", title: "Game Interaction Engine", desc: "Simulated keystrokes, coordinate clicks & mod bridge.", q: "How does the app interact with games in real-time?" },
                            { icon: "🎬", title: "OBS & Stream Overlays", desc: "Browser source URLs, canvas size & setup guide.", q: "How do I add overlays to OBS or TikTok Live Studio?" },
                            { icon: "🎁", title: "TikTok Gifts to Spawns", desc: "Link gifts (Rose, Perfume, Heart) to in-game actions.", q: "How do TikTok gifts connect to game commands?" },
                            { icon: "🎶", title: "Song Requests & Vinyl", desc: "Viewer !play commands, Spotify queue & vinyl overlay.", q: "How does the Song Request and Spotify system work?" },
                            { icon: "🎡", title: "Wheels & 3D Claw Machine", desc: "Reel, 2D Wheel, Vegas Slot & UFO Catcher modes.", q: "How do Lucky Wheels, 3D Slots and 3D Claw visualizers work?" },
                            { icon: "🔧", title: "Troubleshooting & Fixes", desc: "Connection recovery, refresh cache, and game ports.", q: "How to fix overlay not working or disconnected?" }
                        ].map((t, tIdx) => `
                            <div onclick="window.askStudioAiDirect('${t.q.replace(/'/g, "\\'")}')" class="reneai-quick-topic"
                                style="cursor: pointer; background: rgba(15, 18, 28, 0.85); border: 1px solid rgba(255,255,255,0.08); border-radius: 12px; padding: 12px 14px; transition: all 0.2s;"
                                onmouseover="this.style.background='rgba(255, 77, 141, 0.1)'; this.style.borderColor='#ff4d8d';"
                                onmouseout="this.style.background='rgba(15, 18, 28, 0.85)'; this.style.borderColor='rgba(255,255,255,0.08)';">
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <span style="font-size: 20px;">${t.icon}</span>
                                    <div>
                                        <div style="font-size: 13px; font-weight: 800; color: #fff;">${t.title}</div>
                                        <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">${t.desc}</div>
                                    </div>
                                </div>
                            </div>
                        `).join('')}
                    </div>

                    <!-- RIGHT COLUMN: INTERACTIVE CHAT CONSOLE -->
                    <div style="background: #0b0d14; border: 1.5px solid rgba(255, 77, 141, 0.3); border-radius: 18px; display: flex; flex-direction: column; height: 620px; overflow: hidden; box-shadow: 0 12px 36px rgba(0,0,0,0.5);">
                        
                        <!-- CHAT CONSOLE HEADER -->
                        <div style="padding: 14px 18px; background: rgba(18, 22, 34, 0.95); border-bottom: 1px solid rgba(255, 255, 255, 0.08); display: flex; align-items: center; justify-content: space-between;">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <span style="width: 8px; height: 8px; border-radius: 50%; background: #4ade80; box-shadow: 0 0 8px #4ade80;"></span>
                                <span style="font-size: 14px; font-weight: 800; color: #fff;">RENEAI Support Console</span>
                                <span style="font-size: 11px; color: #94a3b8;">• Built-in Offline Assistant</span>
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
                            style="display: none; align-items: center; gap: 8px; padding: 6px 18px; background: rgba(18, 22, 34, 0.6); border-top: 1px solid rgba(255, 255, 255, 0.05); font-size: 11.5px; color: #94a3b8;">
                            <span>RENEAI is typing...</span>
                        </div>

                        <!-- CHAT INPUT AREA -->
                        <div style="padding: 12px 14px; background: rgba(11, 13, 20, 0.98); border-top: 1px solid rgba(255, 255, 255, 0.08); display: flex; gap: 10px; align-items: flex-end;">
                            <textarea id="aiTabInput" rows="1" placeholder="Ask about overlays, TikTok gift links, supported games, or connection fixes..."
                                onkeydown="if(event.key==='Enter' && !event.shiftKey){ event.preventDefault(); window.sendStudioAiChatMessage(); }"
                                style="flex: 1; background: rgba(18, 22, 34, 0.85); border: 1.5px solid rgba(255, 255, 255, 0.15); border-radius: 10px; padding: 10px 14px; color: #ffffff; font-family: inherit; font-size: 13px; line-height: 1.4; resize: none; max-height: 110px; outline: none;"></textarea>
                            <button type="button" onclick="window.sendStudioAiChatMessage()"
                                style="background: linear-gradient(135deg, #ff4d8d, #ec4899); color: #ffffff; border: none; padding: 10px 20px; border-radius: 10px; font-weight: 800; font-size: 13px; cursor: pointer; display: flex; align-items: center; gap: 6px; box-shadow: 0 4px 12px rgba(255, 77, 141, 0.4); flex-shrink: 0;">
                                <span>Send</span> <span>➤</span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- STEP 5: IMPROVE RENEAI DEVELOPER DRAWER -->
                <div id="reneaiImprovePanel" style="display: none; background: rgba(15, 18, 28, 0.95); border: 1px solid rgba(255, 77, 141, 0.3); border-radius: 16px; padding: 20px; margin-top: 10px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                        <div>
                            <h3 style="font-size: 16px; font-weight: 800; color: #fff; margin: 0;">🛠️ Improve RENEAI (Offline Learning Loop)</h3>
                            <p style="font-size: 12px; color: #94a3b8; margin: 2px 0 0;">Inspect unanswered queries, add custom answers, or run automated self-tests.</p>
                        </div>
                        <div style="display: flex; gap: 8px;">
                            <button type="button" class="btn btn-sm" onclick="window.runReneAiSelfTests()" style="background: #10b981; color: #fff; border: none; padding: 6px 14px; border-radius: 8px; font-weight: 700; cursor: pointer;">
                                🧪 Run Self-Tests (12 Cases)
                            </button>
                            <button type="button" class="btn btn-sm" onclick="window.exportReneAiLogs()" style="background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.15); color: #fff; padding: 6px 12px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                                📥 Export Logs
                            </button>
                        </div>
                    </div>

                    <!-- TEST RESULTS CONTAINER -->
                    <div id="reneaiTestResults" style="display: none; background: #0c0f18; border: 1px solid rgba(255,255,255,0.1); border-radius: 10px; padding: 14px; margin-bottom: 16px; font-family: monospace; font-size: 12px; max-height: 200px; overflow-y: auto;"></div>

                    <!-- ADD CUSTOM Q&A FORM -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr auto; gap: 10px; align-items: flex-end;">
                        <div>
                            <label style="font-size: 11px; font-weight: 700; color: #cbd5e1; display: block; margin-bottom: 4px;">User Question / Trigger</label>
                            <input id="txtCustomQuestion" type="text" placeholder="e.g. how do i turn on dark mode" style="width: 100%; background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.15); border-radius: 8px; padding: 8px 12px; color: #fff; font-size: 12px;">
                        </div>
                        <div>
                            <label style="font-size: 11px; font-weight: 700; color: #cbd5e1; display: block; margin-bottom: 4px;">Assistant Answer</label>
                            <input id="txtCustomAnswer" type="text" placeholder="e.g. Dark mode is enabled by default in RENEarn Studio!" style="width: 100%; background: rgba(0,0,0,0.4); border: 1px solid rgba(255,255,255,0.15); border-radius: 8px; padding: 8px 12px; color: #fff; font-size: 12px;">
                        </div>
                        <button type="button" onclick="window.saveCustomQnA()" style="background: #ff4d8d; color: #fff; border: none; padding: 8px 16px; border-radius: 8px; font-weight: 700; font-size: 12px; cursor: pointer; height: 35px;">
                            Save Answer
                        </button>
                    </div>
                </div>
            </div>
        `;

        renderMessages();
    }

    window.toggleImproveReneAiPanel = function () {
        const p = document.getElementById('reneaiImprovePanel');
        if (p) p.style.display = p.style.display === 'none' ? 'block' : 'none';
    };

    window.saveCustomQnA = function () {
        const qEl = document.getElementById('txtCustomQuestion');
        const aEl = document.getElementById('txtCustomAnswer');
        const q = qEl ? qEl.value.trim() : '';
        const a = aEl ? aEl.value.trim() : '';
        if (!q || !a) {
            if (window.showToast) window.showToast('Please enter both question and answer', 'WARNING');
            return;
        }

        try {
            const list = JSON.parse(localStorage.getItem(STORAGE_KEY_OVERRIDES) || '[]');
            list.push({ question: q, answer: a, chips: ["What is this app?", "OBS overlay URLs"] });
            localStorage.setItem(STORAGE_KEY_OVERRIDES, JSON.stringify(list));
            qEl.value = '';
            aEl.value = '';
            if (window.showToast) window.showToast(`✅ Custom Q&A saved! RENEAI will now answer: "${q}"`, 'SAVED');
        } catch (e) {}
    };

    window.exportReneAiLogs = function () {
        try {
            const logs = localStorage.getItem(STORAGE_KEY_LOGS) || '[]';
            const blob = new Blob([logs], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `reneai_logs_${Date.now()}.json`;
            a.click();
            URL.revokeObjectURL(url);
        } catch (e) {}
    };

    // =========================================================================
    // 16. STEP 5: AUTOMATED SELF-TEST RUNNER (12 TEST CASES)
    // =========================================================================

    window.runReneAiSelfTests = async function () {
        const container = document.getElementById('reneaiTestResults');
        if (!container) return;
        container.style.display = 'block';
        container.innerHTML = '⏳ <strong>Running 12 RENEAI Self-Tests...</strong><br/><br/>';

        const tests = [
            { id: 1, query: "who are you?", check: r => r.text.includes("RENEAI Support") },
            { id: 2, query: "who r u", check: r => r.text.includes("RENEAI Support") },
            { id: 3, query: "sino ka?", check: r => r.text.includes("RENEAI Support") },
            { id: 4, query: "what is this game?", check: r => r.text.includes("RENEarn") && r.text.includes("PvZ") },
            { id: 5, query: "what is this app?", check: r => r.text.includes("Live Streaming") || r.text.includes("RENEarn") },
            { id: 6, query: "hello", check: r => r.confidence === 1.0 },
            { id: 7, query: "helo", check: r => r.confidence === 1.0 },
            { id: 8, query: "how do I add the song request overlay in OBS?", check: r => r.text.includes("overlay-songrequest.html") },
            { id: 9, query: "how do i link gifts to spawns", check: r => r.text.includes("Gift Commands") || r.text.includes("Rose") },
            { id: 10, query: "paano mag-connect sa tiktok", check: r => r.text.includes("TikTok LIVE") && (r.text.includes("Connect") || r.text.includes("Studio")) },
            { id: 11, query: "does the app support Fortnite?", check: r => r.text.includes("not natively support") || r.text.includes("hindi suportado") },
            { id: 12, query: "asdfgh random gibberish", check: r => r.text.length > 20 && r.chips.length > 0 }
        ];

        let passed = 0;
        let logs = [];

        for (const t of tests) {
            const res = await getReply(t.query);
            const ok = t.check(res);
            if (ok) passed++;
            logs.push(`${ok ? '✅ PASS' : '❌ FAIL'} [Test ${t.id}]: "${t.query}" -> ${ok ? 'Matches expected criteria' : 'Unexpected result'}`);
        }

        container.innerHTML = `<strong>Result: ${passed} / ${tests.length} Tests Passed!</strong><br/><br/>${logs.join('<br/>')}`;
    };

    // =========================================================================
    // 17. INITIALIZATION & DATA LOADING
    // =========================================================================

    async function loadJsonDataFiles() {
        try {
            // Try loading smalltalk.json
            const stRes = await fetch('reneai/smalltalk.json?v=' + Date.now()).catch(() => null);
            if (stRes && stRes.ok) {
                smalltalk = await stRes.json();
            }
        } catch (e) {}

        try {
            const kbRes = await fetch('reneai/knowledge.json?v=' + Date.now()).catch(() => null);
            if (kbRes && kbRes.ok) {
                const kbData = await kbRes.json();
                if (kbData && kbData.articles) knowledge = kbData.articles;
            }
        } catch (e) {}

        try {
            const synRes = await fetch('reneai/synonyms.json?v=' + Date.now()).catch(() => null);
            if (synRes && synRes.ok) {
                const synData = await synRes.json();
                if (synData && synData.synonyms) synonyms = synData.synonyms;
            }
        } catch (e) {}

        try {
            const perRes = await fetch('reneai/persona.json?v=' + Date.now()).catch(() => null);
            if (perRes && perRes.ok) {
                const perData = await perRes.json();
                if (perData) persona = { ...DEFAULT_PERSONA, ...perData };
            }
        } catch (e) {}
    }

    function init() {
        injectReneAiStyles();
        loadHistory();
        injectSupportWidgetUI();
        if (document.getElementById('tab-support')) {
            renderAiSupportTab();
        }
        startRotatingPlaceholders();
        loadJsonDataFiles();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.openStudioAiSupport = function (initialQuestion = '') {
        const win = document.getElementById('aiSupportWindow');
        if (win) {
            win.style.display = 'flex';
            if (initialQuestion) {
                handleUserSendMessage(initialQuestion);
            }
        }
    };
    window.renderAiSupportTab = renderAiSupportTab;
})();
