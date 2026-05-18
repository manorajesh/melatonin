Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);

    [DllImport("user32.dll")]   public static extern IntPtr CreatePopupMenu();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
                                public static extern bool AppendMenu(IntPtr hMenu, uint uFlags, IntPtr uIDNewItem, string lpNewItem);
    [DllImport("user32.dll")]   public static extern int TrackPopupMenu(IntPtr hMenu, uint uFlags, int x, int y, int nReserved, IntPtr hWnd, IntPtr prcRect);
    [DllImport("user32.dll")]   public static extern uint CheckMenuItem(IntPtr hMenu, uint uIDCheckItem, uint uCheck);
    [DllImport("user32.dll")]   public static extern bool DestroyMenu(IntPtr hMenu);
    [DllImport("user32.dll")]   public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]   public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
}
"@

[Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0) | Out-Null

# PowerShell parses $ES_AWAKE as signed Int32 (-2147483645), which fails the uint cast.
# Convert from hex string to avoid any signed/unsigned ambiguity.
$ES_AWAKE   = [System.Convert]::ToUInt32("80000003", 16)  # ES_CONTINUOUS|ES_DISPLAY_REQUIRED|ES_SYSTEM_REQUIRED
$ES_RELEASE = [System.Convert]::ToUInt32("80000000", 16)  # ES_CONTINUOUS only — releases the request

# --- Tray icon ---
function New-CircleIcon([System.Drawing.Color]$color) {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $color), 2, 2, 27, 27)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

$iconOn  = New-CircleIcon ([System.Drawing.Color]::FromArgb(100, 220, 100))
$iconOff = New-CircleIcon ([System.Drawing.Color]::FromArgb(100, 100, 100))

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon    = $iconOff
$tray.Visible = $true

# --- Native Win32 popup menu ---
# TrackPopupMenu renders via the OS shell — follows system theme automatically
$hMenu = [Win32]::CreatePopupMenu()
[Win32]::AppendMenu($hMenu, 0x0000, [IntPtr]1, "wide awake")     | Out-Null
[Win32]::AppendMenu($hMenu, 0x0000, [IntPtr]2, "getting drowsy") | Out-Null
[Win32]::AppendMenu($hMenu, 0x0800, [IntPtr]0, $null)            | Out-Null  # separator
[Win32]::AppendMenu($hMenu, 0x0000, [IntPtr]3, "goodnight")      | Out-Null

# Hidden anchor window required by TrackPopupMenu
$anchor               = New-Object System.Windows.Forms.Form
$anchor.ShowInTaskbar = $false
$anchor.WindowState   = [System.Windows.Forms.FormWindowState]::Minimized
$anchorHwnd           = $anchor.Handle  # creates HWND without showing the form

# --- Timer ---
$timer          = New-Object System.Windows.Forms.Timer
$timer.Interval = 30000
$timer.Add_Tick({ [Win32]::SetThreadExecutionState($ES_AWAKE) | Out-Null })

# --- State ---
function Set-AwakeState([bool]$on) {
    if ($on) {
        [Win32]::SetThreadExecutionState($ES_AWAKE) | Out-Null
        $script:timer.Start()
        $script:tray.Icon = $script:iconOn
        $script:tray.Text = "melatonin: wide awake"
        [Win32]::CheckMenuItem($script:hMenu, 1, 0x0008) | Out-Null  # MF_CHECKED
        [Win32]::CheckMenuItem($script:hMenu, 2, 0x0000) | Out-Null  # MF_UNCHECKED
    } else {
        $script:timer.Stop()
        [Win32]::SetThreadExecutionState($ES_RELEASE) | Out-Null
        $script:tray.Icon = $script:iconOff
        $script:tray.Text = "melatonin: getting drowsy"
        [Win32]::CheckMenuItem($script:hMenu, 1, 0x0000) | Out-Null
        [Win32]::CheckMenuItem($script:hMenu, 2, 0x0008) | Out-Null
    }
}

# --- Tray right-click ---
$tray.Add_MouseClick({
    if ($_.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }
    $pt = [System.Windows.Forms.Cursor]::Position
    [Win32]::SetForegroundWindow($anchorHwnd) | Out-Null
    # TPM_RETURNCMD (0x0100) | TPM_RIGHTBUTTON (0x0002)
    $cmd = [Win32]::TrackPopupMenu($hMenu, 0x0102, $pt.X, $pt.Y, 0, $anchorHwnd, [IntPtr]::Zero)
    [Win32]::PostMessage($anchorHwnd, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    switch ($cmd) {
        1 { Set-AwakeState $true }
        2 { Set-AwakeState $false }
        3 {
            $script:timer.Stop()
            [Win32]::SetThreadExecutionState($ES_RELEASE) | Out-Null
            [Win32]::DestroyMenu($script:hMenu) | Out-Null
            $script:tray.Visible = $false
            $script:tray.Dispose()
            [System.Windows.Forms.Application]::Exit()
        }
    }
})

Set-AwakeState $true

[System.Windows.Forms.Application]::Run()
