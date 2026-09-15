using System.Diagnostics;
using System.Runtime.InteropServices;

namespace QolSeriesInstaller;

/// <summary>
/// The install / uninstall window. Same binary as the app: run it named "...Setup.exe", or with
/// --setup, and you get this instead of the tool. Uses the app's own palette and controls so the
/// two look like one product.
/// </summary>
internal sealed class SetupForm : Form
{
    private readonly Palette p = Palettes.ByKey(AppSettings.Load().Theme);
    private readonly bool uninstallMode;
    private readonly Image? artwork;

    private readonly TextBox pathBox = new();
    private readonly ToggleRow startMenu;
    private readonly ToggleRow desktop;
    private readonly ToggleRow keepSettings;
    private readonly RoundButton primary = new();
    private readonly RoundButton secondary = new();
    private readonly Label status = new();
    private bool working, finished;

    internal SetupForm(bool uninstall)
    {
        uninstallMode = uninstall;
        var existing = Setup.InstalledAt;

        Text = uninstall ? "Quality of Life Series - Uninstall" : "Quality of Life Series - Setup";
        FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false; MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = p.Base; ForeColor = p.Ink; Font = Ui.F(10); DoubleBuffered = true;

        var icon = Path.Combine(Payload.Dir, "qol_installer.ico");
        if (File.Exists(icon)) { Icon = new Icon(icon); artwork = new Icon(icon, new Size(64, 64)).ToBitmap(); }

        int pad = D(28), width = D(620);

        var mark = new LogoMark { Bounds = new Rectangle(pad, D(26), D(44), D(44)), Radius = 12, BackColor = p.Card, BorderColor = p.Card, Glyph = "", GlyphColor = p.Accent, Artwork = artwork };
        var title = new Label { Bounds = new Rectangle(pad + D(58), D(26), width - pad * 2 - D(58), D(26)), AutoSize = false, TextAlign = ContentAlignment.MiddleLeft, Text = Setup.AppName, Font = Ui.F(15, true), ForeColor = p.Ink, BackColor = p.Base, UseMnemonic = false };
        var subtitle = new Label
        {
            Bounds = new Rectangle(pad + D(58), D(52), width - pad * 2 - D(58), D(20)),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleLeft,
            Text = $"Version {Setup.Version}",
            Font = Ui.F(9), ForeColor = p.Muted, BackColor = p.Base, UseMnemonic = false
        };
        Controls.Add(mark); Controls.Add(title); Controls.Add(subtitle);

        var y = D(90);

        if (!uninstall)
        {
            Controls.Add(Caption("INSTALL TO", pad, y, width));
            y += D(24);
            pathBox.Bounds = new Rectangle(pad, y, width - pad * 2 - D(92), D(32));
            pathBox.Text = existing ?? Setup.DefaultTarget;
            pathBox.BackColor = p.Secondary; pathBox.ForeColor = p.Ink; pathBox.BorderStyle = BorderStyle.FixedSingle; pathBox.Font = Ui.F(9.5f);
            var browse = new RoundButton { Bounds = new Rectangle(width - pad - D(84), y, D(84), D(32)), Radius = D(16), Text = "Browse", BackColor = p.Secondary, HoverColor = p.SecondaryHover, ForeColor = p.Ink, Font = Ui.F(9, true), Cursor = Cursors.Hand, TextAlign = ContentAlignment.MiddleCenter };
            browse.Click += (_, _) =>
            {
                using var pick = new FolderBrowserDialog { SelectedPath = Directory.Exists(pathBox.Text) ? pathBox.Text : Setup.DefaultTarget };
                if (pick.ShowDialog(this) == DialogResult.OK) pathBox.Text = Path.Combine(pick.SelectedPath, Setup.AppName);
            };
            Controls.Add(pathBox); Controls.Add(browse);
            // A single-line TextBox sizes its own height from the font, so centre it on the button
            // rather than assuming the Height we asked for stuck.
            pathBox.Top = y + (D(32) - pathBox.Height) / 2;
            y += D(46);

            Controls.Add(Caption("SHORTCUTS", pad, y, width));
            y += D(24);
            startMenu = Toggle("Start menu", true, pad, y, width); y += D(48);
            desktop = Toggle("Desktop", true, pad, y, width); y += D(48);
            keepSettings = Toggle("", false, 0, 0, 0);
        }
        else
        {
            Controls.Add(Caption("KEEP", pad, y, width));
            y += D(24);
            keepSettings = Toggle("My theme and player name", true, pad, y, width); y += D(48);
            startMenu = Toggle("", false, 0, 0, 0);
            desktop = Toggle("", false, 0, 0, 0);
        }

        y += D(6);
        status.Bounds = new Rectangle(pad, y, width - pad * 2, D(34));
        status.AutoSize = false; status.Font = Ui.F(9); status.ForeColor = p.Muted; status.BackColor = p.Base; status.UseMnemonic = false;
        status.Text = uninstall ? "Your mods stay installed in Plutonium."
            : existing is null ? "" : "Already installed here - this updates it.";
        Controls.Add(status);
        y += D(42);

        primary.Bounds = new Rectangle(pad, y, width - pad * 2, D(44));
        primary.Radius = D(22);
        primary.Text = uninstall ? "Uninstall" : existing is null ? "Install" : "Update";
        primary.BackColor = uninstall ? p.Secondary : p.Accent;
        primary.HoverColor = uninstall ? p.SecondaryHover : p.AccentHover;
        primary.ForeColor = uninstall ? p.Ink : p.AccentText;
        primary.Font = Ui.F(10, true); primary.Cursor = Cursors.Hand; primary.TextAlign = ContentAlignment.MiddleCenter;
        primary.Click += async (_, _) => await GoAsync();
        Controls.Add(primary);
        y += D(52);

        secondary.Bounds = new Rectangle(pad, y, width - pad * 2, D(34));
        secondary.Radius = D(17);
        secondary.Text = uninstall ? "Keep it installed" : "Not now";
        secondary.BackColor = p.Base; secondary.HoverColor = p.Card; secondary.ForeColor = p.Muted;
        secondary.Font = Ui.F(9); secondary.Cursor = Cursors.Hand; secondary.TextAlign = ContentAlignment.MiddleCenter;
        secondary.Click += (_, _) => Close();
        Controls.Add(secondary);

        ClientSize = new Size(width, y + D(34) + D(20));
        var dark = p.Dark ? 1 : 0;
        HandleCreated += (_, _) => { if (DwmSetWindowAttribute(Handle, 20, ref dark, 4) != 0) DwmSetWindowAttribute(Handle, 19, ref dark, 4); };
    }

