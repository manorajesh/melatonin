Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class Win32 {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);
    [DllImport("dwmapi.dll")]   public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}

public class ModernColorTable : ProfessionalColorTable {
    public override Color MenuBorder                  { get { return Color.FromArgb(60, 60, 60); } }
    public override Color ToolStripDropDownBackground { get { return Color.FromArgb(30, 30, 30); } }
    public override Color MenuItemSelected            { get { return Color.Transparent; } }
    public override Color MenuItemBorder              { get { return Color.Transparent; } }
    public override Color SeparatorDark               { get { return Color.FromArgb(65, 65, 65); } }
    public override Color SeparatorLight              { get { return Color.Transparent; } }
    public override Color ImageMarginGradientBegin    { get { return Color.FromArgb(30, 30, 30); } }
    public override Color ImageMarginGradientMiddle   { get { return Color.FromArgb(30, 30, 30); } }
    public override Color ImageMarginGradientEnd      { get { return Color.FromArgb(30, 30, 30); } }
}

public class ModernMenuRenderer : ToolStripProfessionalRenderer {
    public ModernMenuRenderer() : base(new ModernColorTable()) {
        RoundedEdges = false;
    }

    protected override void OnRenderToolStripBackground(ToolStripRenderEventArgs e) {
        e.Graphics.Clear(Color.FromArgb(30, 30, 30));
    }

    protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e) {
        if (!e.Item.Selected || !e.Item.Enabled) return;
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        var rect = new Rectangle(4, 2, e.Item.Width - 8, e.Item.Height - 4);
        using (var brush = new SolidBrush(Color.FromArgb(55, 55, 55)))
        using (var path = RoundedRect(rect, 5))
            g.FillPath(brush, path);
    }

    protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
        e.TextColor = e.Item.Enabled
            ? Color.FromArgb(242, 242, 242)
            : Color.FromArgb(115, 115, 115);
        base.OnRenderItemText(e);
    }

    protected override void OnRenderSeparator(ToolStripSeparatorRenderEventArgs e) {
        int y = e.Item.Height / 2;
        using (var pen = new Pen(Color.FromArgb(65, 65, 65)))
            e.Graphics.DrawLine(pen, 10, y, e.Item.Width - 10, y);
    }

    protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e) {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        var r = e.ImageRectangle;
        int cx = r.X + r.Width / 2;
        int cy = r.Y + r.Height / 2;
        using (var brush = new SolidBrush(Color.FromArgb(76, 194, 255)))
            g.FillEllipse(brush, cx - 3, cy - 3, 6, 6);
    }

    protected override void OnRenderToolStripBorder(ToolStripRenderEventArgs e) {
        using (var pen = new Pen(Color.FromArgb(60, 60, 60)))
            e.Graphics.DrawRectangle(pen, 0, 0, e.ToolStrip.Width - 1, e.ToolStrip.Height - 1);
    }

    private static GraphicsPath RoundedRect(Rectangle b, int r) {
        var path = new GraphicsPath();
        path.AddArc(b.X, b.Y, r*2, r*2, 180, 90);
        path.AddArc(b.Right - r*2, b.Y, r*2, r*2, 270, 90);
        path.AddArc(b.Right - r*2, b.Bottom - r*2, r*2, r*2, 0, 90);
        path.AddArc(b.X, b.Bottom - r*2, r*2, r*2, 90, 90);
        path.CloseFigure();
        return path;
    }
}
"@

[Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0)

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

$menu               = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Renderer      = New-Object ModernMenuRenderer
$menu.Font          = New-Object System.Drawing.Font "Segoe UI", 9
$menu.Padding       = New-Object System.Windows.Forms.Padding 0, 4, 0, 4
$menu.ShowImageMargin = $false

$itemOn   = New-Object System.Windows.Forms.ToolStripMenuItem "wide awake"
$itemOff  = New-Object System.Windows.Forms.ToolStripMenuItem "getting drowsy"
$itemQuit = New-Object System.Windows.Forms.ToolStripMenuItem "goodnight"
foreach ($item in @($itemOn, $itemOff, $itemQuit)) {
    $item.Padding = New-Object System.Windows.Forms.Padding 8, 5, 12, 5
}

$menu.Items.AddRange(@($itemOn, $itemOff, (New-Object System.Windows.Forms.ToolStripSeparator), $itemQuit))
$tray.ContextMenuStrip = $menu

$menu.Add_Opened({
    $s = $args[0]
    $dark = 1;  [Win32]::DwmSetWindowAttribute($s.Handle, 20, [ref]$dark,  4) | Out-Null
    $round = 2; [Win32]::DwmSetWindowAttribute($s.Handle, 33, [ref]$round, 4) | Out-Null
})

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
