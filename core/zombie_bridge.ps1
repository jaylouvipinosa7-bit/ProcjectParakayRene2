# ==============================================================================
# RENEarn • Real Zombie Tsunami Live Command Bridge v4.0
# ==============================================================================
# Connects TikTok Live gifts, chat commands (!jump), and RENEarn Studio
# directly to the REAL Zombie Tsunami game running on your PC!

[Console]::Title = "RENEarn • Zombie Tsunami Real Game Command Bridge"

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Threading;

public class ZombieInputBridge {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const byte VK_SPACE = 0x20;
    public const byte SCAN_SPACE = 0x39;
    public const uint KEYEVENTF_KEYUP = 0x0002;

    public static IntPtr FindGameWindow() {
        IntPtr found = IntPtr.Zero;
        EnumWindows((hWnd, lParam) => {
            if (IsWindowVisible(hWnd)) {
                StringBuilder sb = new StringBuilder(256);
                GetWindowText(hWnd, sb, 256);
                string title = sb.ToString();
                if (title.IndexOf("Zombie Tsunami", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    title.IndexOf("ALYASROBINHOOD", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    title.IndexOf("net.mobigame", StringComparison.OrdinalIgnoreCase) >= 0) {
                    found = hWnd;
                    return false;
                }
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    public static void Jump(IntPtr hWnd, int holdMs) {
        if (hWnd != IntPtr.Zero) {
            SetForegroundWindow(hWnd);
            Thread.Sleep(25);
        }
        keybd_event(VK_SPACE, SCAN_SPACE, 0, UIntPtr.Zero);
        Thread.Sleep(holdMs);
        keybd_event(VK_SPACE, SCAN_SPACE, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }
}
"@

Write-Host "======================================================================" -ForegroundColor Green
Write-Host "       RENEarn • REAL ZOMBIE TSUNAMI COMMAND BRIDGE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Searching for Zombie Tsunami game window..." -ForegroundColor Cyan

$gameHwnd = [ZombieInputBridge]::FindGameWindow()

if ($gameHwnd -ne [IntPtr]::Zero) {
    Write-Host "  [OK] Game window FOUND! (Handle: $gameHwnd)" -ForegroundColor Green
} else {
    Write-Host "  [NOTE] Game window not detected by title yet." -ForegroundColor Yellow
    Write-Host "         Please make sure Zombie Tsunami is open on your screen." -ForegroundColor Yellow
    Write-Host "         The bridge will send global game inputs (Spacebar) to the active game." -ForegroundColor White
}

$countsPath = Join-Path $PSScriptRoot "counts.json"
$lastCountsHash = @{}
if (Test-Path $countsPath) {
    try {
        $raw = Get-Content $countsPath -Raw | ConvertFrom-Json
        $raw.PSObject.Properties | ForEach-Object { $lastCountsHash[$_.Name] = [int]$_.Value }
    } catch {}
}

Write-Host ""
Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  CONTROLS & SHORTCUTS IN THIS CONSOLE:" -ForegroundColor White
Write-Host "    [SPACE] or 'j'  : Trigger Normal Jump (120ms)" -ForegroundColor Cyan
Write-Host "    'h'             : Trigger High Jump (400ms)" -ForegroundColor Magenta
Write-Host "    't'             : Trigger Tsunami Jump Rush (5x Fast Jumps)" -ForegroundColor Yellow
Write-Host "    'q'             : Quit Bridge" -ForegroundColor Red
Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Bridge is ACTIVE! Monitoring gifts from TikTok Live & RENEarn..." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

$pollCounter = 0

while ($true) {
    # 1. Check Console Keyboard Inputs
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Spacebar -or $key.KeyChar -eq 'j' -or $key.KeyChar -eq 'J') {
            Write-Host ">>> [MANUAL] Normal Jump triggered! Sending Spacebar..." -ForegroundColor Cyan
            [ZombieInputBridge]::Jump($gameHwnd, 120)
        }
        elseif ($key.KeyChar -eq 'h' -or $key.KeyChar -eq 'H') {
            Write-Host ">>> [MANUAL] High Jump triggered! Holding Spacebar (400ms)..." -ForegroundColor Magenta
            [ZombieInputBridge]::Jump($gameHwnd, 400)
        }
        elseif ($key.KeyChar -eq 't' -or $key.KeyChar -eq 'T') {
            Write-Host ">>> [MANUAL] TSUNAMI RUSH! Sending 5 rapid jumps..." -ForegroundColor Yellow
            1..5 | ForEach-Object {
                [ZombieInputBridge]::Jump($gameHwnd, 100)
                Start-Sleep -Milliseconds 120
            }
        }
        elseif ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
            Write-Host "Exiting Bridge..." -ForegroundColor Yellow
            break
        }
    }

    # 2. Check counts.json every 200ms for incoming live stream gifts
    $pollCounter++
    if ($pollCounter -ge 4) {
        $pollCounter = 0
        if (Test-Path $countsPath) {
            try {
                $raw = Get-Content $countsPath -Raw | ConvertFrom-Json
                $hasGift = $false
                $giftCardId = ""
                foreach ($prop in $raw.PSObject.Properties) {
                    $currVal = [int]$prop.Value
                    $prevVal = if ($lastCountsHash.ContainsKey($prop.Name)) { [int]$lastCountsHash[$prop.Name] } else { 0 }
                    if ($currVal -gt $prevVal) {
                        $hasGift = $true
                        $giftCardId = $prop.Name
                        $diff = $currVal - $prevVal
                        Write-Host ">>> [STREAM GIFT RECEIVED!] Card #$giftCardId (+$diff) -> Triggering In-Game Jump!" -ForegroundColor Green
                        $lastCountsHash[$prop.Name] = $currVal
                    }
                }
                if ($hasGift) {
                    [ZombieInputBridge]::Jump($gameHwnd, 200)
                }
            } catch {}
        }

        # Keep finding game window if lost
        if ($gameHwnd -eq [IntPtr]::Zero) {
            $gameHwnd = [ZombieInputBridge]::FindGameWindow()
            if ($gameHwnd -ne [IntPtr]::Zero) {
                Write-Host ">>> [CONNECTED] Zombie Tsunami window detected! (Handle: $gameHwnd)" -ForegroundColor Green
            }
        }
    }

    Start-Sleep -Milliseconds 50
}
