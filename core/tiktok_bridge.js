const { TikTokLiveConnection } = require('tiktok-live-connector');
const http = require('http');
const fs = require('fs');
const path = require('path');

const targetUser = (process.argv[2] || '').trim().replace(/^@/, '');
if (!targetUser) {
    console.log('No TikTok username provided. Standing by...');
    process.exit(0);
}
const webhookUrl = 'http://127.0.0.1:8080/api/webhook/tiktok';
const stateFilePath = path.join(__dirname, 'tiktok_live_state.json');

let liveState = {
    connected: false,
    username: targetUser,
    roomId: null,
    viewerCount: 0,
    totalLikes: 0,
    statusText: 'Connecting...',
    lastEventTime: Date.now()
};

// Load verified TikTok gifts catalog (673+ items)
const verifiedGiftsMap = new Map();
try {
    const verifiedPath = path.join(__dirname, 'tiktok_gifts_verified.json');
    if (fs.existsSync(verifiedPath)) {
        const verifiedData = JSON.parse(fs.readFileSync(verifiedPath, 'utf8'));
        if (Array.isArray(verifiedData)) {
            verifiedData.forEach(g => {
                if (g && g.id) {
                    verifiedGiftsMap.set(String(g.id), g);
                }
            });
        }
        console.log(`[GIFTS CATALOG] Loaded ${verifiedGiftsMap.size} verified TikTok gifts into bridge dictionary.`);
    }
} catch (e) {
    console.warn(`[GIFTS CATALOG] Note: Could not load tiktok_gifts_verified.json:`, e.message);
}

function saveState() {
    try {
        fs.writeFileSync(stateFilePath, JSON.stringify(liveState, null, 2), 'utf8');
    } catch (e) {}
}

function postWebhook(payload) {
    try {
        const data = JSON.stringify(payload);
        const req = http.request(webhookUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(data)
            },
            timeout: 2000
        }, (res) => {});
        req.on('error', () => {});
        req.write(data);
        req.end();
    } catch (e) {}
}

console.log(`==========================================================`);
console.log(`  TikTok LIVE Studio Bridge Starting...`);
console.log(`  Target Streamer: @${targetUser}`);
console.log(`  Webhook Target : ${webhookUrl}`);
console.log(`==========================================================`);

let tiktokConnection = null;
let isReconnecting = false;

