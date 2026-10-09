using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Threading;

namespace PvZFusionStudio
{
    static class Program
    {
        static Process serverProc = null;

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            string appDir = AppDomain.CurrentDomain.BaseDirectory;
            string serverScript = Path.Combine(appDir, "core", "server.ps1");
            if (!File.Exists(serverScript)) serverScript = Path.Combine(appDir, "server.ps1");

            string iconPath = Path.Combine(appDir, "app_icon.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "core", "app_icon.ico");

            string dashboardUrl = "http://localhost:8080/app.html";

            // 1. Close existing duplicate server sessions
            try
            {
                ProcessStartInfo killPsi = new ProcessStartInfo();
                killPsi.FileName = "powershell.exe";
                killPsi.Arguments = "-NoProfile -Command \"Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*server.ps1*' -and $_.ProcessId -ne " + Process.GetCurrentProcess().Id + " } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }\"";
                killPsi.WindowStyle = ProcessWindowStyle.Hidden;
                killPsi.CreateNoWindow = true;
                killPsi.UseShellExecute = false;
                Process p = Process.Start(killPsi);
                p.WaitForExit(3000);
            }
            catch { }

            // 2. Start server.ps1 in background
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";
                psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + serverScript + "\"";
                psi.WorkingDirectory = Path.GetDirectoryName(serverScript);
                psi.WindowStyle = ProcessWindowStyle.Hidden;
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                serverProc = Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Failed to start server: " + ex.Message, "PvZ Fusion Studio", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            Thread.Sleep(1200);

            // 3. Find Edge or Chrome to launch as an App Window (Frameless desktop app mode)
            string edgePath = @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";
            if (!File.Exists(edgePath)) edgePath = @"C:\Program Files\Microsoft\Edge\Application\msedge.exe";

            string chromePath = @"C:\Program Files\Google\Chrome\Application\chrome.exe";
            if (!File.Exists(chromePath)) chromePath = @"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe";

            string targetBrowser = File.Exists(edgePath) ? edgePath : (File.Exists(chromePath) ? chromePath : null);
            string profileDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "PvZ_Fusion_Studio_Profile");

            if (targetBrowser != null)
            {
                ProcessStartInfo bPsi = new ProcessStartInfo();
                bPsi.FileName = targetBrowser;
                bPsi.Arguments = "--app=\"" + dashboardUrl + "\" --user-data-dir=\"" + profileDir + "\" --window-size=1440,900 --app-id=pvz-fusion-studio";
                bPsi.UseShellExecute = false;
                Process.Start(bPsi);
            }
            else
            {
                Process.Start(new ProcessStartInfo(dashboardUrl) { UseShellExecute = true });
            }

            // 4. Setup System Tray Icon so user can manage or close the studio cleanly
            NotifyIcon trayIcon = new NotifyIcon();
            if (File.Exists(iconPath))
            {
                try { trayIcon.Icon = new Icon(iconPath); } catch { trayIcon.Icon = SystemIcons.Application; }
            }
            else
            {
                trayIcon.Icon = SystemIcons.Application;
            }

            trayIcon.Text = "PvZ Fusion 4.0 Studio (Running)";
            trayIcon.Visible = true;

            ContextMenu menu = new ContextMenu();
            menu.MenuItems.Add("Open Studio Dashboard", (s, e) => {
                if (targetBrowser != null) {
                    Process.Start(new ProcessStartInfo(targetBrowser, "--app=\"" + dashboardUrl + "\" --user-data-dir=\"" + profileDir + "\"") { UseShellExecute = false });
                } else {
                    Process.Start(new ProcessStartInfo(dashboardUrl) { UseShellExecute = true });
                }
            });
            menu.MenuItems.Add("Open OBS Overlay", (s, e) => {
                Process.Start(new ProcessStartInfo("http://localhost:8080/overlay.html") { UseShellExecute = true });
            });
            menu.MenuItems.Add("Open Stream Grid Overlay", (s, e) => {
                Process.Start(new ProcessStartInfo("http://localhost:8080/stream-overlay.html") { UseShellExecute = true });
            });
            menu.MenuItems.Add("-");
            menu.MenuItems.Add("Exit Studio", (s, e) => {
                trayIcon.Visible = false;
                if (serverProc != null && !serverProc.HasExited) {
                    try { serverProc.Kill(); } catch { }
                }
                Application.Exit();
            });

            trayIcon.ContextMenu = menu;
            trayIcon.DoubleClick += (s, e) => {
                if (targetBrowser != null) {
                    Process.Start(new ProcessStartInfo(targetBrowser, "--app=\"" + dashboardUrl + "\" --user-data-dir=\"" + profileDir + "\"") { UseShellExecute = false });
                } else {
                    Process.Start(new ProcessStartInfo(dashboardUrl) { UseShellExecute = true });
                }
            };

            // Notification balloon on start
            trayIcon.ShowBalloonTip(3000, "PvZ Fusion 4.0 Studio", "Live Stream Control Studio is running!\nClick or right-click this icon in your system tray to manage.", ToolTipIcon.Info);

            Application.Run();
        }
    }
}