    private int D(int v) => Ui.Dp(this, v);

    /// <summary>A real, absolute local path - so a typo gets a plain answer, not a raw .NET message.</summary>
    private static bool Rooted(string path)
    {
        if (path.Length == 0 || path.IndexOfAny(Path.GetInvalidPathChars()) >= 0) return false;
        try { return Path.IsPathFullyQualified(path); }
        catch { return false; }
    }

    private Label Caption(string text, int x, int y, int width) => new()
    {
        Bounds = new Rectangle(x + D(2), y, width - x * 2, D(20)),
        AutoSize = false, TextAlign = ContentAlignment.BottomLeft,
        Text = text, Font = Ui.F(8), ForeColor = p.Caption, BackColor = p.Base, UseMnemonic = false
    };

    private ToggleRow Toggle(string title, bool on, int x, int y, int width)
    {
        var row = new ToggleRow(p) { On = on };
        if (width == 0) { row.Visible = false; return row; }
        row.Bounds = new Rectangle(x, y, width - x * 2, D(40));
        row.Set(title);
        Controls.Add(row);
        return row;
    }

    private async Task GoAsync()
    {
        if (working) return;
        if (finished) { Close(); return; }
        working = true; primary.Enabled = false; secondary.Enabled = false; primary.Invalidate();
        var report = new Progress<string>(s => { status.Text = s; status.ForeColor = p.Muted; });
        try
        {
            if (uninstallMode)
            {
                status.Text = "Removing...";
                await Task.Run(() => Setup.Uninstall(keepSettings.On));
                status.Text = "Removed.";
                status.ForeColor = p.Good;
                await Task.Delay(1200);
                Application.Exit();
                return;
            }

            var target = pathBox.Text.Trim();
            if (!Rooted(target))
            {
                status.Text = target.Length == 0 ? "Pick a folder to install into." : "That is not a valid folder path - use Browse to pick one.";
                status.ForeColor = Color.FromArgb(243, 139, 168);
                working = false; primary.Enabled = secondary.Enabled = true;
                return;
            }
            await Task.Run(() => Setup.Install(target, startMenu.On, desktop.On, report));

            // Say it once, here, rather than letting someone find out when a game will not start.
            // Nothing is installed on their behalf; the app's Requirements page has the detail.
            var short_ = Requirements.Missing(new InstallerService());
            status.Text = short_ == 0
                ? "Installed."
                : short_ == 1
                    ? "Installed. One thing the games need is missing - see Requirements in the app."
                    : $"Installed. {short_} things the games need are missing - see Requirements in the app.";
            status.ForeColor = short_ == 0 ? p.Good : p.Ink;
            primary.Text = "Open Quality of Life Series";
            primary.BackColor = p.Good; primary.HoverColor = p.Good; primary.ForeColor = p.AccentText;
            secondary.Text = "Close";
            finished = true;
            primary.Click += (_, _) =>
            {
                try { Process.Start(new ProcessStartInfo(Path.Combine(target, Setup.ExeName)) { UseShellExecute = true, WorkingDirectory = target }); } catch { }
                Application.Exit();
            };
        }
        catch (Exception ex)
        {
            status.Text = "That did not work: " + ex.Message;
            status.ForeColor = Color.FromArgb(243, 139, 168);
        }
        finally { working = false; primary.Enabled = true; secondary.Enabled = true; primary.Invalidate(); secondary.Invalidate(); }
    }

