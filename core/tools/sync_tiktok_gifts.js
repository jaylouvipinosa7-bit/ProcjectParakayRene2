const { TikTokLiveConnection } = require('tiktok-live-connector');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const GIFTS_DIR = path.join(__dirname, 'images', 'tiktok-gifts');
const VERIFIED_JSON_PATH = path.join(__dirname, 'tiktok_gifts_verified.json');
const CATALOG_PATH = path.join(__dirname, 'pvz_units_catalog.json');

if (!fs.existsSync(GIFTS_DIR)) {
    fs.mkdirSync(GIFTS_DIR, { recursive: true });
}

function downloadFile(url, destPath) {
    return new Promise((resolve, reject) => {
        if (!url || !url.startsWith('http')) return resolve(null);
        const protocol = url.startsWith('https') ? https : http;
        const file = fs.createWriteStream(destPath);
        
        const req = protocol.get(url, (res) => {
            if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
                return downloadFile(res.headers.location, destPath).then(resolve).catch(reject);
            }
            if (res.statusCode !== 200) {
                file.close();
                fs.unlink(destPath, () => {});
                return resolve(null);
            }
            res.pipe(file);
            file.on('finish', () => {
                file.close(() => resolve(destPath));
            });
        });
        
        req.on('error', (err) => {
            file.close();
            fs.unlink(destPath, () => {});
            resolve(null);
        });
        
        req.setTimeout(8000, () => {
            req.abort();
            file.close();
            fs.unlink(destPath, () => {});
            resolve(null);
        });
    });
}

function slugify(name) {
    return (name || '')
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '') || 'gift';
}

