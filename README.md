# 🌻 PvZ Fusion 4.0 - Live Stream Control Studio

> **Version 1.0.0 Official Release**  
> Complete interactive streaming engine connecting **TikTok LIVE**, **OBS Studio**, and **Plants vs. Zombies Fusion**.

---

## 📖 Overview

**PvZ Fusion Studio** is a native Windows streaming companion application built for content creators streaming *Plants vs. Zombies Fusion*. When viewers send gifts, likes, or chat commands on TikTok LIVE, the app triggers in-game plant & zombie spawns, animates dynamic OBS stream overlays, tracks win/loss goals, and runs spammable prize spinners.

---

## 🚀 Quick Start Setup Guide

### 1. Launching the Studio
You have three convenient ways to launch the app:
- **Desktop Shortcut**: Double-click `Create_Desktop_Shortcut.bat` once to place an official **PvZ Fusion Studio** icon on your Windows desktop.
- **Direct Executable**: Double-click **`PvZ_Fusion_Studio.exe`** to launch the standalone desktop window silently.
- **Batch Launcher**: Double-click **`Launch_Studio.bat`** as an alternative launcher.

### 2. Connect Your TikTok LIVE Stream
1. Open the studio dashboard (`http://localhost:8080/app.html` or through the desktop app).
2. Enter your TikTok channel username (e.g. `@yourusername`) in the top connection bar.
3. Click **"Connect TikTok & Start Stream"**.
4. Once connected, viewer gifts and chat messages will stream directly into the app in real time!

### 3. Hook into Plants vs. Zombies Fusion
1. Launch **Plants vs. Zombies Fusion** on your PC.
2. The studio automatically detects the running game process and displays **`PvZ Fusion: Connected`** in the status bar.
3. Spawns, powers, and win conditions are injected seamlessly during gameplay.

---

## 🎥 OBS Studio Overlay Setup

Add these **Browser Sources** in OBS Studio to show interactive visuals on your stream:

| Overlay Feature | Browser Source URL | Recommended Size | Notes |
|---|---|---|---|
| **Gift Reel Spinner** | `http://localhost:8080/overlay-spinner.html` | 1920 × 1080 | 100% transparent when idle; slides in dynamically on gifts |
| **Win Fraction Trophy** | `http://localhost:8080/overlay-win.html` | 500 × 500 | Shows score fraction (e.g. `-3 / 5`) and trophy cup |
| **Full Gift Card Grid** | `http://localhost:8080/overlay-grid.html` | 1920 × 1080 | Interactive TikTok gift catalog for your stream |
| **Classic Gift Bar** | `http://localhost:8080/overlay.html` | 1920 × 300 | Stream bottom bar displaying gift cards |

### OBS Browser Source Configuration Tips:
1. In OBS, click **`+`** under Sources $\rightarrow$ select **Browser**.
2. Paste the desired URL from the table above.
3. Check the box **"Shutdown source when not visible"**.
4. Check **"Refresh browser when scene becomes active"**.
5. Custom CSS: Leave blank or set `body { background: transparent !important; }`.

---

## ✨ Key Features

### 1. Manual Editable LOSE & WIN Counters
- **Direct Manual Editing**: Click directly inside the dark rounded boxes on the **LOSE** and **WIN** cards and write any number directly (e.g. `6756` losses, `600` wins).
- **Auto-Save**: Press <kbd>Enter</kbd> or click away; the new value is instantly saved to `win_widget_state.json`.
- **Quick Buttons**: Use the `[−]` and `[+]` split buttons below each card for quick incremental changes.
- **Hotkeys**:
  - <kbd>Alt</kbd> + <kbd>-</kbd> or <kbd>[</kbd> $\rightarrow$ Add 1 Loss / Deduct Score
  - <kbd>Alt</kbd> + <kbd>=</kbd> or <kbd>]</kbd> $\rightarrow$ Add 1 Win / Add Score

### 2. Spammable Spinners with Queue System
- **No Dropped Spins**: When multiple viewers send gifts simultaneously or a viewer spams gifts, all spins are queued into the queue system without getting dropped.
- **Queue Status Display**: Displays `Queue: <N>` on the top-left of the spinner reel.
- **Stop Spinner Button**: Click the red **`Stop Spinner`** button on the top-right to instantly clear the queue and cancel spinning.
- **Adaptive Speed**: When multiple spins are queued, post-spin celebration hold times automatically accelerate to **1.2 seconds** so waiting viewers get their turn quickly.

