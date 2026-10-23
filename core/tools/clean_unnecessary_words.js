const fs = require('fs');
const path = require('path');

// 1. Clean app.html
const appHtmlPath = path.join(__dirname, '..', 'app.html');
let appHtml = fs.readFileSync(appHtmlPath, 'utf8');

const appReplacements = [
    [/title="Import events or triggers from S2E, TikFinity, and other applications"/g, 'title="Import events or triggers from TikFinity, JSON, and preset files"'],
    [/title="Export triggers to JSON for S2E or other applications"/g, 'title="Export triggers to JSON file or preset"'],
    [/title="Allow this event\/trigger to be imported or shared across applications like S2E"/g, 'title="Allow this event/trigger to be imported or shared"'],
    [/title="Enable to allow this event to be imported into any application like S2E and other apps"/g, 'title="Enable to allow this event to be imported into other apps or presets"'],
    [/Import triggers and summon actions from <strong>S2E \/ TikFinity<\/strong>/g, 'Import triggers and summon actions from <strong>TikFinity or Preset JSON</strong>'],
    [/placeholder=['"]Paste S2E Event Code \(e\.g\. 6ab90a09802d615caa9b8877\) or full S2E JSON payload\.\.\.['"]/g, "placeholder='Paste Preset Code (e.g. 6ab90a09802d615caa9b8877) or JSON payload...'"],
    [/🎯 S2E Ice Cream \(Snow Monster\)/g, '🎯 Preset: Ice Cream (Snow Monster)'],
    [/🎯 S2E 50K Likes Milestone/g, '🎯 Preset: 50K Likes Milestone'],
    [/Share code and JSON schema compatible with <strong>S2E \/ TikFinity<\/strong>/g, 'Share code and JSON schema compatible with <strong>Live Stream Studio & TikFinity</strong>'],
    [/<span>🎯 S2E Share \/ Preset Code \(24-Hex\)<\/span>/g, '<span>🎯 Preset Share Code (24-Hex)</span>'],
    [/onclick="setSliceCategory\('all'\)">All \/ S2E \(Recommended\)<\/button>/g, 'onclick="setSliceCategory(\'all\')">All Cards (Recommended)</button>'],
    [/title="Import Allowed: Any app like S2E can import or trigger this event"/g, 'title="Import Allowed: Presets can import or trigger this event"'],
    [/title="Export \/ Copy Event for S2E or other apps"/g, 'title="Export / Copy Event"'],
    [/engineStatus\.innerText = 'MelonLoader \+ Runetify Mod Linked & Active';/g, "engineStatus.innerText = 'MelonLoader + RENEarn In-Game Mod Linked & Active';"],
    [/badge\.innerText = 'S2E Code';/g, "badge.innerText = 'Preset Code';"],
    [/<span>⏳<\/span> Resolving RENEarn \(S2E\) Code: <code>\$\{s2eCode\}<\/code>\.\.\./g, '<span>⏳</span> Resolving Preset Code: <code>${s2eCode}</code>...'],
    [/<strong>S2E Code detected:<\/strong> <code>\$\{s2eCode\}<\/code><br>Preset not found on RENEarn cloud or local database\. If you have the raw event JSON from S2E, you can paste it directly\./g, '<strong>Preset Code detected:</strong> <code>${s2eCode}</code><br>Preset not found on cloud or local database. If you have the raw event JSON, you can paste it directly.'],
    [/Failed to resolve S2E code: /g, 'Failed to resolve preset code: '],
    [/showToast\("Copied S2E Code to clipboard: " \+ code, "OK"\);/g, 'showToast("Copied Preset Code to clipboard: " + code, "OK");'],
    [/showToast\("Copied S2E JSON payload to clipboard!", "OK"\);/g, 'showToast("Copied Preset JSON to clipboard!", "OK");'],
    [/showToast\("Downloaded S2E preset JSON file!", "OK"\);/g, 'showToast("Downloaded preset JSON file!", "OK");']
];

let appModified = 0;
for (const [pattern, replacement] of appReplacements) {
    if (pattern.test(appHtml)) {
        appHtml = appHtml.replace(pattern, replacement);
        appModified++;
    }
}
fs.writeFileSync(appHtmlPath, appHtml, 'utf8');
console.log(`app.html: Replaced ${appModified} occurrences.`);

// 2. Clean overlay-side.html
const sidePath = path.join(__dirname, '..', 'overlay-side.html');
if (fs.existsSync(sidePath)) {
    let sideHtml = fs.readFileSync(sidePath, 'utf8');
    const oldText = "Icons Only (S2E)";
    if (sideHtml.includes(oldText)) {
        sideHtml = sideHtml.replace(/Icons Only \(S2E\)/g, 'Icons Only');
        fs.writeFileSync(sidePath, sideHtml, 'utf8');
        console.log('overlay-side.html: Cleaned Icons Only (S2E)');
    }
}

// 3. Clean s2e-overlay.html title
const s2ePath = path.join(__dirname, '..', 's2e-overlay.html');
if (fs.existsSync(s2ePath)) {
    let s2eHtml = fs.readFileSync(s2ePath, 'utf8');
    if (s2eHtml.includes('<title>StreamToEarn PvZ TikTok LIVE Overlay</title>')) {
        s2eHtml = s2eHtml.replace('<title>StreamToEarn PvZ TikTok LIVE Overlay</title>', '<title>RENEarn Live Stream Overlay</title>');
        fs.writeFileSync(s2ePath, s2eHtml, 'utf8');
        console.log('s2e-overlay.html: Cleaned title');
    }
}
