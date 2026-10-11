using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace RENEarnGlobalHotkeys
{
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

    static class Program
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

        [DllImport("user32.dll")]
        private static extern short GetKeyState(int nVirtKey);

        private static long _lastActionTime = 0;
        private static string _lastAction = "";
        private static string _logPath;

        private static void Log(string msg)
        {
            try { File.AppendAllText(_logPath, DateTime.Now.ToString("HH:mm:ss.fff") + " " + msg + Environment.NewLine); } catch { }
        }

        [STAThread]
        static void Main()
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory;
            _logPath = Path.Combine(dir, "hotkey_service.log");
            Log("Service starting...");

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "RENEarn_GlobalHotkey_Mutex", out createdNew))
            {
                if (!createdNew)
                {
                    Log("Another instance already running. Exiting.");
                    return;
                }

                _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, IntPtr.Zero, 0);
                int err = Marshal.GetLastWin32Error();
                Log("SetWindowsHookEx result: " + _hookID + " err: " + err);

                Application.ApplicationExit += (s, e) => {
                    if (_hookID != IntPtr.Zero) UnhookWindowsHookEx(_hookID);
                    Log("Service ApplicationExit called.");
                };

                Log("Starting Application.Run(new HotkeyForm())...");
                Application.Run(new HotkeyForm());
                Log("Application.Run finished.");
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
                    
                    bool altDown = ((flags & 0x20) != 0) || (GetKeyState(0x12) < 0) || (GetKeyState(0xA4) < 0) || (GetKeyState(0xA5) < 0);

                    // Minus / Lose:
                    // 1) Alt + '-' (0xBD) or Alt + Numpad '-' (0x6D)
                    // 2) Single '[' (0xDB)
                    bool isLose = (altDown && (vkCode == 0xBD || vkCode == 0x6D)) || (!altDown && vkCode == 0xDB);

                    // Plus / Win:
                    // 1) Alt + '=' (0xBB) or Alt + Numpad '+' (0x6B)
                    // 2) Single ']' (0xDD)
                    bool isWin = (altDown && (vkCode == 0xBB || vkCode == 0x6B)) || (!altDown && vkCode == 0xDD);

                    if (isLose || isWin)
                    {
                        Log(string.Format("HotKey caught: vk=0x{0:X} alt={1} msg=0x{2:X} -> {3}", vkCode, altDown, msg, isLose ? "lose" : "win"));
                        TriggerAdjust(isLose ? "lose_plus" : "win_plus");
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
                    Log("POST /api/win-widget/adjust OK: " + action);
                }
                catch (Exception ex)
                {
                    Log("POST error: " + ex.Message);
                }
            });
        }
    }
}
