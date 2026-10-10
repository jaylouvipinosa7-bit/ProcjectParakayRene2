# PvZ Fusion 4.0 - Live Stream Control Studio
## Official Desktop App & Distribution Guide

Your studio is now a **real native Windows desktop application** with its own official app icon (`.ico`), desktop shortcut, and executable (`.exe`), just like Runetify, S2E, or Discord!

---

### 1. The Official Windows Application (`PvZ_Fusion_Studio.exe`)

Inside this folder, you now have:
- **`PvZ_Fusion_Studio.exe`**: The official compiled executable with the custom Gatling Peashooter live broadcast app icon embedded.
- **`app_icon.ico`**: Multi-resolution Windows icon (256x256, 128x128, 64x64, 48x48, 32x32, 16x16).
- **`Create_Desktop_Shortcut.bat`**: Creates an official shortcut on your Windows Desktop titled **`PvZ Fusion Studio`** with the custom icon.

#### How It Works:
- When you double-click **`PvZ_Fusion_Studio.exe`**:
  1. It starts the background stream engine silently (no black terminal windows).
  2. It launches an **isolated, standalone app window** (just like YouTube, Spotify, or Facebook desktop apps — no address bars, no browser clutter).
  3. It places an official icon in your Windows **System Tray** (bottom-right near your clock) where you can easily open overlays, re-open the dashboard, or exit the studio with one click.

---

### 2. How to Share It With Other Streamers (Downloadable by Others)

To make it downloadable by others:

1. **Create a Download ZIP**:
   - Right-click this folder (`ano na` or rename it to `PvZ_Fusion_Studio`) $\rightarrow$ **Send to** $\rightarrow$ **Compressed (zipped) folder**.
   - Name it: **`PvZ_Fusion_Studio_v4.0.zip`**.
2. **Upload & Share**:
   - Upload the `.zip` to **Google Drive**, **MediaFire**, **Mega.nz**, or your Discord channel.
3. **What Other Streamers Do When They Download It**:
   - They download and extract `PvZ_Fusion_Studio_v4.0.zip`.
   - They double-click **`PvZ_Fusion_Studio.exe`** (or double-click **`Create_Desktop_Shortcut.bat`** to put it on their desktop).
   - The studio opens instantly in an official desktop window!
   - They enter their TikTok `@username`, click **Connect**, and add the OBS browser source:
     - `http://localhost:8080/overlay.html`
     - `http://localhost:8080/stream-overlay.html`
   - Done! That's literally all they have to do. No installation of Node.js or programming required.

---

### 3. File Summary (Clean One-Folder App Structure)
| File / Folder | Description |
|---|---|
| **`PvZ_Fusion_Studio.exe`** | **Official native executable with custom icon & system tray manager** |
| **`Create_Desktop_Shortcut.bat`** | **One-click adds the official PvZ Studio icon to the Windows desktop** |
| **`Launch_Studio.bat`** | **Alternative quick launcher script** |
| **`DISTRIBUTION_GUIDE.md`** | **Setup and distribution guide** |
| **`app_icon.ico`** | **Official multi-resolution Windows app icon** |
| **`core/`** | **All internal app files, server, HTML overlays, gift configs, and assets are tucked cleanly here** |

---

### 4. TikTok Login & Google Account Authentication

- **Dual Streamer Login System**:
  - **TikTok Login**: Streamers can connect directly using their TikTok username (e.g., `@your_username` or their own channel). Clicking **"Connect TikTok & Start Stream"** automatically logs them in and links the live chat bridge!
  - **Google Login**: Streamers can also sign in securely with their Google account (`@gmail.com`).
- **Clean Workspace For New Users**: Each new streamer starts with a completely clean, empty customization canvas (`gifts: []`). No unwanted pre-filled plants or zombies will appear on their dashboard — they build their own setup!
- **Starter Template Option**: If a streamer wants the 64 standard Plants vs Zombies presets, they can click **`Load Starter Template (64 Gifts)`** at any time.
- **Per-User Isolation**: Every streamer's configuration is saved in an isolated user file (`user_configs/<user>_config.json`), so multiple streamers sharing the app never overwrite each other.

---

### 5. Overlay Host & Streaming Across 2 PCs / Other People

- **"Is the overlay only working for me or also for other people?"**
  - **Single PC Setup** (PvZ game, OBS, and Studio on the same PC):
    Use **`http://localhost:8080/overlay-grid.html`** or **`http://localhost:8080/overlay.html`**.
  - **Dual-PC / Streaming PC Setup** (PvZ game on Gaming PC, OBS on a separate Streaming PC, or sharing with a friend on your local WiFi):
    The app includes a built-in **Host Switcher** right next to the Overlay link bar!
    - Click **`[ Local PC ]`** for localhost URL.
    - Click **`[ Stream PC (LAN IP) ]`** to get your machine's network URL (e.g., `http://192.168.x.x:8080/...`), which works seamlessly on any browser or OBS on your home network!

---

### 6. Clean Interface & App Icon

- **No Technical Jargon**: Unnecessary technical labels like `(Port 55001)` and `(Port 8080)` have been removed. The status bar simply displays **`PvZ Fusion: Connected`** or **`PvZ Fusion: Offline`**.
- **Official App Icon**: Embedded into `PvZ_Fusion_Studio.exe`, the desktop shortcut, and provided as `favicon.ico` so the window and taskbar show the Gatling Peashooter icon instead of the generic browser globe icon.
- **Organized Files**: All diagnostic, setup, and conversion scripts are organized into the `tools/` folder, keeping the root directory clean and professional.