### 3. Pointer Indicator with User Avatar
- **Yellow Triangle Pointer**: A vibrant golden yellow inverted triangle (`▼`) pointing down into the winning card.
- **Embedded User Profile Avatar**: The upper circle of the triangle displays the profile picture/avatar of the person who spun the wheel.
- **Username Badge**: Displays an `@Username` pill above the pointer.

### 4. Spinner History Log & Statistics
- Real-time history card feed logging every spin outcome.
- Shows timestamp, gifter username, profile avatar, prize label, and item icon.
- Full support for test spins logged under your tester profile.

### 5. Multi-PC (LAN) Streaming Support
- If your PvZ game is on your Gaming PC and OBS is on a separate Streaming PC:
  - In the dashboard, use the **Host Switcher** button `[ Stream PC (LAN IP) ]` to copy your network IP (e.g. `http://192.168.1.50:8080/overlay-spinner.html`).
  - Works seamlessly across all devices on the same local network!

---

## ⌨️ Hotkeys Reference

| Shortcut | Action | Description |
|---|---|---|
| <kbd>Alt</kbd> + <kbd>-</kbd> | **Add Loss** | Increments losses by 1 and adjusts fraction score |
| <kbd>Alt</kbd> + <kbd>=</kbd> | **Add Win** | Increments wins by 1 and adjusts fraction score |
| <kbd>[</kbd> | **Add Loss (Single Key)** | Alternative shortcut for game controllers/macro pads |
| <kbd>]</kbd> | **Add Win (Single Key)** | Alternative shortcut for game controllers/macro pads |
| <kbd>T</kbd> | **Test Random Spin** | Tests the horizontal gift reel in overlay mode |
| <kbd>1</kbd> | **Test Plants Spinner** | Triggers Plants reel spin |
| <kbd>2</kbd> | **Test Zombies Spinner** | Triggers Zombies reel spin |
| <kbd>3</kbd> | **Test Points (+/-) Spinner** | Triggers score delta spinner |

---

## 📁 Repository & Folder Structure

```text
├── PvZ_Fusion_Studio.exe          # Official native desktop executable
├── Create_Desktop_Shortcut.bat    # 1-Click desktop shortcut creator
├── Launch_Studio.bat              # Studio launcher script
├── PUSH_TO_GITHUB.bat             # 1-Click GitHub publisher
├── app_icon.ico                   # Multi-resolution app icon
├── README.md                      # Setup and usage guide (this file)
├── DISTRIBUTION_GUIDE.md          # Creator distribution instructions
└── core/                          # Internal engine files
    ├── app.html                   # Streamer Control Dashboard
    ├── overlay-spinner.html       # OBS Gift Reel Overlay with Avatar Pointer
    ├── overlay-win.html           # OBS Win Fraction & Trophy Overlay
    ├── overlay-grid.html          # OBS Gift Catalog Grid Overlay
    ├── server.ps1                 # High-performance HTTP server engine
    ├── win_widget_state.json      # Persistent win/loss counters
    ├── spinner_history.json       # Persistent spin history records
    ├── pvz_fusion_config.json     # Streamer configuration & gift mapping
    └── images/                    # Game icons, gifts, and UI graphics
```

---

## 🛠️ Troubleshooting & FAQ

- **Port 8080 already in use?**  
  If another program uses port 8080, close it before launching `PvZ_Fusion_Studio.exe` or `Launch_Studio.bat`.
- **TikTok chat not connecting?**  
  Make sure your TikTok account is currently **LIVE**. TikTok LIVE chat bridges can only connect while the stream is active.
- **Overlays have a black background in OBS?**  
  In OBS, make sure your browser source dimensions match (e.g. Width: 1920, Height: 1080), and ensure "Custom CSS" is empty or has a transparent background.
- **Game units not spawning?**  
  Ensure Plants vs. Zombies Fusion is running before or after the studio starts. The status indicator in the top right will display **`Connected`**.

---

## 📦 Version History

- **v1.0.0 (Latest Release)**:
  - Added direct manual editable numbers for WIN and LOSE cards.
  - Implemented spammable spinner queue system with `Queue: <N>` display and red `[Stop Spinner]` button.
  - Implemented downward yellow triangle pointer with embedded circular user avatar and `@Username` badge.
  - Added real-time spinner history tracking with persistence.
  - Added hotkey debounce prevention (fixing double points issue).
  - Standalone desktop app packaging with custom `.ico` and system tray support.

---

Developed for the **Plants vs. Zombies Fusion Live Streaming Community** 🌻🧟‍♂️
