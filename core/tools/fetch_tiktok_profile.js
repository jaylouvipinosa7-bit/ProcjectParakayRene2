const { TikTokLiveConnection } = require('tiktok-live-connector');
const fs = require('fs');
const path = require('path');

const targetUser = (process.argv[2] || 'gohanmalunggay').replace(/^@+/, '').trim();
if (!targetUser) {
    console.log(JSON.stringify({ success: false, error: 'No username provided' }));
    process.exit(0);
}

const cacheFile = path.join(__dirname, '..', 'tiktok_profile_cache.json');
let cache = {};
try {
    if (fs.existsSync(cacheFile)) {
        cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    }
} catch (e) {}

// Check cache (valid for 6 hours)
const now = Date.now();
if (cache[targetUser] && (now - (cache[targetUser].cachedAt || 0)) < 6 * 3600 * 1000) {
    console.log(JSON.stringify({ success: true, cached: true, ...cache[targetUser] }));
    process.exit(0);
}

async function run() {
    try {
        const conn = new TikTokLiveConnection(targetUser);
        const res = await conn.webClient.fetchRoomInfoFromHtml({ uniqueId: targetUser });
        const user = res && res.user;
        if (user) {
            const avatar = user.avatarMedium || user.avatarLarger || user.avatarThumb || '';
            const nickname = user.nickname || targetUser;
            const profileData = {
                username: targetUser,
                nickname: nickname,
                avatar: avatar,
                avatarLarger: user.avatarLarger || avatar,
                avatarThumb: user.avatarThumb || avatar,
                userId: user.id || '',
                secUid: user.secUid || '',
                cachedAt: now
            };
            cache[targetUser] = profileData;
            try {
                fs.writeFileSync(cacheFile, JSON.stringify(cache, null, 2), 'utf8');
            } catch (e) {}
            console.log(JSON.stringify({ success: true, ...profileData }));
            process.exit(0);
        } else {
            console.log(JSON.stringify({ success: false, error: 'User data not found in HTML' }));
        }
    } catch (e) {
        // If cache exists even if expired, return stale cache as fallback
        if (cache[targetUser]) {
            console.log(JSON.stringify({ success: true, stale: true, ...cache[targetUser] }));
        } else {
            console.log(JSON.stringify({ success: false, error: e.message }));
        }
    }
}

run();
