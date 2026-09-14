using System.Diagnostics;
using System.Drawing.Drawing2D;

namespace QolSeriesInstaller;

internal sealed class MainForm : Form
{
    private readonly InstallerService service;
    private readonly Panel content = new() { Dock = DockStyle.Fill, BackColor = Color.FromArgb(20, 23, 29), Padding = new Padding(34) };
    private readonly Label footer = new() { Dock = DockStyle.Bottom, Height = 38, ForeColor = Color.FromArgb(145, 155, 170), Padding = new Padding(18, 10, 0, 0), Text = "Ready" };
    private readonly ProgressBar progress = new() { Dock = DockStyle.Bottom, Height = 3, Style = ProgressBarStyle.Marquee, Visible = false };
    private readonly Color accent = Color.FromArgb(20, 188, 186);

    internal MainForm(InstallerService service)
    {
        this.service = service;
        Text = "Quality of Life Series"; MinimumSize = new Size(940, 620); Size = new Size(1120, 720); StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(14, 16, 21); ForeColor = Color.White; Font = new Font("Segoe UI", 10); Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        var side = new Panel { Dock = DockStyle.Left, Width = 235, BackColor = Color.FromArgb(14, 16, 21), Padding = new Padding(16, 24, 16, 16) };
        side.Controls.Add(Nav("About", ShowAbout)); side.Controls.Add(Nav("Details and log", ShowDetails)); side.Controls.Add(Nav("Backups", ShowBackups)); side.Controls.Add(Nav("Uninstall", ShowRemove)); side.Controls.Add(Nav("Black Ops II", ShowT6));
        var brand = new Label { Dock = DockStyle.Top, Height = 92, Text = "QUALITY OF LIFE\nSERIES", ForeColor = Color.White, Font = new Font("Segoe UI Semibold", 17), TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(8, 0, 0, 0) };
        side.Controls.Add(brand);
        Controls.Add(content); Controls.Add(side); Controls.Add(progress); Controls.Add(footer); ShowT6();
    }

