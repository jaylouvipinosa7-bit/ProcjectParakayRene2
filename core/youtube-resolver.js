const https = require('https');

function searchYouTube(query) {
    return new Promise((resolve) => {
        if (!query) return resolve({ videoId: null });
        const cleanQuery = query.replace(/^!(play|sr|request)\s+/i, '').trim();
        const q = encodeURIComponent(cleanQuery + ' audio');
        const url = `https://www.youtube.com/results?search_query=${q}`;
        
        let resolved = false;
        const req = https.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9'
            },
            timeout: 4500
        }, (res) => {
            let html = '';
            res.on('data', chunk => {
                if (resolved) return;
                html += chunk;
                const m = html.match(/"videoId":"([a-zA-Z0-9_-]{11})"/);
                if (m) {
                    resolved = true;
                    req.destroy();
                    const titleMatch = html.match(/"title":{"runs":\[{"text":"([^"]+)"}\]/);
                    resolve({
                        videoId: m[1],
                        title: titleMatch ? titleMatch[1] : null
                    });
                }
            });
            res.on('end', () => {
                if (!resolved) {
                    resolved = true;
                    const m = html.match(/"videoId":"([a-zA-Z0-9_-]{11})"/);
                    const titleMatch = html.match(/"title":{"runs":\[{"text":"([^"]+)"}\]/);
                    resolve({
                        videoId: m ? m[1] : null,
                        title: titleMatch ? titleMatch[1] : null
                    });
                }
            });
        });

        req.on('error', () => {
            if (!resolved) { resolved = true; resolve({ videoId: null }); }
        });
        req.on('timeout', () => {
            req.destroy();
            if (!resolved) { resolved = true; resolve({ videoId: null }); }
        });
    });
}

if (require.main === module) {
    const q = process.argv.slice(2).join(' ');
    searchYouTube(q).then(res => {
        process.stdout.write(JSON.stringify(res || { videoId: null }));
    });
}

module.exports = { searchYouTube };