async function main() {
    console.log('=== Syncing All TikTok LIVE Gifts ===');
    
    // 1. Fetch official gifts from TikTok Live Connector
    let rawGifts = [];
    try {
        const conn = new TikTokLiveConnection('gohanmalunggay');
        rawGifts = await conn.fetchAvailableGifts();
        console.log(`Successfully fetched ${rawGifts.length} gifts from TikTok LIVE Connector.`);
    } catch (err) {
        console.warn('Could not fetch online gifts:', err.message);
    }

    // 2. Load existing verified gifts
    let existingGifts = [];
    if (fs.existsSync(VERIFIED_JSON_PATH)) {
        try {
            existingGifts = JSON.parse(fs.readFileSync(VERIFIED_JSON_PATH, 'utf8'));
        } catch (e) {}
    }

    // 3. Scan local files in images/tiktok-gifts
    const localFiles = fs.readdirSync(GIFTS_DIR);
    const localFileMap = new Map();
    for (const f of localFiles) {
        const idMatch = f.match(/^(\d+)_/);
        if (idMatch) {
            localFileMap.set(idMatch[1], `images/tiktok-gifts/${f}`);
        }
    }

    // Gift map by ID
    const giftsMap = new Map();

    // Add existing verified gifts first
    for (const g of existingGifts) {
        if (g && g.id) {
            giftsMap.set(String(g.id), {
                id: String(g.id),
                name: g.name,
                coins: parseInt(g.coins) || 1,
                icon: g.icon,
                cdnIcon: g.cdnIcon || g.icon
            });
        }
    }

    // Add / update with online TikTok gifts
    for (const g of rawGifts) {
        if (!g || !g.id || !g.name) continue;
        const gId = String(g.id);
        const name = g.name.trim();
        const coins = parseInt(g.diamond_count) || 1;
        const cdnUrl = (g.image && g.image.url_list && g.image.url_list[0]) ||
                       (g.icon && g.icon.url_list && g.icon.url_list[0]) || '';
        
        let iconPath = '';
        if (localFileMap.has(gId)) {
            iconPath = localFileMap.get(gId);
        } else {
            // Check if existing map has a local path
            if (giftsMap.has(gId) && giftsMap.get(gId).icon && giftsMap.get(gId).icon.startsWith('images/')) {
                iconPath = giftsMap.get(gId).icon;
            }
        }

        giftsMap.set(gId, {
            id: gId,
            name: name,
            coins: coins,
            icon: iconPath || cdnUrl,
            cdnIcon: cdnUrl
        });
    }

    // Ensure essential special presets exist (Perfume, Doughnut, Rose, etc.)
    if (!giftsMap.has('perfume')) {
        giftsMap.set('perfume', {
            id: 'perfume',
            name: 'Perfume',
            coins: 20,
            icon: 'images/tiktok-gifts/perfume_gift.webp',
            cdnIcon: 'images/tiktok-gifts/perfume_gift.webp'
        });
    }
    if (!giftsMap.has('5879')) {
        giftsMap.set('5879', {
            id: '5879',
            name: 'Doughnut',
            coins: 30,
            icon: 'images/tiktok-gifts/5879_doughnut.webp',
            cdnIcon: 'images/tiktok-gifts/5879_doughnut.webp'
        });
    }

    // 4. Download missing icons for key gifts, especially the 1-coin, popular and photo gifts
    const giftsList = Array.from(giftsMap.values());
    console.log(`Total unique TikTok gifts to process: ${giftsList.length}`);

    // Download in parallel with concurrency limit
    const CONCURRENCY = 10;
    let downloadedCount = 0;

    const toDownload = giftsList.filter(g => {
        // Needs download if icon is still a remote URL and cdnIcon is available
        return (!g.icon || g.icon.startsWith('http')) && g.cdnIcon && g.cdnIcon.startsWith('http');
    });

    console.log(`Gifts needing local image download: ${toDownload.length}`);

    // Download batch
    for (let i = 0; i < toDownload.length; i += CONCURRENCY) {
        const batch = toDownload.slice(i, i + CONCURRENCY);
        await Promise.all(batch.map(async (g) => {
            const slug = slugify(g.name);
            const fileName = `${g.id}_${slug}.webp`;
            const destPath = path.join(GIFTS_DIR, fileName);

            if (fs.existsSync(destPath) && fs.statSync(destPath).size > 100) {
                g.icon = `images/tiktok-gifts/${fileName}`;
                return;
            }

            try {
                const res = await downloadFile(g.cdnIcon, destPath);
                if (res && fs.existsSync(destPath) && fs.statSync(destPath).size > 100) {
                    g.icon = `images/tiktok-gifts/${fileName}`;
                    downloadedCount++;
                } else {
                    g.icon = g.cdnIcon; // fallback to CDN url
                }
            } catch (e) {
                g.icon = g.cdnIcon;
            }
        }));
    }

    console.log(`Downloaded ${downloadedCount} new gift icons locally.`);

    // 5. Popular gifts priority list (shows at top of their coin tier)
    const POPULAR_GIFTS = [
        'Rose', 'TikTok', "You're awesome", 'Ice Cream Cone', 'GG', 'Mate Melody',
        'Love you so much', 'Clap Clap', 'Wink wink', 'Cake Slice', 'Good Job',
        'Welcome Dallah', 'Pop', 'Glow Stick', 'A Shard of Hope', 'Heart Me',
        'Finger Heart', 'Fire', 'Bibingka', 'Freestyle', 'Oldies', 'SEA Shell',
        'Treasure Clover', 'Perfume', 'Doughnut', 'Blossom Po', 'Rosa', 'Star Light',
        'Divine Fingers', 'I love you', 'Friendship Necklace', 'Kudos for My Star',
        'Hat and Mustache', 'Sunglasses', 'Corgi', 'Fruit Friends', 'Boxing Gloves',
        'Money Gun', 'Galaxy', 'Fireworks', 'Lion', 'TikTok Universe'
    ];

    const popRank = new Map();
    POPULAR_GIFTS.forEach((p, idx) => popRank.set(p.toLowerCase(), idx));

    giftsList.sort((a, b) => {
        if (a.coins !== b.coins) return a.coins - b.coins;
        const rA = popRank.has(a.name.toLowerCase()) ? popRank.get(a.name.toLowerCase()) : 999;
        const rB = popRank.has(b.name.toLowerCase()) ? popRank.get(b.name.toLowerCase()) : 999;
        if (rA !== rB) return rA - rB;
        return a.name.localeCompare(b.name);
    });

    // 6. Save updated tiktok_gifts_verified.json
    fs.writeFileSync(VERIFIED_JSON_PATH, JSON.stringify(giftsList, null, 2), 'utf8');
    console.log(`Saved ${giftsList.length} gifts to tiktok_gifts_verified.json`);

    // 7. Update pvz_units_catalog.json
    if (fs.existsSync(CATALOG_PATH)) {
        try {
            let catRaw = fs.readFileSync(CATALOG_PATH, 'utf8').replace(/^\uFEFF/, '');
            const catalog = JSON.parse(catRaw);
            catalog.tiktokGifts = giftsList;
            fs.writeFileSync(CATALOG_PATH, JSON.stringify(catalog, null, 2), 'utf8');
            console.log(`Updated pvz_units_catalog.json with all ${giftsList.length} TikTok gifts.`);
        } catch (e) {
            console.error('Failed to update catalog:', e);
        }
    }

    console.log('=== Finished TikTok Gifts Sync! ===');
}

main().catch(console.error);