    private Button Nav(string text, Action action)
    {
        var b = new Button { Dock = DockStyle.Top, Height = 48, Text = text, TextAlign = ContentAlignment.MiddleLeft, FlatStyle = FlatStyle.Flat, BackColor = Color.Transparent, ForeColor = Color.FromArgb(195, 202, 213), Padding = new Padding(12, 0, 0, 0), Cursor = Cursors.Hand };
        b.FlatAppearance.BorderSize = 0; b.FlatAppearance.MouseOverBackColor = Color.FromArgb(31, 36, 45); b.Click += (_, _) => action(); return b;
    }
    private void Clear(string title, string subtitle)
    {
        content.Controls.Clear();
        var sub = new Label { Dock = DockStyle.Top, Height = 38, Text = subtitle, ForeColor = Color.FromArgb(146, 157, 173), Font = new Font("Segoe UI", 10) };
        var head = new Label { Dock = DockStyle.Top, Height = 48, Text = title, ForeColor = Color.White, Font = new Font("Segoe UI Semibold", 25) };
        content.Controls.Add(sub); content.Controls.Add(head);
    }
    private FlowLayoutPanel Cards() { var p = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.LeftToRight, WrapContents = true, AutoScroll = true, Padding = new Padding(0, 18, 0, 0) }; content.Controls.Add(p); p.BringToFront(); return p; }
    private Panel Card(string title, string description, string status, string button, Func<Task> action, bool primary = false)
    {
        var panel = new Panel { Width = 375, Height = 185, Margin = new Padding(0, 0, 18, 18), BackColor = Color.FromArgb(29, 33, 41), Padding = new Padding(22) };
        panel.Paint += (_, e) => { using var pen = new Pen(primary ? accent : Color.FromArgb(52, 58, 69)); e.Graphics.DrawRectangle(pen, 0, 0, panel.Width - 1, panel.Height - 1); };
        var btn = new Button { Dock = DockStyle.Bottom, Height = 38, Text = button, FlatStyle = FlatStyle.Flat, BackColor = primary ? accent : Color.FromArgb(48, 55, 67), ForeColor = primary ? Color.FromArgb(8, 32, 33) : Color.White, Font = new Font("Segoe UI Semibold", 9), Cursor = Cursors.Hand };
        btn.FlatAppearance.BorderSize = 0; btn.Click += async (_, _) => await Run(action, btn);
        panel.Controls.Add(btn); panel.Controls.Add(new Label { Dock = DockStyle.Bottom, Height = 30, Text = status, ForeColor = status.Contains("not") || status.Contains("default") ? Color.FromArgb(150, 160, 174) : Color.FromArgb(80, 215, 160) });
        panel.Controls.Add(new Label { Dock = DockStyle.Fill, Text = description, ForeColor = Color.FromArgb(177, 185, 198) });
        panel.Controls.Add(new Label { Dock = DockStyle.Top, Height = 34, Text = title, ForeColor = Color.White, Font = new Font("Segoe UI Semibold", 14) }); return panel;
    }
    private async Task Run(Func<Task> action, Control source)
    {
        try { Enabled = false; progress.Visible = true; footer.Text = "Working..."; await action(); footer.Text = "Done"; ShowT6(); }
        catch (Exception ex) { footer.Text = "Stopped"; MessageBox.Show(this, ex.Message, "Quality of Life Series", MessageBoxButtons.OK, MessageBoxIcon.Error); }
        finally { progress.Visible = false; Enabled = true; source.Focus(); }
    }
    private Progress<string> Reporter() => new(s => footer.Text = s);
    private bool Confirm(string text, string title = "Confirm") => MessageBox.Show(this, text, title, MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes;

    private void ShowT6()
    {
        var s = service.GetStatus(); Clear("Black Ops II", "Plutonium T6  •  Zombies");
        if (!s.PlutoniumFound) footer.Text = "Plutonium was not found. Run it once, then return here."; else if (s.PlutoniumRunning) footer.Text = "Close Plutonium before installing or removing files."; else footer.Text = $"Plutonium: {s.Root}";
        var cards = Cards();
        cards.Controls.Add(Card("Quality of Life", "Installs or updates the five mod files. Saved menu settings stay in place.", s.Mod, "Install mod", async () => await service.InstallModAsync(false, Reporter()), true));
        cards.Controls.Add(Card("HD texture pack", "Downloads the latest texture pack when it is not beside this app. Controller art and the HUD blood splat stay untouched.", s.Textures, "Install with backup", async () => await service.InstallPackAsync("images", true, Reporter())));
        cards.Controls.Add(Card("Custom sounds", "Downloads and installs the sound pack under Plutonium storage. The original game files stay untouched.", s.Sounds, "Install with backup", async () => await service.InstallPackAsync("zone", true, Reporter())));
        cards.Controls.Add(Card("Controller icons", "Choose PlayStation 5, Nintendo Switch, or Xbox One button prompts.", s.Controller, "Choose controller", ChooseController));
        cards.Controls.Add(Card("ReShade", "Installs the included presets and shader collection. The app keeps a copy for repair.", s.ReShade, "Install ReShade", async () => await service.InstallReShadeAsync(Reporter())));
        cards.Controls.Add(Card("Play now", "Starts Black Ops II Zombies in LAN mode with the Quality of Life mod loaded.", "LAN  •  mod loaded", "Play BO2", () => { service.StartBundled("Play BO2 with mod (LAN).bat"); return Task.CompletedTask; }, true));
        cards.Controls.Add(Card("ReShade watcher", "Keeps ReShade in Plutonium's bin folder while Plutonium updates and starts.", "Runs only while you are playing", "Start watcher", () => { service.StartBundled("Play BO2 with ReShade.bat"); return Task.CompletedTask; }));
        cards.Controls.Add(Card("Latest release", "Open the current Quality of Life release on GitHub.", "github.com/DavidHiFi/T6-QoL", "Check for updates", () => { service.OpenReleases(); return Task.CompletedTask; }));
    }
    private Task ChooseController()
    {
        using var dialog = new Form { Text = "Controller icons", Size = new Size(430, 280), StartPosition = FormStartPosition.CenterParent, BackColor = Color.FromArgb(20, 23, 29), ForeColor = Color.White, FormBorderStyle = FormBorderStyle.FixedDialog, MaximizeBox = false, MinimizeBox = false };
        var selected = ""; foreach (var item in new[] { ("PlayStation 5 (DualSense)", "ps5"), ("Nintendo Switch", "switch"), ("Xbox One", "xbox") }) { var b = Nav(item.Item1, () => { selected = item.Item2; dialog.Close(); }); b.Dock = DockStyle.Top; dialog.Controls.Add(b); }
        dialog.ShowDialog(this); return selected.Length == 0 ? Task.CompletedTask : service.InstallControllerAsync(selected, Reporter());
    }
    private void ShowRemove()
    {
        var s = service.GetStatus(); Clear("Uninstall", "Only files recorded by this installer are removed"); var cards = Cards();
        foreach (var item in new[] { ("Mod", "mod", s.Mod), ("HD textures", "images", s.Textures), ("Custom sounds", "zone", s.Sounds), ("Controller icons", "controller", s.Controller), ("ReShade", "reshade", s.ReShade) })
            cards.Controls.Add(Card(item.Item1, "A saved backup can be restored after this part is removed.", item.Item3, "Remove", () => { if (Confirm($"Remove {item.Item1}?")) service.Remove(item.Item2, Confirm("Restore your backup after removal?", "Restore backup"), Reporter()); return Task.CompletedTask; }));
    }
    private void ShowBackups() { Clear("Backups", "Plain folders under Plutonium storage"); var cards = Cards(); cards.Controls.Add(Card("Open backup folder", "View, copy, or archive your saved files in Explorer.", service.Backups, "Open folder", () => { service.OpenFolder(service.Backups); return Task.CompletedTask; }, true)); }
    private void ShowDetails() { Clear("Details and log", "Installed paths and recorded actions"); var cards = Cards(); cards.Controls.Add(Card("Installer log", "Opens the action log in your default text editor.", service.LogFile, "Open log", () => { service.OpenLog(); return Task.CompletedTask; }, true)); cards.Controls.Add(Card("Plutonium storage", "Opens the T6 storage folder used by the installer.", service.T6, "Open folder", () => { service.OpenFolder(service.T6); return Task.CompletedTask; })); }
    private void ShowAbout() { Clear("Quality of Life Series", "Portable installer  •  v2.16.7"); var cards = Cards(); cards.Controls.Add(Card("About", "A native, self-contained Windows installer for the Quality of Life mods. Its interface follows the Cod LAN Launcher layout. No PowerShell runtime or administrator access is required.", "github.com/DavidHiFi/T6-QoL", "Open project", () => { service.OpenReleases(); return Task.CompletedTask; }, true)); }
}
