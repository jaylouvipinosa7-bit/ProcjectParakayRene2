const fs = require('fs');
const html = fs.readFileSync('core/app.html', 'utf8');
const scriptRegex = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
let match;
let count = 0;
let errors = 0;
while ((match = scriptRegex.exec(html)) !== null) {
    count++;
    const code = match[1];
    if (!code.trim()) continue;
    try {
        new Function(code);
        console.log(`Script block ${count}: OK`);
    } catch (err) {
        errors++;
        console.error(`Script block ${count} ERROR:`, err.message);
        const upToMatch = html.substring(0, match.index);
        const startLine = upToMatch.split('\n').length;
        console.error(`Starts at line ${startLine} in core/app.html`);
        fs.writeFileSync(`core/tools/err_script_${count}.js`, code);
    }
}
console.log(`Checked ${count} script blocks. Total errors: ${errors}`);
if (errors > 0) process.exit(1);
