const { app, BrowserWindow, shell, globalShortcut } = require('electron');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

let mainWindow = null;
let serverProcess = null;

let lastAdjustTime = 0;
let lastAdjustAction = '';

function sendAdjust(action) {
    const now = Date.now();
    if (action === lastAdjustAction && (now - lastAdjustTime) < 350) {
        return; // Debounce rapid duplicate trigger
    }
    lastAdjustTime = now;
    lastAdjustAction = action;

    try {
        const postData = JSON.stringify({ action });
        const req = http.request({
            hostname: '127.0.0.1',
            port: 8080,
            path: '/api/win-widget/adjust',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        });
        req.on('error', () => {});
        req.write(postData);
        req.end();
    } catch (e) {}
}

function startBackendServer() {
    const scriptPath = path.join(__dirname, 'server.ps1');
    serverProcess = spawn('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath
    ], {
        cwd: __dirname,
        stdio: 'ignore',
        windowsHide: true
    });

    serverProcess.on('error', (err) => {
        console.error('Failed to start server:', err);
    });
}

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 1024,
        minHeight: 700,
        title: 'PvZ Fusion 4.0 - Live Stream Control Studio',
        icon: path.join(__dirname, 'images', 'super_gargantuar.png'),
        backgroundColor: '#070a0d',
        autoHideMenuBar: true,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true
        }
    });

    // Wait 1.5 seconds for backend server to bind port 8080
    setTimeout(() => {
        mainWindow.loadURL('http://localhost:8080/app.html');
    }, 1500);

    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

app.whenReady().then(() => {
    startBackendServer();
    createWindow();

    // Register system-wide global shortcuts so streamers can press Alt+- and Alt+= while in-game!
    try { globalShortcut.register('Alt+-', () => sendAdjust('lose_plus')); } catch (e) {}
    try { globalShortcut.register('Alt+=', () => sendAdjust('win_plus')); } catch (e) {}
    try { globalShortcut.register('Alt+NumSub', () => sendAdjust('lose_plus')); } catch (e) {}
    try { globalShortcut.register('Alt+NumAdd', () => sendAdjust('win_plus')); } catch (e) {}

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('will-quit', () => {
    try {
        globalShortcut.unregisterAll();
    } catch (e) {}
});

app.on('window-all-closed', () => {
    if (serverProcess) {
        try {
            serverProcess.kill();
        } catch (e) {}
    }
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