function startConnection() {
    liveState.statusText = 'Connecting to TikTok...';
    saveState();

    tiktokConnection = new TikTokLiveConnection(targetUser, {
        processInitialData: true,
        enableExtendedGiftInfo: true,
        requestPollingIntervalMs: 1000
    });

    tiktokConnection.connect().then(state => {
        isReconnecting = false;
        liveState.connected = true;
        liveState.roomId = state.roomId;
        liveState.statusText = 'Connected to Live Stream';
        liveState.lastEventTime = Date.now();
        saveState();

        console.log(`[SUCCESS] Connected to TikTok LIVE! Room ID: ${state.roomId}`);
        console.log(`[READY] Listening for Gifts, Likes, Follows, and Team Chat (!plants/!zombies)...`);
    }).catch(err => {
        liveState.connected = false;
        liveState.statusText = 'Connection failed: ' + (err.message || 'Offline');
        saveState();
        console.error(`[ERROR] Connection failed: ${err.message || err}`);
        scheduleReconnect(6000);
    });

    function extractUserName(d) {
        if (!d) return 'Viewer';

        // 1. Direct properties on data
        if (typeof d.nickname === 'string' && d.nickname.trim() && d.nickname.trim() !== 'Viewer' && d.nickname.trim() !== 'Gifter') {
            return d.nickname.trim();
        }
        if (typeof d.uniqueId === 'string' && d.uniqueId.trim() && d.uniqueId.trim() !== 'Viewer' && d.uniqueId.trim() !== 'Gifter') {
            return d.uniqueId.trim();
        }
        if (typeof d.displayId === 'string' && d.displayId.trim()) {
            return d.displayId.trim();
        }

        // 2. Nested user object (TikTok Protobuf message)
        if (d.user && typeof d.user === 'object') {
            if (typeof d.user.nickname === 'string' && d.user.nickname.trim()) {
                return d.user.nickname.trim();
            }
            if (typeof d.user.uniqueId === 'string' && d.user.uniqueId.trim()) {
                return d.user.uniqueId.trim();
            }
            if (typeof d.user.displayId === 'string' && d.user.displayId.trim()) {
                return d.user.displayId.trim();
            }
        }

        // 3. Nested userDetails object
        if (d.userDetails && typeof d.userDetails === 'object') {
            if (typeof d.userDetails.nickname === 'string' && d.userDetails.nickname.trim()) {
                return d.userDetails.nickname.trim();
            }
            if (typeof d.userDetails.uniqueId === 'string' && d.userDetails.uniqueId.trim()) {
                return d.userDetails.uniqueId.trim();
            }
            if (typeof d.userDetails.displayId === 'string' && d.userDetails.displayId.trim()) {
                return d.userDetails.displayId.trim();
            }
        }

        // 4. Common displayText pieces (Protobuf displayText with user piece)
        if (d.common && d.common.displayText && Array.isArray(d.common.displayText.pieces)) {
            for (const piece of d.common.displayText.pieces) {
                const u = (piece.userValue && piece.userValue.user) || piece.user;
                if (u) {
                    if (typeof u.nickname === 'string' && u.nickname.trim()) return u.nickname.trim();
                    if (typeof u.displayId === 'string' && u.displayId.trim()) return u.displayId.trim();
                    if (typeof u.uniqueId === 'string' && u.uniqueId.trim()) return u.uniqueId.trim();
                }
            }
        }

        // 5. Fallback sender / author properties
        if (d.sender && typeof d.sender === 'object') {
            if (typeof d.sender.nickname === 'string' && d.sender.nickname.trim()) return d.sender.nickname.trim();
            if (typeof d.sender.uniqueId === 'string' && d.sender.uniqueId.trim()) return d.sender.uniqueId.trim();
        }

        return 'Viewer';
    }

    function extractAvatarUrl(d) {
        if (!d) return '';

        // 1. Direct avatar properties
        if (typeof d.profilePictureUrl === 'string' && d.profilePictureUrl.startsWith('http')) return d.profilePictureUrl;
        if (typeof d.avatarUrl === 'string' && d.avatarUrl.startsWith('http')) return d.avatarUrl;

        // 2. Nested user object (TikTok Protobuf)
        if (d.user && typeof d.user === 'object') {
            if (typeof d.user.profilePictureUrl === 'string' && d.user.profilePictureUrl.startsWith('http')) return d.user.profilePictureUrl;
            if (typeof d.user.avatarUrl === 'string' && d.user.avatarUrl.startsWith('http')) return d.user.avatarUrl;

            // Avatar thumbs / medium / large
            if (d.user.avatarThumb && Array.isArray(d.user.avatarThumb.urlList) && d.user.avatarThumb.urlList[0]) {
                return d.user.avatarThumb.urlList[0];
            }
            if (d.user.avatarMedium && Array.isArray(d.user.avatarMedium.urlList) && d.user.avatarMedium.urlList[0]) {
                return d.user.avatarMedium.urlList[0];
            }
            if (d.user.avatarLarge && Array.isArray(d.user.avatarLarge.urlList) && d.user.avatarLarge.urlList[0]) {
                return d.user.avatarLarge.urlList[0];
            }

            // ProfilePicture object
            if (d.user.profilePicture) {
                if (Array.isArray(d.user.profilePicture.urls) && d.user.profilePicture.urls[0]) return d.user.profilePicture.urls[0];
                if (Array.isArray(d.user.profilePicture.urlList) && d.user.profilePicture.urlList[0]) return d.user.profilePicture.urlList[0];
                if (Array.isArray(d.user.profilePicture.url) && d.user.profilePicture.url[0]) return d.user.profilePicture.url[0];
                if (typeof d.user.profilePicture.url === 'string' && d.user.profilePicture.url.startsWith('http')) return d.user.profilePicture.url;
            }
        }

        // 3. Nested userDetails object
        if (d.userDetails && typeof d.userDetails === 'object') {
            if (Array.isArray(d.userDetails.profilePictureUrls) && d.userDetails.profilePictureUrls[0]) {
                return d.userDetails.profilePictureUrls[0];
            }
        }

        // 4. Nested sender object
        if (d.sender && typeof d.sender === 'object') {
            if (typeof d.sender.profilePictureUrl === 'string' && d.sender.profilePictureUrl.startsWith('http')) return d.sender.profilePictureUrl;
            if (typeof d.sender.avatarUrl === 'string' && d.sender.avatarUrl.startsWith('http')) return d.sender.avatarUrl;
            if (d.sender.avatarThumb && Array.isArray(d.sender.avatarThumb.urlList) && d.sender.avatarThumb.urlList[0]) {
                return d.sender.avatarThumb.urlList[0];
            }
        }

        // 5. Protobuf displayText user piece
        if (d.common && d.common.displayText && Array.isArray(d.common.displayText.pieces)) {
            for (const piece of d.common.displayText.pieces) {
                const u = (piece.userValue && piece.userValue.user) || piece.user;
                if (u) {
                    if (u.avatarThumb && Array.isArray(u.avatarThumb.urlList) && u.avatarThumb.urlList[0]) return u.avatarThumb.urlList[0];
                    if (u.profilePicture && Array.isArray(u.profilePicture.urls) && u.profilePicture.urls[0]) return u.profilePicture.urls[0];
                }
            }
        }

        return '';
    }

    // Track repeat counts per user + gift so every tap triggers immediately
    const activeStreaks = new Map();
    // Deduplication cache for non-streak gifts (prevents double firing when repeatEnd echoes duplicate count)
    const recentGiftPackets = new Map();

    // 1. Gift Event
    tiktokConnection.on('gift', data => {
        liveState.lastEventTime = Date.now();
        const giftId = String(data.giftId || (data.giftDetails && data.giftDetails.id) || (data.extendedGiftInfo && data.extendedGiftInfo.id) || '').trim();
        const verified = verifiedGiftsMap.get(giftId);

        let giftName = data.giftName || (data.giftDetails && data.giftDetails.giftName) || (data.giftDetails && data.giftDetails.name) || (data.extendedGiftInfo && data.extendedGiftInfo.name) || '';
        if ((!giftName || giftName === 'Gift') && verified && verified.name) {
            giftName = verified.name;
        }
        if (!giftName && data.describe) { giftName = data.describe; }
        if (!giftName && verified && verified.name) { giftName = verified.name; }
        if (!giftName) { giftName = 'Gift'; }

        const user = extractUserName(data);
        const userAvatar = extractAvatarUrl(data);
        const totalCount = parseInt(data.repeatCount, 10) || 1;
        const isStreak = (data.giftType === 1);
        const streakKey = `${user}_${giftId}`;
        const now = Date.now();

        let deltaCount = 1;

        if (isStreak) {
            const prev = activeStreaks.get(streakKey) || 0;
            if (totalCount > prev) {
                deltaCount = totalCount - prev;
                activeStreaks.set(streakKey, totalCount);
            } else {
                if (data.repeatEnd) {
                    activeStreaks.delete(streakKey);
                }
                return; // Duplicate streak packet or repeatEnd echo, already counted!
            }

            if (data.repeatEnd) {
                activeStreaks.delete(streakKey);
            }
        } else {
            // Non-streak gift:
            // If repeatEnd is true and this exact donation (user + giftId + count) was already processed < 5 seconds ago, ignore echo!
            const nonStreakKey = `${user}_${giftId}_${totalCount}`;
            const lastProcessedTime = recentGiftPackets.get(nonStreakKey);
            if (lastProcessedTime && (now - lastProcessedTime < 5000)) {
                if (data.repeatEnd) {
                    recentGiftPackets.delete(nonStreakKey);
                }
                return; // Skip duplicate echo!
            }
            recentGiftPackets.set(nonStreakKey, now);
            deltaCount = totalCount;
        }

        const unitDiamonds = parseInt(data.diamondCount || (data.giftDetails && data.giftDetails.diamondCount) || (data.extendedGiftInfo && data.extendedGiftInfo.diamondCount) || 0, 10);
        const unitCoins = unitDiamonds > 0 ? unitDiamonds : ((verified && verified.coins) ? parseInt(verified.coins, 10) : 1);
        const deltaCoins = unitCoins * deltaCount;

        const giftPic = (data.giftPictureUrl || 
                        (data.giftDetails && data.giftDetails.giftImage && data.giftDetails.giftImage.urlList && data.giftDetails.giftImage.urlList[0]) || 
                        (verified && verified.icon) || 
                        '');

        const payload = {
            event: 'gift',
            giftId: giftId,
            giftName: giftName,
            repeatCount: deltaCount,
            totalRepeatCount: totalCount,
            coins: deltaCoins,
            diamondCount: unitCoins,
            username: user,
            avatarUrl: userAvatar,
            giftPictureUrl: giftPic
        };

        const logMsg = `[${new Date().toLocaleTimeString()}] GIFT: ${user} sent ${deltaCount}x ${giftName} (ID: ${giftId}, ${unitCoins} coins each = ${deltaCoins} coins, streak: ${totalCount}, repeatEnd: ${!!data.repeatEnd})\n`;
        console.log(logMsg.trim());
        try { fs.appendFileSync(path.join(__dirname, 'tiktok_gifts_debug.log'), logMsg, 'utf8'); } catch (e) {}

        postWebhook(payload);
        saveState();
    });

    // 2. Like Event
    tiktokConnection.on('like', data => {
        liveState.lastEventTime = Date.now();
        if (data.totalLikeCount) {
            liveState.totalLikes = data.totalLikeCount;
        }

        const user = extractUserName(data);
        const userAvatar = extractAvatarUrl(data);
        const payload = {
            event: 'like',
            likeCount: data.likeCount || 1,
            totalLikeCount: data.totalLikeCount || liveState.totalLikes,
            username: user,
            avatarUrl: userAvatar
        };

        postWebhook(payload);
        saveState();
    });

    // Anti-spam: Strictly 1 follow per viewer per day or per live session (persistent)
    const followersFile = path.join(__dirname, 'session_followers.json');
    function getTodayFollowers() {
        const todayStr = new Date().toISOString().slice(0, 10);
        try {
            if (fs.existsSync(followersFile)) {
                const raw = JSON.parse(fs.readFileSync(followersFile, 'utf8'));
                if (raw && raw.date === todayStr && raw.followers) {
                    return new Set(Object.keys(raw.followers));
                }
            }
        } catch (e) {}
        return new Set();
    }
    const sessionFollowers = getTodayFollowers();

    // 3. Follow Event (Strictly 1 follow per viewer per day or per live session)
    tiktokConnection.on('follow', data => {
        liveState.lastEventTime = Date.now();
        const user = extractUserName(data);
        const uniqueId = data.uniqueId || (data.user && data.user.uniqueId) || (data.userDetails && data.userDetails.uniqueId) || '';
        const userId = data.userId || (data.user && data.user.userId) || (data.user && data.user.id) || '';
        const cleanUser = user.toLowerCase().replace(/[^a-z0-9]/g, '');
        const cleanUnique = (uniqueId || '').toLowerCase().replace(/[^a-z0-9]/g, '');
        const trackerKey = userId ? `uid_${userId}` : (cleanUnique ? `u_${cleanUnique}` : `u_${cleanUser}`);

        if ((trackerKey && sessionFollowers.has(trackerKey)) || (cleanUser && cleanUser !== 'viewer' && sessionFollowers.has(`u_${cleanUser}`))) {
            console.log(`>>> [FOLLOW IGNORED] @${user} already followed today / in this stream session.`);
            return;
        }

        if (trackerKey) sessionFollowers.add(trackerKey);
        if (cleanUser) sessionFollowers.add(`u_${cleanUser}`);

        // Persist to session_followers.json
        try {
            const todayStr = new Date().toISOString().slice(0, 10);
            const folObj = {};
            for (const f of sessionFollowers) folObj[f] = Date.now();
            fs.writeFileSync(followersFile, JSON.stringify({ date: todayStr, followers: folObj }, null, 2), 'utf8');
        } catch (e) {}

        const payload = {
            event: 'follow',
            username: user,
            userId: String(userId || ''),
            uniqueId: String(uniqueId || '')
        };

        console.log(`>>> [FOLLOW] @${user} followed! (1st time today / this session)`);
        postWebhook(payload);
        saveState();
    });

    // 4. Chat Event (Team Battle selection: !plants vs !zombies)
    tiktokConnection.on('chat', data => {
        liveState.lastEventTime = Date.now();
        const comment = data.comment || '';
        const user = extractUserName(data);

        if (comment.includes('!plant') || comment.includes('!zombie')) {
            console.log(`>>> [TEAM CHAT] ${user}: "${comment}"`);
        }

        const payload = {
            event: 'chat',
            username: user,
            comment: comment
        };

        postWebhook(payload);
    });

    // 5. Share Event
    tiktokConnection.on('share', data => {
        liveState.lastEventTime = Date.now();
        const payload = {
            event: 'share',
            username: data.uniqueId || data.nickname || 'Viewer'
        };

        console.log(`>>> [SHARE] ${payload.username} shared the stream!`);
        postWebhook(payload);
        saveState();
    });

    // 6. Room Viewers
    tiktokConnection.on('roomUser', data => {
        if (data.viewerCount !== undefined) {
            liveState.viewerCount = data.viewerCount;
            saveState();
        }
    });

    // 7. Stream End / Disconnect
    tiktokConnection.on('disconnected', () => {
        console.warn(`[DISCONNECT] Disconnected from TikTok LIVE`);
        liveState.connected = false;
        liveState.statusText = 'Disconnected';
        saveState();
        scheduleReconnect(5000);
    });

    tiktokConnection.on('streamEnd', () => {
        console.warn(`[STREAM END] TikTok Live stream ended`);
        liveState.connected = false;
        liveState.statusText = 'Stream Ended';
        saveState();
        scheduleReconnect(10000);
    });
}

function scheduleReconnect(delayMs) {
    if (isReconnecting) return;
    isReconnecting = true;
    console.log(`[RETRY] Reconnecting in ${delayMs / 1000}s...`);
    setTimeout(() => {
        if (tiktokConnection) {
            try { tiktokConnection.disconnect(); } catch (e) {}
            tiktokConnection = null;
        }
        startConnection();
    }, delayMs);
}

// Clean exit handling
process.on('SIGINT', () => {
    liveState.connected = false;
    liveState.statusText = 'Stopped';
    saveState();
    if (tiktokConnection) {
        try { tiktokConnection.disconnect(); } catch (e) {}
    }
    process.exit(0);
});

startConnection();
