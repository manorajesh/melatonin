Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);
}
"@

[Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0)

function New-CircleIcon([System.Drawing.Color]$color) {
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $color), 1, 1, 13, 13)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

$iconOn  = New-CircleIcon ([System.Drawing.Color]::LimeGreen)
$iconOff = New-CircleIcon ([System.Drawing.Color]::DimGray)

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon    = $iconOff
$tray.Visible = $true

$menu        = New-Object System.Windows.Forms.ContextMenuStrip
$itemOn      = New-Object System.Windows.Forms.ToolStripMenuItem "wide awake"
$itemOff     = New-Object System.Windows.Forms.ToolStripMenuItem "getting drowsy"
$itemQuit    = New-Object System.Windows.Forms.ToolStripMenuItem "goodnight"
$menu.Items.AddRange(@($itemOn, $itemOff, (New-Object System.Windows.Forms.ToolStripSeparator), $itemQuit))
$tray.ContextMenuStrip = $menu

$timer          = New-Object System.Windows.Forms.Timer
$timer.Interval = 30000
$timer.Add_Tick({ [Win32]::SetThreadExecutionState(0x80000003) })

$itemOn.Add_Click({
    [Win32]::SetThreadExecutionState(0x80000003)
    $timer.Start()
    $tray.Icon       = $iconOn
    $tray.Text       = "melatonin: wide awake"
    $itemOn.Checked  = $true
    $itemOff.Checked = $false
})

$itemOff.Add_Click({
    $timer.Stop()
    [Win32]::SetThreadExecutionState(0x80000000)
    $tray.Icon       = $iconOff
    $tray.Text       = "melatonin: getting drowsy"
    $itemOn.Checked  = $false
    $itemOff.Checked = $true
})

$itemQuit.Add_Click({
    $timer.Stop()
    [Win32]::SetThreadExecutionState(0x80000000)
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$itemOn.PerformClick()
[System.Windows.Forms.Application]::Run()