    [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    /// <summary>A card row with a real on/off switch, so nothing here is one-way.</summary>
    private sealed class ToggleRow : RoundedPanel
    {
        private readonly Palette p;
        private readonly Label title = new();
        private readonly RoundButton button = new();
        internal bool On { get; set; }

        internal ToggleRow(Palette palette)
        {
            p = palette;
            Radius = 10; BackColor = p.Card; BorderColor = p.Card; HoverBorderColor = p.Card; HoverFill = Color.Empty;
            title.AutoSize = false; title.Font = Ui.F(10); title.ForeColor = p.Ink; title.BackColor = p.Card; title.TextAlign = ContentAlignment.MiddleLeft; title.AutoEllipsis = true; title.UseMnemonic = false;
            button.Radius = 14; button.Font = Ui.F(8.5f, true); button.Cursor = Cursors.Hand; button.TextAlign = ContentAlignment.MiddleCenter;
            button.Click += (_, _) => { On = !On; Sync(); };
            Controls.Add(title); Controls.Add(button);
        }

        internal void Set(string heading) { title.Text = heading; Sync(); }

        private void Sync()
        {
            button.Text = On ? "On" : "Off";
            button.BackColor = On ? p.Accent : p.Secondary;
            button.HoverColor = On ? p.AccentHover : p.SecondaryHover;
            button.ForeColor = On ? p.AccentText : p.Muted;
            button.Invalidate();
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            int pad = Ui.Dp(this, 14), bw = Ui.Dp(this, 68), bh = Ui.Dp(this, 28);
            button.Bounds = new Rectangle(Width - pad - bw, (Height - bh) / 2, bw, bh);
            var room = Math.Max(Ui.Dp(this, 60), Width - pad * 2 - bw - Ui.Dp(this, 12));
            title.Bounds = new Rectangle(pad, 0, room, Height);
        }
    }
}
