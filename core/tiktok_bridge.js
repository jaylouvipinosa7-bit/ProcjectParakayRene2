const { TikTokLiveConnection } = require('tiktok-live-connector');
const http = require('http');
const fs = require('fs');
const path = require('path');

let rawUserArg = (process.argv[2] || '').trim();
let targetUser = rawUserArg;
const urlMatch = rawUserArg.match(/tiktok\.com\/@([a-zA-Z0-9_.-]+)/i);
if (urlMatch) {
    targetUser = urlMatch[1];
} else {
    targetUser = rawUserArg.replace(/^@+/, '').split('/')[0].split('?')[0].split('&')[0].trim();
}
if (!targetUser) {
    console.log('No TikTok username provided. Standing by...');
    process.exit(0);
}
const webhookUrl = 'http://127.0.0.1:8080/api/webhook/tiktok';
const stateFilePath = path.join(__dirname, 'tiktok_live_state.json');

let liveState = {
    connected: false,
    processRunning: true,
    username: targetUser,
    roomId: null,
    viewerCount: 0,
    totalLikes: 0,
    statusText: 'Connecting to TikTok...',
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

// Load detected region configuration
let detectedRegionCode = 'PH';
try {
    const regPath = path.join(__dirname, 'region_config.json');
    if (fs.existsSync(regPath)) {
        const regData = JSON.parse(fs.readFileSync(regPath, 'utf8'));
        if (regData) {
            detectedRegionCode = regData.selectedRegion || (regData.detectedRegion && regData.detectedRegion.countryCode) || 'PH';
        }
    }
    console.log(`[REGION] Initialized TikTok Live Bridge for region: ${detectedRegionCode}`);
} catch (e) {}

let tiktokConnection = null;
let isReconnecting = false;

function startConnection() {
    liveState.statusText = 'Waiting for Stream...';
    saveState();

    // Clean up any existing connection and remove all listeners to prevent duplicate triggers
    if (tiktokConnection) {
        try {
            if (typeof tiktokConnection.removeAllListeners === 'function') {
                tiktokConnection.removeAllListeners();
            }
            tiktokConnection.disconnect();
        } catch (e) {}
        tiktokConnection = null;
    }

    tiktokConnection = new TikTokLiveConnection(targetUser, {
        processInitialData: true,
        enableExtendedGiftInfo: true,
        requestPollingIntervalMs: 1000,
        clientParams: {
            priority_region: detectedRegionCode,
            region: detectedRegionCode,
            app_language: 'en',
            webcast_language: 'en'
        }
    });

    // Auto-discover streamer profile photo & nickname
    try {
        if (tiktokConnection && tiktokConnection.webClient && typeof tiktokConnection.webClient.fetchRoomInfoFromHtml === 'function') {
            tiktokConnection.webClient.fetchRoomInfoFromHtml({ uniqueId: targetUser }).then(res => {
                if (res && res.user) {
                    const u = res.user;
                    const av = u.avatarMedium || u.avatarLarger || u.avatarThumb;
                    if (av) {
                        liveState.avatar = av;
                        liveState.nickname = u.nickname || targetUser;
                        saveState();
                        postWebhook({
                            event: 'streamer_profile',
                            username: targetUser,
                            nickname: liveState.nickname,
                            avatar: av
                        });
                        console.log(`[PROFILE] Synced real TikTok Profile Photo for @${targetUser}`);
                    }
                }
            }).catch(() => {});
        }
    } catch (e) {}

    tiktokConnection.connect().then(async state => {
        isReconnecting = false;
        liveState.connected = true;
        liveState.roomId = state.roomId;
        liveState.statusText = 'Connected to Live Stream';
        liveState.lastEventTime = Date.now();

        // Extract initial viewers and likes from roomInfo if available
        try {
            if (state && state.roomInfo) {
                const ri = state.roomInfo;
                if (ri.user_count !== undefined) liveState.viewerCount = parseInt(ri.user_count, 10) || 0;
                else if (ri.total_user !== undefined) liveState.viewerCount = parseInt(ri.total_user, 10) || 0;
                if (ri.like_count !== undefined) liveState.totalLikes = parseInt(ri.like_count, 10) || 0;
            } else if (typeof tiktokConnection.fetchRoomInfo === 'function') {
                tiktokConnection.fetchRoomInfo().then(info => {
                    if (info) {
                        if (info.user_count !== undefined) liveState.viewerCount = parseInt(info.user_count, 10) || 0;
                        else if (info.total_user !== undefined) liveState.viewerCount = parseInt(info.total_user, 10) || 0;
                        if (info.like_count !== undefined) liveState.totalLikes = parseInt(info.like_count, 10) || 0;
                        saveState();
                        postWebhook({
                            event: 'room_viewers',
                            viewerCount: liveState.viewerCount,
                            totalLikes: liveState.totalLikes
                        });
                    }
                }).catch(() => {});
            }
        } catch (e) {}

        saveState();

        postWebhook({
            event: 'room_viewers',
            viewerCount: liveState.viewerCount,
            totalLikes: liveState.totalLikes
        });

        console.log(`[SUCCESS] Connected to TikTok LIVE! Room ID: ${state.roomId} | Viewers: ${liveState.viewerCount} | Likes: ${liveState.totalLikes}`);
        console.log(`[READY] Listening for Gifts, Likes, Follows, and Team Chat (!plants/!zombies)...`);

        // AUTOMATIC COMMUNITY / ROOM GIFTS SYNC
        try {
            if (typeof tiktokConnection.fetchAvailableGifts === 'function') {
                const roomGifts = await tiktokConnection.fetchAvailableGifts();
                if (Array.isArray(roomGifts) && roomGifts.length > 0) {
                    console.log(`[GIFTS DISCOVERY] Discovered ${roomGifts.length} available gifts for room from TikTok Webcast.`);
                    const formattedGifts = roomGifts.map(g => ({
                        id: String(g.id || ''),
                        name: g.name || '',
                        coins: g.diamond_count || g.coins || 1,
                        icon: (g.image && g.image.url_list && g.image.url_list[0]) || (g.icon) || '',
                        isCommunity: true,
                        source: 'tiktok_live_room'
                    })).filter(g => g.name && g.id);

                    postWebhook({
                        event: 'community_gifts_sync',
                        gifts: formattedGifts
                    });
                }
            }
        } catch (giftErr) {
            console.log(`[GIFTS DISCOVERY] Note on room gift fetch: ${giftErr.message}`);
        }
    }).catch(err => {
        liveState.connected = false;
        liveState.processRunning = true;
        const msg = (err && err.message) ? err.message : String(err || '');
        const msgLower = msg.toLowerCase();
        let cleanStatus = 'Waiting for Stream...';
        if (msgLower.includes('live has ended') || msgLower.includes('offline') || 
            msgLower.includes('failed to retrieve room_id') || msgLower.includes('user is offline') ||
            msgLower.includes("isn't online") || msgLower.includes('is not online') ||
            msgLower.includes('not found') || msgLower.includes('not live') ||
            msgLower.includes('user not found') || msgLower.includes('no live')) {
            cleanStatus = 'Waiting for Stream...';
            console.log(`[STANDBY] @${targetUser} is offline or not live yet. Waiting for you to Go LIVE in TikTok LIVE Studio... (Auto-retrying in 5s)`);
        } else {
            cleanStatus = 'Waiting for Stream...';
            console.log(`[STANDBY] Connection notice: ${msg}. Standing by for TikTok LIVE stream to start...`);
        }
        liveState.statusText = cleanStatus;
        saveState();
        scheduleReconnect(5000);
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

    // Unique message ID cache to drop identical socket packet retransmissions without dropping real gifts
    const recentMsgIds = new Map();
    // Track active combo streaks by user + giftId + groupId
    const activeStreaks = new Map();
    // Micro-cache to absorb raw sub-150ms socket duplicate echoes if msgId is absent
    const recentPacketSignatures = new Map();

    // 1. Gift Event Listener with Bulletproof Instant Triggering & Combo Support
    tiktokConnection.on('gift', data => {
        liveState.lastEventTime = Date.now();
        const now = Date.now();

        // 1. UNIQUE PACKET DEDUPLICATION BY MSGID:
        // TikTok live webcast provides a unique msgId on every single distinct message.
        // Dropping matching msgId within 8 seconds prevents duplicate socket retransmissions
        // WITHOUT EVER dropping a 2nd gift sent 1 second later!
        const msgId = String(
            (data.common && data.common.msgId) || 
            data.msgId || 
            data.id || 
            (data.common && data.common.createTime && `${data.giftId}_${data.common.createTime}`) ||
            ''
        ).trim();

        if (msgId) {
            if (recentMsgIds.has(msgId)) {
                return; // Exact socket retransmission duplicate
            }
            recentMsgIds.set(msgId, now);
            setTimeout(() => recentMsgIds.delete(msgId), 8000);
        }

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
        const groupId = String(data.groupId || '');

        // 2. SUB-150MS DUPLICATE SIGNATURE PROTECTION (for packets lacking msgId)
        if (!msgId) {
            const sig = `${user.toLowerCase()}_${giftId}_${totalCount}_${data.repeatEnd}`;
            const lastSigTime = recentPacketSignatures.get(sig);
            if (lastSigTime && (now - lastSigTime < 150)) {
                return; // Dropped sub-150ms socket loopback bounce
            }
            recentPacketSignatures.set(sig, now);
            setTimeout(() => recentPacketSignatures.delete(sig), 2000);
        }

        // ACCURATE STREAK / COMBO DETECTION:
        // A gift is part of an active streak if repeatEnd is explicitly defined OR repeatCount > 0
        const isStreak = Boolean(
            data.repeatEnd !== undefined ||
            data.giftType === 1 ||
            (data.repeatCount && data.repeatCount > 0) ||
            (data.giftDetails && data.giftDetails.giftType === 1) ||
            (data.extendedGiftInfo && data.extendedGiftInfo.gift_type === 1)
        );

        // Deduplication key per user and gift:
        // NEVER include groupId in the key because TikTok packet 1 often has empty groupId,
        // while packet 2 (the repeatEnd confirmation) has a numeric groupId. Keeping the key
        // strictly user + giftId ensures packet 2 is recognized as the same streak!
        const streakKey = `${user.toLowerCase()}_${giftId}`;

        let deltaCount = 0;

        if (isStreak) {
            let streak = activeStreaks.get(streakKey);
            const isEnd = Boolean(data.repeatEnd);

            if (streak) {
                const timeSinceLastTap = now - (streak.lastTime || 0);

                if (totalCount > streak.lastProcessedCount) {
                    // Streak advanced (e.g. was 1, now 2; or was 2, now 5)
                    deltaCount = totalCount - streak.lastProcessedCount;
                    streak.lastProcessedCount = totalCount;
                    streak.lastTime = now;
                    streak.isFinished = isEnd;
                } else if (totalCount < streak.lastProcessedCount) {
                    // New streak started after a higher combo ended
                    deltaCount = totalCount;
                    streak.lastProcessedCount = totalCount;
                    streak.lastTime = now;
                    streak.isFinished = isEnd;
                } else {
                    // totalCount is EQUAL to lastProcessedCount (e.g., repeatEnd echo for 1 gift)
                    if (timeSinceLastTap < 4000) {
                        // This is an echo/retransmission or repeatEnd confirmation packet! Drop it!
                        deltaCount = 0;
                        streak.lastTime = now;
                        if (isEnd) streak.isFinished = true;
                    } else {
                        // More than 4 seconds elapsed: legitimate brand new gift send
                        deltaCount = totalCount;
                        streak.lastProcessedCount = totalCount;
                        streak.lastTime = now;
                        streak.isFinished = isEnd;
                    }
                }
            } else {
                // First packet of this streak
                deltaCount = totalCount;
                streak = {
                    lastProcessedCount: totalCount,
                    lastTime: now,
                    isFinished: isEnd,
                    cleanupTimer: null
                };
                activeStreaks.set(streakKey, streak);
            }

            // Keep streak in memory for 5 seconds to absorb late repeatEnd confirmation echos
            if (streak.cleanupTimer) {
                clearTimeout(streak.cleanupTimer);
            }
            streak.cleanupTimer = setTimeout(() => {
                activeStreaks.delete(streakKey);
            }, 5000);

            // If deltaCount is 0, this packet is an end-of-streak confirmation echo with no new gifts
            if (deltaCount <= 0) {
                const dropMsg = `[${new Date().toLocaleTimeString()}] DROPPED DUPLICATE: ${user} streak echo for ${giftName} (streak: ${totalCount}, repeatEnd: ${!!data.repeatEnd}, already executed: ${streak.lastProcessedCount}x)\n`;
                try { fs.appendFileSync(path.join(__dirname, 'tiktok_gifts_debug.log'), dropMsg, 'utf8'); } catch (e) {}
                return;
            }
        } else {
            // Non-streak gift:
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
            msgId: msgId,
            groupId: groupId,
            giftId: giftId,
            giftName: giftName,
            repeatCount: deltaCount,
            totalRepeatCount: totalCount,
            coins: deltaCoins,
            diamondCount: unitCoins,
            username: user,
            avatarUrl: userAvatar,
            giftPictureUrl: giftPic,
            repeatEnd: Boolean(data.repeatEnd),
            isStreak: isStreak
        };

        const logMsg = `[${new Date().toLocaleTimeString()}] GIFT: ${user} sent ${deltaCount}x ${giftName} (ID: ${giftId}, ${unitCoins} coins each = ${deltaCoins} coins, streak: ${totalCount}, repeatEnd: ${!!data.repeatEnd})\n`;
        console.log(logMsg.trim());
        try { fs.appendFileSync(path.join(__dirname, 'tiktok_gifts_debug.log'), logMsg, 'utf8'); } catch (e) {}

        postWebhook(payload);
        saveState();
    });

    // 2. Like Event (Real-time accumulation & Webhook dispatch)
    tiktokConnection.on('like', data => {
        liveState.lastEventTime = Date.now();
        const incomingLikes = parseInt(data.likeCount || 1, 10) || 1;
        const totalLikesFromData = data.totalLikeCount !== undefined ? parseInt(data.totalLikeCount, 10) :
                                  (data.total !== undefined ? parseInt(data.total, 10) :
                                  (data.totalLikes !== undefined ? parseInt(data.totalLikes, 10) : undefined));

        if (totalLikesFromData !== undefined && totalLikesFromData > 0) {
            liveState.totalLikes = totalLikesFromData;
        } else {
            liveState.totalLikes = (liveState.totalLikes || 0) + incomingLikes;
        }

        const user = extractUserName(data);
        const userAvatar = extractAvatarUrl(data);
        const payload = {
            event: 'like',
            likeCount: incomingLikes,
            totalLikeCount: liveState.totalLikes,
            totalLikes: liveState.totalLikes,
            viewerCount: liveState.viewerCount,
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

    // 6. Viewer Join / Member Event
    tiktokConnection.on('member', data => {
        liveState.lastEventTime = Date.now();
        const user = extractUserName(data);
        const userAvatar = extractAvatarUrl(data);
        const uniqueId = data.uniqueId || (data.user && data.user.uniqueId) || (data.userDetails && data.userDetails.uniqueId) || '';

        const payload = {
            event: 'join',
            username: user || uniqueId || 'Viewer',
            uniqueId: uniqueId,
            avatar: userAvatar,
            timestamp: Date.now()
        };

        console.log(`>>> [MEMBER JOIN] @${payload.username} joined the stream!`);
        postWebhook(payload);
        saveState();
    });

    // 7. Room Viewers (Real-time Webcast Room User updates)
    tiktokConnection.on('roomUser', data => {
        liveState.lastEventTime = Date.now();
        const vCount = data.viewerCount !== undefined ? data.viewerCount : 
                      (data.userCount !== undefined ? data.userCount : 
                      (data.totalUser !== undefined ? data.totalUser : 
                      (data.total !== undefined ? data.total : 
                      (data.count !== undefined ? data.count : 
                      (Array.isArray(data.ranksList) ? data.ranksList.length : 
                      (Array.isArray(data.topViewers) ? data.topViewers.length : undefined))))));
        if (vCount !== undefined) {
            liveState.viewerCount = parseInt(vCount, 10) || 0;
            saveState();
            postWebhook({
                event: 'room_viewers',
                viewerCount: liveState.viewerCount,
                totalLikes: liveState.totalLikes
            });
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
            try { 
                if (typeof tiktokConnection.removeAllListeners === 'function') {
                    tiktokConnection.removeAllListeners();
                }
                tiktokConnection.disconnect(); 
            } catch (e) {}
            tiktokConnection = null;
        }
        startConnection();
    }, delayMs);
}

// Prevent crash from unhandled errors
process.on('uncaughtException', (err) => {
    console.error(`[UNCAUGHT ERROR] ${err.message}`);
    liveState.processRunning = true;
    liveState.statusText = 'Waiting for TikTok LIVE stream to start (recovering from error)...';
    saveState();
    scheduleReconnect(5000);
});

process.on('unhandledRejection', (reason) => {
    console.error(`[UNHANDLED REJECTION] ${reason}`);
    liveState.processRunning = true;
    liveState.statusText = 'Waiting for TikTok LIVE stream to start (recovering from error)...';
    saveState();
    scheduleReconnect(5000);
});

// Clean exit handling
process.on('SIGINT', () => {
    liveState.connected = false;
    liveState.processRunning = false;
    liveState.statusText = 'Stopped';
    saveState();
    if (tiktokConnection) {
        try { tiktokConnection.disconnect(); } catch (e) {}
    }
    process.exit(0);
});

startConnection();
