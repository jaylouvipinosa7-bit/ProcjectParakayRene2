const { app, BrowserWindow, shell } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow = null;
let serverProcess = null;

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

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
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
