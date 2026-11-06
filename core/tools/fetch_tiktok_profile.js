const fs = require('fs');
const path = require('path');

const targetUser = (process.argv[2] || '').replace(/^@+/, '').trim();
if (!targetUser) {
    console.log(JSON.stringify({ success: false, error: 'No username provided' }));
    process.exit(0);
}

const cleanUser = targetUser.toLowerCase();
const cacheFile = path.join(__dirname, '..', 'tiktok_profile_cache.json');
let cache = {};
try {
    if (fs.existsSync(cacheFile)) {
        cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    }
} catch (e) {}

const now = Date.now();
const coreAvatarDir = path.join(__dirname, '..', 'images', 'avatars');
const rootAvatarDir = path.join(__dirname, '..', '..', 'images', 'avatars');
[coreAvatarDir, rootAvatarDir].forEach(d => {
    if (!fs.existsSync(d)) {
        try { fs.mkdirSync(d, { recursive: true }); } catch (e) {}
    }
});

const coreAvatarFile = path.join(coreAvatarDir, `${cleanUser}.jpg`);
const rootAvatarFile = path.join(rootAvatarDir, `${cleanUser}.jpg`);
const localRelativeUrl = `/images/avatars/${cleanUser}.jpg`;

async function fetchProfile() {
    let nickname = targetUser;
    let avatarUrl = localRelativeUrl;

    // 1. Fetch real-time display name via official TikTok oEmbed
    try {
        const oembedRes = await fetch(`https://www.tiktok.com/oembed?url=https://www.tiktok.com/@${targetUser}`, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
            signal: AbortSignal.timeout(6000)
        });
        if (oembedRes.ok) {
            const odata = await oembedRes.json();
            if (odata.author_name) {
                nickname = odata.author_name;
            }
        }
    } catch (e) {
        if (cache[cleanUser] && cache[cleanUser].nickname) {
            nickname = cache[cleanUser].nickname;
        }
    }

    // 2. Fetch avatar image from unavatar.io and persist to disk
    try {
        const avRes = await fetch(`https://unavatar.io/tiktok/${targetUser}`, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
            signal: AbortSignal.timeout(8000)
        });
        if (avRes.ok) {
            const buf = Buffer.from(await avRes.arrayBuffer());
            if (buf && buf.length > 500) {
                fs.writeFileSync(coreAvatarFile, buf);
                try { fs.writeFileSync(rootAvatarFile, buf); } catch (e) {}
                avatarUrl = localRelativeUrl;
            }
        }
    } catch (e) {
        if (!fs.existsSync(coreAvatarFile)) {
            avatarUrl = `https://unavatar.io/tiktok/${targetUser}`;
        }
    }

    // Fallback if local file exists
    if (fs.existsSync(coreAvatarFile)) {
        avatarUrl = localRelativeUrl;
    } else {
        avatarUrl = `https://unavatar.io/tiktok/${targetUser}`;
    }

    const profileData = {
        username: targetUser,
        nickname: nickname,
        avatar: avatarUrl,
        fallbackAvatar: `https://unavatar.io/tiktok/${targetUser}`,
        cachedAt: now
    };

    cache[cleanUser] = profileData;
    cache[targetUser] = profileData;
    try {
        fs.writeFileSync(cacheFile, JSON.stringify(cache, null, 2), 'utf8');
    } catch (e) {}

    // Also update tiktok_live_state.json if active streamer matches
    try {
        const stateFile = path.join(__dirname, '..', 'tiktok_live_state.json');
        if (fs.existsSync(stateFile)) {
            const sJson = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
            if (!sJson.username || sJson.username.toLowerCase() === cleanUser) {
                sJson.username = targetUser;
                sJson.nickname = nickname;
                sJson.avatar = avatarUrl;
                fs.writeFileSync(stateFile, JSON.stringify(sJson, null, 2), 'utf8');
            }
        }
    } catch (e) {}

    console.log(JSON.stringify({ success: true, ...profileData }));
}

fetchProfile().catch(err => {
    const fallback = {
        success: true,
        username: targetUser,
        nickname: targetUser,
        avatar: fs.existsSync(coreAvatarFile) ? localRelativeUrl : `https://unavatar.io/tiktok/${targetUser}`,
        fallbackAvatar: `https://unavatar.io/tiktok/${targetUser}`,
        cachedAt: now
    };
    console.log(JSON.stringify(fallback));
});
