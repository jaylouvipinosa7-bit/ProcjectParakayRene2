using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Threading;
using System.Runtime.InteropServices;
using System.Net;
using System.Text;

namespace RENEarnStudio
{
    public static class GlobalKeyboardHook
    {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_SYSKEYDOWN = 0x0104;

        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        private static LowLevelKeyboardProc _proc = HookCallback;
        private static IntPtr _hookID = IntPtr.Zero;

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        private static extern short GetKeyState(int nVirtKey);

        private static long _lastActionTime = 0;
        private static string _lastAction = "";

        public static void Install()
        {
            if (_hookID != IntPtr.Zero) return;
            try
            {
                using (Process curProcess = Process.GetCurrentProcess())
                using (ProcessModule curModule = curProcess.MainModule)
                {
                    _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
                }
            }
            catch { }

            if (_hookID == IntPtr.Zero)
            {
                try { _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, IntPtr.Zero, 0); } catch { }
            }
        }

        public static void Uninstall()
        {
            if (_hookID != IntPtr.Zero)
            {
                try { UnhookWindowsHookEx(_hookID); } catch { }
                _hookID = IntPtr.Zero;
            }
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0)
            {
                int msg = wParam.ToInt32();
                if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN)
                {
                    int vkCode = Marshal.ReadInt32(lParam);
                    int flags = Marshal.ReadInt32(lParam, 8);

                    // Alt key detection: LLKHF_ALTDOWN flag or physical key state of VK_MENU
                    bool altDown = ((flags & 0x20) != 0) || (GetKeyState(0x12) < 0) || (GetKeyState(0xA4) < 0) || (GetKeyState(0xA5) < 0);

                    // Minus / Lose:
                    // 1) Alt + '-' (0xBD = VK_OEM_MINUS) or Alt + Numpad '-' (0x6D = VK_SUBTRACT)
                    // 2) Single '[' (0xDB = VK_OEM_4)
                    bool isLose = (altDown && (vkCode == 0xBD || vkCode == 0x6D)) || (!altDown && vkCode == 0xDB);

                    // Plus / Win:
                    // 1) Alt + '=' / '+' (0xBB = VK_OEM_PLUS) or Alt + Numpad '+' (0x6B = VK_ADD)
                    // 2) Single ']' (0xDD = VK_OEM_6)
                    bool isWin = (altDown && (vkCode == 0xBB || vkCode == 0x6B)) || (!altDown && vkCode == 0xDD);

                    if (isLose)
                    {
                        TriggerAdjust("lose_plus");
                    }
                    else if (isWin)
                    {
                        TriggerAdjust("win_plus");
                    }
                }
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        private static void TriggerAdjust(string action)
        {
            long now = DateTime.UtcNow.Ticks / TimeSpan.TicksPerMillisecond;
            if (action == _lastAction && (now - _lastActionTime) < 120) return;
            _lastActionTime = now;
            _lastAction = action;

            ThreadPool.QueueUserWorkItem((state) =>
            {
                try
                {
                    HttpWebRequest req = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8080/api/win-widget/adjust");
                    req.Method = "POST";
                    req.ContentType = "application/json";
                    req.Timeout = 1500;
                    byte[] data = Encoding.UTF8.GetBytes("{\"action\":\"" + action + "\"}");
                    req.ContentLength = data.Length;
                    using (Stream s = req.GetRequestStream())
                    {
                        s.Write(data, 0, data.Length);
                    }
                    using (WebResponse resp = req.GetResponse()) { }
                }
                catch { }
            });
        }
    }

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
            if (!File.Exists(serverScript)) serverScript = Path.Combine(appDir, "..", "core", "server.ps1");
            if (!File.Exists(serverScript)) serverScript = Path.Combine(appDir, "server.ps1");

            string iconPath = Path.Combine(appDir, "renearn.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "app_icon.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "..", "renearn.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "..", "app_icon.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "core", "app_icon.ico");
            if (!File.Exists(iconPath)) iconPath = Path.Combine(appDir, "..", "core", "app_icon.ico");

            string dashboardUrl = "http://localhost:8080/app.html";

            // 1. Check if server is already running and responding
            bool serverAlreadyRunning = false;
            try
            {
                HttpWebRequest ping = (HttpWebRequest)WebRequest.Create("http://127.0.0.1:8080/api/status");
                ping.Timeout = 400;
                using (WebResponse r = ping.GetResponse()) { serverAlreadyRunning = true; }
            }
            catch { }

            // 2. Only start server.ps1 if not already running
            if (!serverAlreadyRunning)
            {
                try
                {
                    ProcessStartInfo killPsi = new ProcessStartInfo();
                    killPsi.FileName = "powershell.exe";
                    killPsi.Arguments = "-NoProfile -Command \"Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*server.ps1*' -and $_.ProcessId -ne " + Process.GetCurrentProcess().Id + " } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }\"";
                    killPsi.WindowStyle = ProcessWindowStyle.Hidden;
                    killPsi.CreateNoWindow = true;
                    killPsi.UseShellExecute = false;
                    Process p = Process.Start(killPsi);
                    p.WaitForExit(2000);
                }
                catch { }

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
                    MessageBox.Show("Failed to start server: " + ex.Message, "RENEarn Studio", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }

            // Wait dynamically until server is listening and ready to serve app.html
            for (int i = 0; i < 60; i++)
            {
                try
                {
                    HttpWebRequest ping = (HttpWebRequest)WebRequest.Create(dashboardUrl);
                    ping.Timeout = 250;
                    using (WebResponse r = ping.GetResponse()) { }
                    break;
                }
                catch
                {
                    Thread.Sleep(100);
                }
            }

            // 3. Find Edge or Chrome to launch as an App Window (Frameless desktop app mode)
            string edgePath = @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";
            if (!File.Exists(edgePath)) edgePath = @"C:\Program Files\Microsoft\Edge\Application\msedge.exe";

            string chromePath = @"C:\Program Files\Google\Chrome\Application\chrome.exe";
            if (!File.Exists(chromePath)) chromePath = @"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe";

            string targetBrowser = File.Exists(edgePath) ? edgePath : (File.Exists(chromePath) ? chromePath : null);
            string profileDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RENEarn_Studio_Profile");

            if (targetBrowser != null)
            {
                ProcessStartInfo bPsi = new ProcessStartInfo();
                bPsi.FileName = targetBrowser;
                bPsi.Arguments = "--app=\"" + dashboardUrl + "\" --user-data-dir=\"" + profileDir + "\" --window-size=1440,900 --app-id=renearn-studio --background-color=#090a0f --force-dark-mode";
                bPsi.UseShellExecute = false;
                Process.Start(bPsi);
            }
            else
            {
                Process.Start(new ProcessStartInfo(dashboardUrl) { UseShellExecute = true });
            }

            // 4. Setup System Tray Icon & Off-Screen Hotkey Form
            HotkeyForm hkForm = new HotkeyForm();
            NotifyIcon trayIcon = new NotifyIcon();
            if (File.Exists(iconPath))
            {
                try { trayIcon.Icon = new Icon(iconPath); } catch { trayIcon.Icon = SystemIcons.Application; }
            }
            else
            {
                trayIcon.Icon = SystemIcons.Application;
            }

            trayIcon.Text = "RENEarn Studio (Running)";
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
            menu.MenuItems.Add("Open Win Fraction Overlay", (s, e) => {
                Process.Start(new ProcessStartInfo("http://localhost:8080/overlay-win.html") { UseShellExecute = true });
            });
            menu.MenuItems.Add("Open Lucky Wheel Overlay", (s, e) => {
                Process.Start(new ProcessStartInfo("http://localhost:8080/overlay-spinner.html") { UseShellExecute = true });
            });
            menu.MenuItems.Add("-");
            menu.MenuItems.Add("Exit Studio", (s, e) => {
                GlobalKeyboardHook.Uninstall();
                trayIcon.Visible = false;
                if (serverProc != null && !serverProc.HasExited) {
                    try { serverProc.Kill(); } catch { }
                }
                hkForm.Close();
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

            // (Startup balloon notification removed to keep startup clean and quiet)

            // Install low-level keyboard hook
            GlobalKeyboardHook.Install();

            Application.Run(hkForm);
        }
    }

    public class HotkeyForm : Form
    {
        public HotkeyForm()
        {
            this.ShowInTaskbar = false;
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.Manual;
            this.Location = new Point(-3000, -3000);
            this.Size = new Size(1, 1);
            this.Opacity = 0;
        }
    }
}
