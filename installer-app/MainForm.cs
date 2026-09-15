using System.Diagnostics;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace QolSeriesInstaller;

internal sealed class MainForm : Form
{
    private readonly InstallerService service;
    private readonly Panel content = new() { Dock = DockStyle.Fill, BackColor = Color.FromArgb(26, 27, 32), Padding = new Padding(24, 18, 24, 14) };
    private readonly Label footer = new() { Dock = DockStyle.Bottom, Height = 36, ForeColor = Color.FromArgb(170, 175, 185), Padding = new Padding(20, 9, 0, 0), Text = "Ready" };
    private readonly Dictionary<string, RoundButton> navs = [];
    private readonly Image? artwork;
    private Action currentPage = () => { };
    private bool busy;
    private readonly AppSettings settings = AppSettings.Load();
    private NotifyIcon? tray;
    private UpdateCheck? pendingCheck;

    private static Color Crust = Color.FromArgb(20, 21, 24);
    private static Color Mantle = Color.FromArgb(21, 22, 26);
    private static Color Base = Color.FromArgb(26, 27, 32);
    private static Color Surface0 = Color.FromArgb(35, 37, 43);
    private static Color Surface1 = Color.FromArgb(47, 50, 58);
    private static Color Surface2 = Color.FromArgb(57, 61, 70);
    private static Color Overlay0 = Color.FromArgb(122, 128, 139);
    private static Color Overlay2 = Color.FromArgb(154, 160, 172);
    private static Color Subtext0 = Color.FromArgb(178, 184, 196);
    private static Color Ink = Color.FromArgb(232, 234, 238);
    private static Color Teal = Color.FromArgb(79, 156, 249);
    private static Color Sky = Color.FromArgb(108, 176, 255);
    private static Color Green = Color.FromArgb(109, 205, 138);

    private static Font F(float size, bool bold = false) => Ui.F(size, bold);
    private static int Dp(Control c, int value) => Ui.Dp(c, value);


    private static Palette CurrentTheme(AppSettings settings) => Palettes.ByKey(settings.Theme);

    private void ApplyTheme(Palette p, bool rebuild)
    {
        Crust = p.AccentText; Mantle = p.Side; Base = p.Base; Surface0 = p.Card; Surface1 = p.Secondary; Surface2 = p.SecondaryHover;
        Overlay0 = p.Caption; Overlay2 = p.Muted; Subtext0 = p.Sub; Ink = p.Ink; Teal = p.Accent; Sky = p.AccentHover; Green = p.Good;
        BackColor = p.Side; content.BackColor = p.Base; column.BackColor = p.Base; footer.ForeColor = p.Sub; footer.BackColor = p.Side;
        foreach (var nav in navs.Values)
        {
            nav.BackColor = p.Side; nav.HoverColor = Blend(p.Side, p.Card, 0.6f); nav.SelectedColor = p.Card; nav.SelectedForeColor = p.Accent; nav.ForeColor = p.Sub; nav.Invalidate();
        }
        if (side is not null)
        {
            side.BackColor = p.Side;
            foreach (var caption in sectionLabels) { caption.BackColor = p.Side; caption.ForeColor = p.Caption; }
            brandPanel.BackColor = p.Side;
            brandName.BackColor = p.Side; brandName.ForeColor = p.Ink;
            brandSub.BackColor = p.Side; brandSub.ForeColor = p.Caption;
            brandMark.BackColor = p.Card; brandMark.BorderColor = p.Card; brandMark.Invalidate();
        }
        ApplyTitleBar(p);
        if (rebuild) Rebuild();
    }
    private Panel side = null!;
    private readonly List<Label> sectionLabels = [];
    private Panel brandPanel = null!;
    private Label brandName = null!, brandSub = null!;
    private LogoMark brandMark = null!;

    // The title bar follows the theme, and needs a frame change to repaint on an already-shown window.
    private void ApplyTitleBar(Palette p)
    {
        if (!IsHandleCreated) return;
        var dark = p.Dark ? 1 : 0;
        if (DwmSetWindowAttribute(Handle, 20, ref dark, 4) != 0) DwmSetWindowAttribute(Handle, 19, ref dark, 4);
        SetWindowPos(Handle, IntPtr.Zero, 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0004 | 0x0020);
    }

    private static Color Blend(Color a, Color b, float t) => Color.FromArgb((int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));

    internal MainForm(InstallerService service)
    {
        this.service = service;
        Text = "Quality of Life Series"; MinimumSize = new Size(880, 580); Size = new Size(1040, 700); StartPosition = FormStartPosition.CenterScreen;
        ForeColor = Ink; Font = F(10); DoubleBuffered = true;
        var iconPath = Path.Combine(service.Payload, "qol_installer.ico");
        Icon = File.Exists(iconPath) ? new Icon(iconPath) : Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        artwork = File.Exists(iconPath) ? new Icon(iconPath, new Size(64, 64)).ToBitmap() : null;
        side = new Panel { Dock = DockStyle.Left, Width = 238, BackColor = Mantle, Padding = new Padding(12, 14, 12, 12), AutoScroll = true };
        side.Controls.Add(NavItem("\uE946", "About", ShowAbout));
        side.Controls.Add(NavItem("\uE8A5", "Details and log", ShowDetails));
        side.Controls.Add(NavItem("\uE713", "Settings", ShowSettings));
        side.Controls.Add(NavItem("\uE74D", "Uninstall", ShowUninstall));
        side.Controls.Add(NavItem("\uE8B7", "Backups", ShowBackups));
        side.Controls.Add(NavItem("\uE71B", "Start menu shortcuts", ShowShortcuts));
        side.Controls.Add(NavItem("\uE790", "ReShade", ShowReShade));
        side.Controls.Add(Section("TOOLS"));
        side.Controls.Add(NavItem("\uE7FC", "Black Ops III (T7)", () => ShowEmptyGame("Black Ops III", "T7")));
        side.Controls.Add(NavItem("\uE7FC", "Black Ops II (T6)", ShowT6));
        side.Controls.Add(NavItem("\uE7FC", "Black Ops (T5)", () => ShowGame("t5", "T5", "Black Ops")));
        side.Controls.Add(NavItem("\uE7FC", "World at War (T4)", () => ShowGame("t4", "T4", "World at War")));
        side.Controls.Add(Section("GAMES"));
        side.Controls.Add(NavItem("\uE80F", "Home", ShowHome));
        side.Controls.Add(Brand());
        column.BackColor = Base;
        content.Controls.Add(column);
        content.Resize += (_, _) => FitColumn();
        Controls.Add(content); Controls.Add(side); Controls.Add(footer);
        ApplyTheme(CurrentTheme(settings), false);
        SetTray(settings.Tray, false);
        ShowHome();
        if (settings.AutoUpdate) _ = StartupCheckAsync();
    }

    private Control Brand()
    {
        brandPanel = new Panel { Dock = DockStyle.Top, Height = Dp(this, 74), BackColor = Mantle };
        brandMark = new LogoMark { Location = new Point(Dp(this, 6), Dp(this, 4)), Size = new Size(Dp(this, 38), Dp(this, 38)), Radius = 10, BackColor = Surface0, BorderColor = Surface0, Glyph = "\uE7FC", GlyphColor = Teal, Artwork = artwork };
        brandName = new Label { Location = new Point(Dp(this, 54), Dp(this, 5)), AutoSize = true, Text = "Quality of Life", Font = F(10.5f, true), ForeColor = Ink, BackColor = Mantle, UseMnemonic = false };
        brandSub = new Label { Location = new Point(Dp(this, 54), Dp(this, 26)), AutoSize = true, Text = "Mod manager", Font = F(8), ForeColor = Overlay0, BackColor = Mantle, UseMnemonic = false };
        brandPanel.Controls.Add(brandMark); brandPanel.Controls.Add(brandName); brandPanel.Controls.Add(brandSub); return brandPanel;
    }

    private Label Section(string caption)
    {
        var label = new Label { Dock = DockStyle.Top, Height = Dp(this, 26), Text = caption, Font = F(7.5f), ForeColor = Overlay0, Padding = new Padding(Dp(this, 12), Dp(this, 9), 0, 0), BackColor = Mantle, UseMnemonic = false };
        sectionLabels.Add(label);
        return label;
    }
    private Control NavItem(string glyph, string text, Action action)
    {
        var b = new RoundButton { Dock = DockStyle.Top, Height = 36, Glyph = glyph, Text = text, Radius = 9, BackColor = Mantle, HoverColor = Blend(Mantle, Surface0, 0.6f), SelectedColor = Surface0, SelectedForeColor = Teal, ForeColor = Subtext0, Font = F(9), Cursor = Cursors.Hand };
        b.Click += (_, _) => { if (busy || overlay is not null) { footer.Text = "One moment - still working."; return; } action(); };
        tips.SetToolTip(b, text); navs[text] = b; return b;
    }
    private void Select(string name) { foreach (var pair in navs) { pair.Value.Selected = pair.Key == name; pair.Value.Invalidate(); } }

    // The page title and the rows below it live in one centred column, so they can never end up
    // on two different left edges when the window is widened.
    private readonly Panel column = new() { Dock = DockStyle.Fill };

    private void FitColumn()
    {
        var avail = content.DisplayRectangle.Width;
        if (avail <= 0) return;
        var width = Math.Max(Dp(this, 360), Math.Min(Dp(this, 900), avail));
        var side = Math.Max(0, (avail - width) / 2);
        if (column.Padding.Left != side) column.Padding = new Padding(side, 0, side, 0);
    }

    private void Clear(string title, string subtitle)
    {
        column.Controls.Clear();
        var sub = new Label { Dock = DockStyle.Top, Height = Dp(this, 28), Text = subtitle, ForeColor = Overlay2, Font = F(9), BackColor = Base, AutoEllipsis = true, UseMnemonic = false, TextAlign = ContentAlignment.TopLeft };
        var head = new Label { Dock = DockStyle.Top, Height = Dp(this, 42), Text = title, ForeColor = Ink, Font = F(17, true), BackColor = Base, AutoEllipsis = true, UseMnemonic = false, TextAlign = ContentAlignment.MiddleLeft };
        tips.SetToolTip(sub, subtitle);
        column.Controls.Add(sub); column.Controls.Add(head);
        FitColumn();
    }
    // The native scrollbar follows the system's dark/light app mode, not ours, so it renders black
    // on the light themes. Hide both native bars and draw our own thin rail from the palette; the
    // scrolling itself is still AutoScroll, so the wheel and keyboard behave exactly as normal.
    private sealed class PageFlow : FlowLayoutPanel
    {
        [DllImport("user32.dll")] private static extern bool ShowScrollBar(IntPtr hWnd, int bar, bool show);
        private const int SbBoth = 3;
        internal event Action? ViewChanged;
        internal PageFlow() => AutoScroll = true;
        private void HideNative() { if (IsHandleCreated) ShowScrollBar(Handle, SbBoth, false); }
        private void Changed() { HideNative(); ViewChanged?.Invoke(); }
        protected override void OnHandleCreated(EventArgs e) { base.OnHandleCreated(e); HideNative(); }
        protected override void OnLayout(LayoutEventArgs e) { base.OnLayout(e); Changed(); }
        protected override void OnPaint(PaintEventArgs e) { base.OnPaint(e); HideNative(); }
        protected override void OnScroll(ScrollEventArgs e) { base.OnScroll(e); Changed(); }
        protected override void OnMouseWheel(MouseEventArgs e) { base.OnMouseWheel(e); Changed(); }
        internal int ViewHeight => ClientSize.Height;
        internal int ContentHeight => DisplayRectangle.Height;
        internal int Offset
        {
            get => -AutoScrollPosition.Y;
            set { AutoScrollPosition = new Point(0, Math.Max(0, value)); Changed(); }
        }
    }

    private sealed class Rail : Control
    {
        private readonly PageFlow flow;
        internal Color Thumb, ThumbHot;
        private bool hot, dragging;
        private int grab;
        internal Rail(PageFlow owner)
        {
            flow = owner;
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            flow.ViewChanged += () => { if (IsHandleCreated) Invalidate(); };
            MouseLeave += (_, _) => { hot = false; Invalidate(); };
        }
        private int Track => Math.Max(1, Height - 8);
        private int ThumbHeight
        {
            get
            {
                int view = flow.ViewHeight, content = flow.ContentHeight;
                return content <= 0 ? 0 : Math.Max(28, (int)((long)Track * view / content));
            }
        }
        private Rectangle ThumbRect()
        {
            int view = flow.ViewHeight, content = flow.ContentHeight;
            if (view <= 0 || content <= view) return Rectangle.Empty;
            int h = ThumbHeight, span = Math.Max(1, Track - h), max = content - view;
            var y = 4 + (int)((long)span * Math.Clamp(flow.Offset, 0, max) / max);
            return new Rectangle(Math.Max(0, Width - 9), y, 5, h);
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.Clear(BackColor);
            var r = ThumbRect();
            if (r.IsEmpty) return;
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using var brush = new SolidBrush(hot || dragging ? ThumbHot : Thumb);
            using var path = RoundedPanel.RoundedPath(r, 3);
            e.Graphics.FillPath(brush, path);
        }
        private void MoveThumbTo(int top)
        {
            int view = flow.ViewHeight, content = flow.ContentHeight;
            if (content <= view) return;
            var span = Math.Max(1, Track - ThumbHeight);
            flow.Offset = (int)((long)(content - view) * Math.Clamp(top - 4, 0, span) / span);
        }
        protected override void OnMouseDown(MouseEventArgs e)
        {
            var r = ThumbRect();
            if (r.IsEmpty) return;
            if (e.Y >= r.Y && e.Y < r.Bottom) { dragging = true; grab = e.Y - r.Y; }
            else MoveThumbTo(e.Y - r.Height / 2);
            Invalidate();
        }
        protected override void OnMouseMove(MouseEventArgs e)
        {
            var r = ThumbRect();
            var over = !r.IsEmpty && e.Y >= r.Y && e.Y < r.Bottom;
            if (over != hot) { hot = over; Invalidate(); }
            if (dragging) MoveThumbTo(e.Y - grab);
        }
        protected override void OnMouseUp(MouseEventArgs e) { dragging = false; Invalidate(); }
        protected override void OnMouseWheel(MouseEventArgs e) => flow.Offset -= e.Delta;
    }

    private FlowLayoutPanel Page()
    {
        var host = new Panel { Dock = DockStyle.Fill, BackColor = Base };
        var p = new PageFlow { Dock = DockStyle.Fill, BackColor = Base };
        ConfigureFlow(p);
        var rail = new Rail(p) { Width = Dp(this, 12), BackColor = Base, Thumb = Overlay0, ThumbHot = Overlay2, Anchor = AnchorStyles.Top | AnchorStyles.Right | AnchorStyles.Bottom };
        host.Controls.Add(p);
        host.Controls.Add(rail);
        void PlaceRail() { rail.Bounds = new Rectangle(host.ClientSize.Width - rail.Width, 0, rail.Width, host.ClientSize.Height); rail.BringToFront(); }
        host.Resize += (_, _) => PlaceRail();
        column.Controls.Add(host); host.BringToFront(); PlaceRail();
        return p;
    }
    private void ConfigureFlow(FlowLayoutPanel p)
    {
        var dark = CurrentTheme(settings).Dark;
        p.FlowDirection = FlowDirection.TopDown; p.WrapContents = false; p.AutoScroll = true; p.Padding = new Padding(0, 8, 0, 12);
        // Dark themes get the dark overlay scrollbar; light themes reset to the default so the
        // scrollbar does not render black against a white page.
        p.HandleCreated += (_, _) => SetWindowTheme(p.Handle, dark ? "DarkMode_Explorer" : null, null);
        var laying = false;
        // The centring is done by the column; every row just fills its width. Re-measure after each
        // pass: the first one can bring in a vertical scrollbar, which narrows the client area, and
        // a row still sized for the old width would leave a horizontal scrollbar behind.
        void Fit()
        {
            if (laying || p.Controls.Count == 0) return;
            laying = true;
            try
            {
                for (var pass = 0; pass < 4; pass++)
                {
                    var width = Math.Max(Dp(p, 200), p.ClientSize.Width - Dp(p, 4));
                    var changed = false;
                    foreach (Control c in p.Controls) if (c.Width != width) { c.Width = width; changed = true; }
                    if (!changed) break;
                    p.PerformLayout();
                }
            }
            finally { laying = false; }
        }
        p.Resize += (_, _) => Fit();
        p.ControlAdded += (_, _) => Fit();
        p.DpiChangedAfterParent += (_, _) => Fit();
    }
    private FlowLayoutPanel Cards() => Page();
    private Panel Hero(string title, string installed, string missing, string button, Func<Task> action)
    {
        var hero = new RoundedPanel { Radius = 12, Margin = new Padding(0, 0, 0, 10), BackColor = Surface0, BorderColor = Surface0, HoverBorderColor = Surface0, Padding = new Padding(0) };
        var mark = new LogoMark { Radius = 10, BackColor = Surface1, BorderColor = Surface1, Glyph = "\uE7FC", GlyphColor = Teal, Artwork = artwork };
        var head = new Label { AutoSize = false, AutoEllipsis = true, UseMnemonic = false, TextAlign = ContentAlignment.MiddleLeft, Text = title, ForeColor = Ink, Font = F(13, true), BackColor = Surface0 };
        var line1 = new Label { AutoSize = false, AutoEllipsis = true, UseMnemonic = false, TextAlign = ContentAlignment.MiddleLeft, Text = installed, ForeColor = installed.StartsWith("Nothing") ? Overlay2 : Green, Font = F(9), BackColor = Surface0 };
        var line2 = new Label { AutoSize = false, AutoEllipsis = true, UseMnemonic = false, TextAlign = ContentAlignment.MiddleLeft, Text = missing, ForeColor = missing.StartsWith("Everything") ? Green : Overlay2, Font = F(9), BackColor = Surface0 };
        var btn = new RoundButton { Radius = 16, Text = button, BackColor = Teal, HoverColor = Sky, ForeColor = Crust, Font = F(9, true), Cursor = Cursors.Hand };
        btn.Click += async (_, _) => await Run(action, btn);
        hero.Controls.Add(mark); hero.Controls.Add(head); hero.Controls.Add(line1); hero.Controls.Add(line2); hero.Controls.Add(btn);
        tips.SetToolTip(head, title); tips.SetToolTip(line1, installed); tips.SetToolTip(line2, missing);
        void LayoutHero()
        {
            int pad = Dp(hero, 16), left = Dp(hero, 68);
            hero.Height = Dp(hero, 94);
            mark.Bounds = new Rectangle(pad, (hero.Height - Dp(hero, 38)) / 2, Dp(hero, 38), Dp(hero, 38));
            btn.Size = new Size(Dp(hero, 168), Dp(hero, 34));
            btn.Location = new Point(hero.Width - btn.Width - pad, (hero.Height - btn.Height) / 2);
            var room = Math.Max(Dp(hero, 120), hero.Width - btn.Width - pad - left - Dp(hero, 14));
            head.Bounds = new Rectangle(left, Dp(hero, 13), room, Dp(hero, 26));
            line1.Bounds = new Rectangle(left, Dp(hero, 41), room, Dp(hero, 20));
            line2.Bounds = new Rectangle(left, Dp(hero, 61), room, Dp(hero, 20));
        }
        hero.Resize += (_, _) => LayoutHero();
        hero.DpiChangedAfterParent += (_, _) => LayoutHero();
        LayoutHero();
        return hero;
    }
    private static string InstalledText(InstallStatus s)
    {
        var list = new List<string>();
        if (s.Mod != "not installed") list.Add("mod " + s.Mod);
        if (s.Textures == "installed") list.Add("HD textures");
        if (s.Sounds == "installed") list.Add("custom sounds");
        if (s.Controller != "game defaults") list.Add(s.Controller == "ps5" ? "PS5 icons" : s.Controller + " icons");
        if (s.ReShade == "installed") list.Add("ReShade");
        if (s.Shortcuts != "not added") list.Add("Start menu shortcuts");
        return list.Count == 0 ? "Nothing is installed yet." : "Installed:  " + string.Join("  ·  ", list);
    }
    private static string MissingText(InstallStatus s)
    {
        var list = new List<string>();
        if (s.Mod == "not installed") list.Add("the mod");
        if (s.Textures != "installed") list.Add("HD textures");
        if (s.Sounds != "installed") list.Add("custom sounds");
        if (s.Controller == "game defaults") list.Add("controller icons");
        if (s.ReShade != "installed") list.Add("ReShade");
        if (s.Shortcuts == "not added") list.Add("Start menu shortcuts");
        return list.Count == 0 ? "Everything is installed." : "Not installed:  " + string.Join("  ·  ", list);
    }
    // The hero rides in the same centred column as the rows, so the two never sit on different
    // left edges when the window is maximised.
    private FlowLayoutPanel HeroPage(Panel hero)
    {
        var cards = Page();
        cards.Controls.Add(hero);
        return cards;
    }
    // Green means "this is on / installed". Everything else - paths, counts, hints - stays muted,
    // so a status can never contradict the row it sits on.
    private static bool StatusGood(string status)
    {
        var s = status.Trim().ToLowerInvariant();
        if (s.Length == 0) return false;
        if (s is "installed" or "on" or "set" or "added" or "in use" or "backup found") return true;
        return s.StartsWith("mod v") || s.StartsWith("ps5") || s.StartsWith("switch") || s.StartsWith("xbox");
    }

    private readonly ToolTip tips = new() { AutoPopDelay = 12000, InitialDelay = 400, ReshowDelay = 100 };
    private Panel Card(string title, string description, string status, string button, Func<Task> action, bool primary = false, Action? refresh = null)
    {
        var row = new Row();
        row.Title.Text = title;
        row.Description.Text = description;
        row.Status.Text = status;
        row.Status.ForeColor = StatusGood(status) ? Green : Overlay2;
        row.Button.Text = button;
        row.Button.BackColor = primary ? Teal : Surface1;
        row.Button.HoverColor = primary ? Sky : Surface2;
        row.Button.ForeColor = primary ? Crust : Ink;
        row.Button.Click += async (_, _) => await Run(action, row.Button, refresh);
        tips.SetToolTip(row.Description, description);
        tips.SetToolTip(row.Status, status);
        return row;
    }
    private Label Caption(string text) => new() { AutoSize = false, Height = 28, Text = text, Font = F(8), ForeColor = Overlay0, Margin = new Padding(0, 10, 0, 0), Padding = new Padding(2, 0, 0, 4), TextAlign = ContentAlignment.BottomLeft, BackColor = Base, UseMnemonic = false };
    private async Task Run(Func<Task> action, Control source, Action? refresh = null)
    {
        if (busy || overlay is not null) { footer.Text = "One moment - still working."; return; }
        busy = true; footer.Text = "Working...";
        try { await action(); footer.Text = "Done"; refresh?.Invoke(); }
        catch (Exception ex) { footer.Text = "Stopped"; await Tell("That did not work:\n\n" + ex.Message); }
        finally { busy = false; }
    }
    private void Rebuild() => currentPage();

    private Panel? overlay;

    // A dimmed snapshot of the page, not an opaque panel: the page stays readable behind the question
    // instead of going blank.
    private sealed class Scrim : Panel
    {
        internal Image? Shot;
        internal Point ShotOffset;
        internal Color Veil = Color.FromArgb(170, 0, 0, 0);
        internal Scrim()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
            // Once the panel outgrows the snapshot the old page would sit as a stranded island,
            // so drop it and fall back to a plain dimmed backdrop.
            Resize += (_, _) =>
            {
                if (Shot is not null && (ShotOffset.X + Shot.Width < ClientSize.Width || ShotOffset.Y + Shot.Height < ClientSize.Height))
                {
                    Shot.Dispose(); Shot = null;
                }
                Invalidate();
            };
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.Clear(BackColor);
            if (Shot is not null) e.Graphics.DrawImage(Shot, ShotOffset.X, ShotOffset.Y, Shot.Width, Shot.Height);
            using var veil = new SolidBrush(Veil);
            e.Graphics.FillRectangle(veil, ClientRectangle);
        }
        protected override void Dispose(bool disposing) { if (disposing) { Shot?.Dispose(); Shot = null; } base.Dispose(disposing); }
    }

    private Scrim NewScrim()
    {
        var theme = CurrentTheme(settings);
        var s = new Scrim { Dock = DockStyle.Fill, BackColor = theme.Base, Veil = Color.FromArgb(theme.Dark ? 168 : 120, 0, 0, 0) };
        if (content.ClientSize.Width > 0 && content.ClientSize.Height > 0)
        {
            var shot = new Bitmap(content.ClientSize.Width, content.ClientSize.Height);
            // The scrim is docked inside content's padding, so the snapshot has to slide back by it
            // or the page appears duplicated and shifted behind the card.
            try
            {
                content.DrawToBitmap(shot, new Rectangle(0, 0, shot.Width, shot.Height));
                s.Shot = shot;
                s.ShotOffset = new Point(-content.Padding.Left, -content.Padding.Top);
            }
            catch { shot.Dispose(); }
        }
        return s;
    }

    private void CentreCard(Panel host, Control card)
    {
        void Place() => card.Location = new Point(Math.Max(0, (host.ClientSize.Width - card.Width) / 2), Math.Max(0, (host.ClientSize.Height - card.Height) / 2));
        host.Resize += (_, _) => Place();
        host.HandleCreated += (_, _) => Place();
        Place();
    }

    private async Task<string?> Choose(string message, params (string Text, string Key, bool Primary)[] options)
    {
        var tcs = new TaskCompletionSource<string?>();
        var wasBusy = busy; busy = true;
        var scrim = NewScrim(); overlay = scrim;
        int pad = Dp(this, 28), rowH = Dp(this, 52), btnH = Dp(this, 40);
        var cardWidth = Math.Min(Dp(this, 560), Math.Max(Dp(this, 320), content.ClientSize.Width - Dp(this, 48)));
        var textWidth = cardWidth - pad * 2;
        var font = F(10);
        // Measure the real wrapped message instead of assuming one line, so long questions are never cut off.
        var roomForText = Math.Max(Dp(this, 40), content.ClientSize.Height - Dp(this, 60) - options.Length * rowH - pad * 2);
        var textHeight = Math.Min(roomForText, Math.Max(Dp(this, 24), TextRenderer.MeasureText(message, font, new Size(textWidth, 0), TextFormatFlags.WordBreak | TextFormatFlags.TextBoxControl).Height + Dp(this, 6)));
        var height = pad + textHeight + Dp(this, 22) + options.Length * rowH - (rowH - btnH) + Dp(this, 18);

        var card = new RoundedPanel { Width = cardWidth, Height = height, BackColor = Surface0, BorderColor = Surface1, HoverBorderColor = Surface1, Radius = 16, Padding = new Padding(0) };
        var label = new Label { AutoSize = false, Bounds = new Rectangle(pad, pad, textWidth, textHeight), Text = message, ForeColor = Ink, Font = font, BackColor = Surface0, UseMnemonic = false };
        card.Controls.Add(label);
        var y = pad + textHeight + Dp(this, 22);
        foreach (var option in options)
        {
            var btn = new RoundButton { Bounds = new Rectangle(pad, y, textWidth, btnH), Radius = btnH / 2, Text = option.Text, BackColor = option.Primary ? Teal : Surface1, HoverColor = option.Primary ? Sky : Surface2, ForeColor = option.Primary ? Crust : Ink, Font = F(9.5f, true), Cursor = Cursors.Hand, TextAlign = ContentAlignment.MiddleCenter };
            var key = option.Key;
            btn.Click += (_, _) => tcs.TrySetResult(key);
            card.Controls.Add(btn); y += rowH;
        }
        scrim.Controls.Add(card);
        CentreCard(scrim, card);
        content.Controls.Add(scrim); scrim.BringToFront();
        var result = await tcs.Task;
        content.Controls.Remove(scrim); scrim.Dispose(); overlay = null; busy = wasBusy;
        return result;
    }
    private Task Tell(string message, string ok = "OK") => Choose(message, (ok, "ok", true));
    private async Task<bool> Ask(string message, string yes = "Yes", string no = "No") => await Choose(message, (yes, "yes", true), (no, "no", false)) == "yes";

    private void ShowHome()
    {
        currentPage = ShowHome;
        var s = service.GetStatus(); Clear("Home", "Discover the Quality of Life series  •  Plutonium"); Select("Home");
        footer.Text = PageFooter(s);
        var cards = HeroPage(Hero("Black Ops II  •  Zombies", InstalledText(s), MissingText(s), "Open Black Ops II", () => { ShowT6(); return Task.CompletedTask; }));
        if (pendingCheck is { ModUpdate: true })
            cards.Controls.Add(Card($"Mod update {pendingCheck.LatestTag}", "A newer release is on GitHub. It updates the five mod files and keeps your settings.", "update available", "Install update", async () => { await service.InstallUpdateAsync(Reporter()); await Tell("Installed. Your settings were kept."); }, true, ShowHome));
        if (pendingCheck is { AppUpdate: true })
            cards.Controls.Add(Card($"App update {pendingCheck.LatestTag}", "A newer version of this tool is on GitHub.", "update available", "Update app", async () => { if (await Ask("The app will close, update itself, and open again.", "Update now", "Not now")) { await service.InstallAppUpdateAsync(Reporter()); Application.Exit(); } }, true, ShowHome));
        cards.Controls.Add(Card("World at War (T4)", "Play World at War through Plutonium, online or LAN.", "no mod yet", "Open", () => { ShowGame("t4", "T4", "World at War"); return Task.CompletedTask; }));
        cards.Controls.Add(Card("Black Ops (T5)", "Play Black Ops through Plutonium, online or LAN.", "no mod yet", "Open", () => { ShowGame("t5", "T5", "Black Ops"); return Task.CompletedTask; }));
        cards.Controls.Add(Card("Black Ops III (T7)", "No Quality of Life mod yet - Black Ops II is the current focus.", "nothing yet", "About", () => Tell("There is no Quality of Life mod for Black Ops III yet.\n\nDevelopment has not started; Black Ops II is the current focus.\n\nIts home will be github.com/DavidHiFi/T7-QoL.")));
        cards.Controls.Add(Card("Check for a newer version", "Asks GitHub whether a newer release exists, and can install it for you.", "github.com/DavidHiFi/T6-QoL", "Check now", CheckUpdates, false, ShowHome));
    }
    private static string PageFooter(InstallStatus s) => !s.PlutoniumFound ? "Plutonium was not found. Run it once, then return here." : s.PlutoniumRunning ? "Close Plutonium before installing or removing files." : $"Plutonium: {s.Root}";

    private void ShowT6()
    {
        currentPage = ShowT6;
        var s = service.GetStatus(); Clear("Black Ops II", "Plutonium T6  •  Zombies"); Select("Black Ops II (T6)"); footer.Text = PageFooter(s);
        var cards = HeroPage(Hero("Quality of Life", InstalledText(s), MissingText(s), "Play BO2 (LAN)", () => { LaunchGame("t6", "zm", true, false); return Task.CompletedTask; }));
        cards.Controls.Add(Card("EVERYTHING", "Installs the mod, HD textures and custom sounds in order.", "recommended", "Install all", InstallEverything, true, ShowT6));
        cards.Controls.Add(Card("The mod", "Installs or updates the five mod files. Saved menu settings stay in place.", s.Mod, "Install", InstallMod, true, ShowT6));
        cards.Controls.Add(Card("HD texture pack", "Downloads the latest texture pack when it is not beside this app, with a backup of yours first.", s.Textures, "Install", () => InstallPack("images"), false, ShowT6));
        cards.Controls.Add(Card("Custom sounds", "Downloads and installs the sound pack under Plutonium storage, with a backup of yours first.", s.Sounds, "Install", () => InstallPack("zone"), false, ShowT6));
        cards.Controls.Add(Card("Controller icons", "Choose PlayStation 5, Nintendo Switch, or Xbox One prompts.", s.Controller, "Choose", () => { ShowController(); return Task.CompletedTask; }, false, ShowT6));
        var t6mods = service.GetInstalledMods("t6");
        cards.Controls.Add(Card("Installed mods", "Every mod installed for Black Ops II. Install another from a file, or remove one.", t6mods.Count == 1 ? "1 mod" : $"{t6mods.Count} mods", "Manage", () => { ShowMods("t6", "T6", "Black Ops II"); return Task.CompletedTask; }, false, ShowT6));
        cards.Controls.Add(Card("Play Zombies", "Normal online launch. The mod can be picked in Zombies -> Mods.", "online", "Play online", () => { LaunchGame("t6", "zm", false, false); return Task.CompletedTask; }, false, ShowT6));
        cards.Controls.Add(Card("Play Multiplayer", "Normal online launch of Black Ops II multiplayer.", "online", "Play online", () => { LaunchGame("t6", "mp", false, false); return Task.CompletedTask; }, false, ShowT6));
        cards.Controls.Add(Card("Play with ReShade", "LAN launch plus the ReShade watchdog. Closing that window stops it.", "LAN + watchdog", "Play", () => { LaunchGame("t6", "zm", true, true); return Task.CompletedTask; }, false, ShowT6));
    }

    private void ShowReShade()
    {
        currentPage = ShowReShade;
        var s = service.GetStatus(); Clear("ReShade", "Improves the visuals for every Plutonium game - BO1, MW3, WaW and BO2"); Select("ReShade"); footer.Text = PageFooter(s);
        var cards = Cards();
        cards.Controls.Add(Card("Install ReShade", "Installs the included presets and shader collection. Keeps a copy for repair.", s.ReShade, "Install", InstallReShade, true, ShowReShade));
        cards.Controls.Add(Card("Start ReShade watchdog only", "Puts ReShade back when Plutonium clears it. Close its window to stop it.", "own window", "Start", () => { service.StartWatchdog(); footer.Text = "Watchdog started - close its window to stop it."; return Task.CompletedTask; }, false, ShowReShade));
    }

    private void ShowShortcuts()
    {
        currentPage = ShowShortcuts;
        var s = service.GetStatus(); Clear("Start menu shortcuts", "A group called \"Quality of Life Series\""); Select("Start menu shortcuts"); footer.Text = PageFooter(s); var cards = Cards();
        cards.Controls.Add(Card("Add both", "Quality of Life Series Launcher and Plutonium ReShade Watcher.", s.Shortcuts, "Add both", () => { service.InstallShortcuts(true, true, Reporter()); return Task.CompletedTask; }, true, ShowShortcuts));
        cards.Controls.Add(Card("Just the launcher", "One entry that opens this installer.", s.Shortcuts, "Add launcher", () => { service.InstallShortcuts(true, false, Reporter()); return Task.CompletedTask; }, false, ShowShortcuts));
        cards.Controls.Add(Card("Just the watcher", "One entry that starts the ReShade helper.", s.Shortcuts, "Add watcher", () => { service.InstallShortcuts(false, true, Reporter()); return Task.CompletedTask; }, false, ShowShortcuts));
        cards.Controls.Add(Card("Remove the shortcuts", "Takes both entries off again, and the group folder with them.", s.Shortcuts, "Remove", async () => { if (await Ask("Remove the Start menu shortcuts?")) service.RemoveShortcuts(); }, false, ShowShortcuts));
    }

    private void ShowUninstall()
    {
        currentPage = ShowUninstall;
        var s = service.GetStatus(); Clear("Uninstall", "Only files recorded by this installer are removed"); Select("Uninstall"); footer.Text = PageFooter(s); var cards = Cards();
        var parts = new[]
        {
            ("The mod", "mod", s.Mod, "The five mod files under storage\\t6\\mods. Your saved menu settings stay."),
            ("HD textures", "images", s.Textures, "The texture pack under storage\\t6\\images."),
            ("Custom sounds", "zone", s.Sounds, "The sound pack under storage\\t6\\zone."),
            ("Controller icons", "controller", s.Controller, "The button prompt images, so the game's own prompts come back."),
            ("ReShade", "reshade", s.ReShade, "The ReShade DLL, presets and shader collection.")
        };
        var installed = parts.Count(p => StatusGood(p.Item3));
        cards.Controls.Add(Card("Remove everything", "Every part below plus the Start menu shortcuts. Your saved menu settings are kept.", installed == 1 ? "1 part installed" : $"{installed} parts installed", "Remove all", RemoveEverything, true, ShowUninstall));
        foreach (var item in parts)
            cards.Controls.Add(Card(item.Item1, item.Item4 + " A backup can be put back.", item.Item3, "Remove", async () => { if (await Ask($"Remove {item.Item1}?")) service.Remove(item.Item2, service.HasBackup(item.Item2) && await Ask("Put your backup back after removal?", "Restore it", "Just remove"), Reporter()); }, false, ShowUninstall));
    }

    private void ShowBackups()
    {
        currentPage = ShowBackups;
        Clear("Backups", "One plain folder per thing, under Plutonium storage"); Select("Backups"); footer.Text = PageFooter(service.GetStatus()); var cards = Cards();
        foreach (var b in service.GetBackups())
        {
            var status = b.Exists ? $"{b.When:d MMM yyyy}" : b.LiveFiles == 0 ? "nothing to back up" : $"{b.LiveFiles} files now";
            cards.Controls.Add(Card(b.Label, "Kept separately from the mod, so an install can never be the reason you lose them.", status, "Manage", () => { ShowBackupOne(b.Kind); return Task.CompletedTask; }));
        }
        cards.Controls.Add(Card("Open backup folder", "View, copy, or archive your saved files in Explorer.", service.Backups, "Open folder", () => { service.OpenFolder(service.Backups); return Task.CompletedTask; }, true));
    }

    private void ShowBackupOne(string kind)
    {
        currentPage = () => ShowBackupOne(kind);
        var b = service.GetBackup(kind);
        var subtitle = b.Exists ? $"Saved {b.When:d MMM yyyy, HH:mm}  •  {b.Files} file(s)" : b.LiveFiles == 0 ? "There is nothing to back up yet" : $"No backup yet  •  {b.LiveFiles} file(s) on this PC now - your files are untouched";
        Clear(b.Label, subtitle); Select("Backups"); footer.Text = PageFooter(service.GetStatus()); var cards = Cards();
        if (b.Exists)
        {
            cards.Controls.Add(Card("Put my backup back", $"Copies {b.Title} out of the backup, over what is there now.", "backup found", "Restore", () => service.RestoreKind(kind, Reporter()) ? Task.CompletedTask : throw new InvalidOperationException("That backup is empty - nothing to put back."), true, () => ShowBackupOne(kind)));
            cards.Controls.Add(Card("Back up again", "Replaces the saved backup with what is on this PC now.", "overwrite", "Replace", () => { service.BackupKind(kind, true, Reporter()); return Task.CompletedTask; }, false, () => ShowBackupOne(kind)));
            cards.Controls.Add(Card("Delete this backup", "The files on your PC are untouched.", $"{b.Files} files", "Delete", async () => { if (await Ask($"Delete the backup of {b.Title}?")) service.DeleteBackup(kind); }, false, () => ShowBackupOne(kind)));
        }
        else cards.Controls.Add(Card("Back it up now", "Copies your files into the backups folder, separate from the mod.", $"{b.LiveFiles} files", "Back up", () => { service.BackupKind(kind, false, Reporter()); return Task.CompletedTask; }, true, () => ShowBackupOne(kind)));
        cards.Controls.Add(Card("Back to Backups", "Returns to the list. Nothing is changed.", "list", "Back", () => { ShowBackups(); return Task.CompletedTask; }));
    }

    private void ShowController()
    {
        currentPage = ShowController;
        var s = service.GetStatus(); Clear("Controller icons", "PlayStation 5, Nintendo Switch or Xbox One prompts"); Select("Black Ops II (T6)"); footer.Text = PageFooter(s); var cards = Cards();
        foreach (var item in new[] { ("PlayStation 5 (DualSense)", "ps5"), ("Nintendo Switch", "switch"), ("Xbox One", "xbox") })
            cards.Controls.Add(Card(item.Item1, "Swaps the on-screen button prompts. Picking another pack swaps it over cleanly.", s.Controller == item.Item2 ? "installed" : "not installed", "Install", () => service.InstallControllerAsync(item.Item2, Reporter()), s.Controller == item.Item2, () => ShowController()));
        cards.Controls.Add(Card("Back to Black Ops II", "Returns to the mod screen. Nothing is changed.", "back", "Back", () => { ShowT6(); return Task.CompletedTask; }));
    }

    private void ShowSettings()
    {
        currentPage = ShowSettings;
        var current = CurrentTheme(settings);
        Clear("Settings", "Themes and app options"); Select("Settings"); footer.Text = PageFooter(service.GetStatus());
        var page = Page();
        page.Controls.Add(Caption("THEME"));
        page.Controls.Add(ThemeGrid(page, current));
        page.Controls.Add(Card("Reset to default", $"Go back to {Palettes.Default.Name}.", CurrentTheme(settings).Key == Palettes.Default.Key ? "in use" : "available", "Use default", () => { settings.Theme = Palettes.Default.Key; settings.Save(); ApplyTheme(Palettes.Default, true); return Task.CompletedTask; }, false, ShowSettings));
        page.Controls.Add(Caption("UPDATES"));
        page.Controls.Add(Card("Check for updates", "Checks GitHub for a newer mod release and a newer version of this app.", "github.com/DavidHiFi/T6-QoL", "Check now", CheckUpdates, false, ShowSettings));
        page.Controls.Add(Card("Automatic update checks", "Asks GitHub for a newer release every time this app opens.", settings.AutoUpdate ? "on" : "off", settings.AutoUpdate ? "Turn off" : "Turn on", () => { settings.AutoUpdate = !settings.AutoUpdate; settings.Save(); return Task.CompletedTask; }, false, ShowSettings));
        page.Controls.Add(Caption("APP"));
        page.Controls.Add(Card("Player name", settings.PlayerName.Trim().Length > 0 ? $"The name the game shows. Now: {settings.PlayerName.Trim()}" : "Not set - the game shows \"Player\" in LAN sessions.", settings.PlayerName.Trim().Length > 0 ? "set" : "not set", "Change", async () => { var name = await AskText("What name should the game show?", settings.PlayerName); if (name is not null) { settings.PlayerName = name.Trim(); settings.Save(); } }, false, ShowSettings));
        page.Controls.Add(Card("Minimize to the tray", "Keeps the app in the notification area when you minimize it.", settings.Tray ? "on" : "off", settings.Tray ? "Turn off" : "Turn on", () => { SetTray(!settings.Tray); return Task.CompletedTask; }, false, ShowSettings));

        page.Controls.Add(Caption("THIS PC"));
        var installedAt = Setup.InstalledAt;
        if (installedAt is null)
            page.Controls.Add(Card("Install on this PC", "Copies the app into your profile and adds it to the Start menu and Apps & features. You are running it portable right now.", "portable", "Install", () => { Process.Start(new ProcessStartInfo(Environment.ProcessPath!, "--setup") { UseShellExecute = true }); return Task.CompletedTask; }, false, ShowSettings));
        else
        {
            page.Controls.Add(Card("Installed on this PC", $"The app lives in {installedAt}. Removing it leaves your mods in Plutonium untouched.", "installed", "Uninstall", () => { Process.Start(new ProcessStartInfo(Path.Combine(installedAt, Setup.ExeName), "--uninstall") { UseShellExecute = true }); return Task.CompletedTask; }, false, ShowSettings));
            page.Controls.Add(Card("Start menu entry", "An entry under a \"Quality of Life Series\" group.", Setup.HasStartMenu ? "on" : "off", Setup.HasStartMenu ? "Turn off" : "Turn on", () => { Setup.SetStartMenu(!Setup.HasStartMenu); return Task.CompletedTask; }, false, ShowSettings));
            page.Controls.Add(Card("Desktop shortcut", "A shortcut to this app on your desktop.", Setup.HasDesktop ? "on" : "off", Setup.HasDesktop ? "Turn off" : "Turn on", () => { Setup.SetDesktop(!Setup.HasDesktop); return Task.CompletedTask; }, false, ShowSettings));
        }
    }

    private FlowLayoutPanel ThemeGrid(FlowLayoutPanel page, Palette current)
    {
        var grid = new FlowLayoutPanel { FlowDirection = FlowDirection.LeftToRight, WrapContents = true, BackColor = Base, AutoSize = false, Margin = new Padding(0, 2, 0, 6), Padding = new Padding(0), Width = Math.Max(420, page.ClientSize.Width - 8) };
        foreach (var theme in Palettes.All)
        {
            var chip = new RoundedPanel { Width = 196, Height = 42, Margin = new Padding(0, 0, 10, 10), Radius = 10, BackColor = Surface0, BorderColor = theme.Key == current.Key ? Teal : Surface0, HoverBorderColor = Surface1, Cursor = Cursors.Hand };
            var dot = new RoundedPanel { Location = new Point(12, 13), Size = new Size(16, 16), Radius = 8, BackColor = theme.Accent, BorderColor = theme.Accent, Cursor = Cursors.Hand };
            var name = new Label { AutoSize = false, Bounds = new Rectangle(38, 11, 146, 20), AutoEllipsis = true, Text = theme.Name, Font = F(9), ForeColor = theme.Key == current.Key ? Ink : Subtext0, BackColor = Surface0, Cursor = Cursors.Hand };
            void Pick() { settings.Theme = theme.Key; settings.Save(); ApplyTheme(theme, true); }
            chip.Click += (_, _) => Pick(); name.Click += (_, _) => Pick(); dot.Click += (_, _) => Pick();
            tips.SetToolTip(name, theme.Name); chip.Controls.Add(dot); chip.Controls.Add(name);
            grid.Controls.Add(chip);
        }
        void LayoutGrid()
        {
            var perRow = Math.Max(1, (grid.Width + 10) / 206);
            grid.Height = ((grid.Controls.Count + perRow - 1) / perRow) * 52 + 2;
        }
        grid.Resize += (_, _) => LayoutGrid();
        grid.ControlAdded += (_, _) => LayoutGrid();
        return grid;
    }

    private void ShowDetails()
    {
        currentPage = ShowDetails;
        Clear("Details and log", "Installed paths and recorded actions"); Select("Details and log"); footer.Text = PageFooter(service.GetStatus()); var cards = Cards();
        cards.Controls.Add(Card("Installer log", "Opens the action log in your default text editor.", "installer.log", "Open log", () => { service.OpenLog(); return Task.CompletedTask; }, true));
        cards.Controls.Add(Card("Plutonium storage", "Opens Plutonium's storage folder - every game version lives under it.", "storage", "Open folder", () => { service.OpenFolder(service.Storage); return Task.CompletedTask; }));
        cards.Controls.Add(Card("T6 storage (this mod)", "Opens the Black Ops II folder under storage where this mod is installed.", "storage\\t6", "Open folder", () => { service.OpenFolder(service.T6); return Task.CompletedTask; }));
        cards.Controls.Add(Card("Start menu group", "Where the two shortcuts live, if you added them.", "Programs", "Open folder", () => { service.OpenFolder(service.StartMenuDir); return Task.CompletedTask; }));
        cards.Controls.Add(Card("Settings file", "Where this app remembers your theme and options.", "settings.json", "Open folder", () => { service.OpenFolder(Path.GetDirectoryName(AppSettings.FilePath)!); return Task.CompletedTask; }));
    }
    private void ShowAbout()
    {
        currentPage = ShowAbout;
        Clear("About", $"Mod manager  •  v{service.ProductVersion}"); Select("About"); footer.Text = PageFooter(service.GetStatus()); var cards = Cards();
        cards.Controls.Add(Card("Quality of Life Series", "A mod manager for the Quality of Life mods on Plutonium - install, update, launch and remove. MIT licensed.", "MIT", "Open", () => { service.OpenReleases(); return Task.CompletedTask; }, true));
    }

    private void ShowGame(string game, string system, string name)
    {
        currentPage = () => ShowGame(game, system, name);
        var s = service.GetStatus(); Clear(name, $"Plutonium {system}  •  Multiplayer and Zombies"); Select($"{name} ({system})"); footer.Text = PageFooter(s);
        var cards = Cards();
        cards.Controls.Add(Card("Play Zombies", "Normal online launch through Plutonium.", "online", "Play online", () => { LaunchGame(game, "zm", false, false); return Task.CompletedTask; }, true));
        cards.Controls.Add(Card("Play Zombies (LAN)", "LAN mode - offline this session, no online servers or stats.", "LAN", "Play LAN", () => { LaunchGame(game, "zm", true, false); return Task.CompletedTask; }, false));
        cards.Controls.Add(Card("Play Multiplayer", "Normal online launch through Plutonium.", "online", "Play online", () => { LaunchGame(game, "mp", false, false); return Task.CompletedTask; }, false));
        cards.Controls.Add(Card("Play Multiplayer (LAN)", "LAN mode - offline this session, no online servers or stats.", "LAN", "Play LAN", () => { LaunchGame(game, "mp", true, false); return Task.CompletedTask; }, false));
        var installed = service.GetInstalledMods(game);
        cards.Controls.Add(Card("Installed mods", "See what is installed for this game, install another from a file, or remove one.", installed.Count == 1 ? "1 mod" : $"{installed.Count} mods", "Manage", () => { ShowMods(game, system, name); return Task.CompletedTask; }, false, () => ShowGame(game, system, name)));
        cards.Controls.Add(Card("No Quality of Life mod yet", $"There is no Quality of Life mod for {name} yet - Black Ops II is the current focus. Its home will be github.com/DavidHiFi/{system}-QoL.", "no mod yet", "Back", () => { ShowHome(); return Task.CompletedTask; }));
    }

    private void ShowMods(string game, string system, string gameName)
    {
        currentPage = () => ShowMods(game, system, gameName);
        var mods = service.GetInstalledMods(game);
        Clear($"{gameName} mods", $"Plutonium {system}  •  storage\\{game}\\mods"); Select($"{gameName} ({system})"); footer.Text = PageFooter(service.GetStatus());
        var page = Page();
        page.Controls.Add(Caption($"INSTALLED ({mods.Count})"));
        if (mods.Count == 0)
            page.Controls.Add(Card("Nothing installed", "No mods are installed for this game yet. Install one from a .zip or a mod file.", "empty", "Install", () => InstallModFromFile(game), true, () => ShowMods(game, system, gameName)));
        foreach (var mod in mods)
            page.Controls.Add(Card(mod.Name, $"{mod.Version}{(mod.Version.Length > 0 ? "  •  " : "")}{mod.Path}", InstallerService.FormatSize(mod.Bytes), "Remove", async () => { if (await Ask($"Remove {mod.Name}?")) service.RemoveModFolder(game, mod.Path, Reporter()); }, false, () => ShowMods(game, system, gameName)));
        page.Controls.Add(Caption("ADD"));
        page.Controls.Add(Card("Install a mod from a file", "Pick a .zip or a mod .ff/.iwd file. It is copied into this game's mods folder.", "zip or file", "Choose file", () => InstallModFromFile(game), true, () => ShowMods(game, system, gameName)));
        page.Controls.Add(Card("Open mods folder", "Where Plutonium looks for this game's mods.", "mods", "Open folder", () => { service.OpenFolder(service.ModsDir(game)); return Task.CompletedTask; }));
        page.Controls.Add(Card($"Back to {gameName}", "Returns to the game screen. Nothing is changed.", "back", "Back", () => { if (game == "t6") ShowT6(); else ShowGame(game, system, gameName); return Task.CompletedTask; }));
    }

    // Run() already owns the busy flag, the error dialog and the page refresh - this only picks
    // the file and returns the task so Run can await it. Guarding busy in here as well meant the
    // picker opened and the install then silently did nothing.
    private async Task InstallModFromFile(string game)
    {
        using var pick = new OpenFileDialog { Title = "Pick a mod file", Filter = "Mod files (*.zip;*.ff;*.iwd)|*.zip;*.ff;*.iwd|All files (*.*)|*.*" };
        if (pick.ShowDialog(this) != DialogResult.OK) return;
        await service.InstallModFromFileAsync(game, pick.FileName, Reporter());
    }

    private void LaunchGame(string game, string play, bool lan, bool watchdog)
    {
        var script = Path.Combine(service.Payload, "lan-launch.ps1");
        if (!File.Exists(script)) throw new FileNotFoundException("lan-launch.ps1 is missing from this package - reinstall from the full download.");
        var args = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" -Game {game} -Play {play}";
        if (settings.PlayerName.Trim().Length > 0) args += $" -LanName \"{settings.PlayerName.Trim()}\"";
        if (!lan) args += " -Online";
        if (watchdog) args += " -Watchdog";
        Process.Start(new ProcessStartInfo("powershell.exe", args) { UseShellExecute = true, WorkingDirectory = service.Payload, WindowStyle = ProcessWindowStyle.Normal });
        service.Log($"launch: {game} {play} lan={lan} watchdog={watchdog} name={(settings.PlayerName.Trim().Length > 0 ? settings.PlayerName.Trim() : "Player")}");
        footer.Text = lan ? "Starting in LAN mode - a console window shows progress." : "Starting through Plutonium - a console window shows progress.";
    }

    private void ShowEmptyGame(string game, string system)
    {
        currentPage = () => ShowEmptyGame(game, system);
        Clear(game, $"Plutonium {system}  •  nothing to install yet"); Select($"{game} ({system})"); footer.Text = PageFooter(service.GetStatus()); var cards = Cards();
        cards.Controls.Add(Card("No mod yet", $"There is no Quality of Life mod for {game} yet. Black Ops II is the current focus - its home will be github.com/DavidHiFi/{system}-QoL.", "nothing yet", "Back to Home", () => { ShowHome(); return Task.CompletedTask; }, true));
    }

    private async Task InstallMod()
    {
        var answer = await Choose("Update and keep your saved menu settings?", ("Update, keep everything", "keep", true), ("Fresh install, wipe settings", "wipe", false), ("Cancel", "cancel", false));
        if (answer is null or "cancel") return;
        await service.InstallModAsync(answer == "wipe", Reporter());
    }

    private async Task InstallPack(string kind)
    {
        var what = kind == "images" ? "your textures" : "your sounds";
        var answer = await Choose($"Back up {what} first?", ("Back up, then install", "backup", true), ("Install without a backup", "plain", false), ("Cancel", "cancel", false));
        if (answer is null or "cancel") return;
        await service.InstallPackAsync(kind, answer == "backup", Reporter());
    }

    private async Task InstallReShade()
    {
        var answer = await Choose("Back up your ReShade setup first?", ("Back up, then install", "backup", true), ("Install without a backup", "plain", false), ("Cancel", "cancel", false));
        if (answer is null or "cancel") return;
        if (answer == "backup") service.BackupKind("reshade", false, Reporter());
        await service.InstallReShadeAsync(Reporter());
    }

    private async Task InstallEverything()
    {
        if (!await Ask("Install the mod, HD textures and custom sounds?\n\nYour textures and sounds are backed up first.")) return;
        await service.InstallEverythingAsync(Reporter());
    }

    private async Task RemoveEverything()
    {
        if (!await Ask("Remove every part of this package: textures, sounds, controller icons, ReShade, the Start menu shortcuts and the mod?")) return;
        var restore = service.HasBackup("images") || service.HasBackup("zone") || service.HasBackup("controller") || service.HasBackup("reshade") || service.HasBackup("mod");
        var putBack = restore && await Ask("Put your original files back afterwards?", "Restore them", "Just remove");
        service.RemoveEverything(putBack, Reporter());
        footer.Text = "Removed. Your saved menu settings were kept.";
    }

    private async Task CheckUpdates()
    {
        var result = await service.CheckForUpdatesAsync();
        if (result.Ok) pendingCheck = result;
        if (!result.Ok || (!result.ModUpdate && !result.AppUpdate))
        {
            await Tell(result.Ok ? result.Summary + "\n\nEverything is up to date." : result.Summary);
            return;
        }
        var options = new List<(string Text, string Key, bool Primary)>();
        if (result.CanInstallMod) options.Add(("Install the mod update", "mod", true));
        if (result.CanInstallApp) options.Add(("Update this app", "app", options.Count == 0));
        options.Add(("Open the releases page", "open", false));
        options.Add(("Not now", "close", false));
        var choice = await Choose(result.Summary, options.ToArray());
        if (choice == "mod") { await service.InstallUpdateAsync(Reporter()); await Tell("The mod update is installed. Your settings were kept."); ShowT6(); }
        else if (choice == "app")
        {
            if (await Ask("The app will close, update itself, and open again.", "Update now", "Not now"))
            {
                await service.InstallAppUpdateAsync(Reporter());
                Application.Exit();
            }
        }
        else if (choice == "open") service.OpenReleases();
    }

    private async Task StartupCheckAsync()
    {
        try
        {
            var result = await service.CheckForUpdatesAsync();
            if (!result.Ok) return;
            pendingCheck = result;
            if (result.ModUpdate || result.AppUpdate) { footer.Text = "An update is available - see Home."; Rebuild(); }
        }
        catch { }
    }

    private void SetTray(bool on, bool save = true)
    {
        settings.Tray = on; if (save) settings.Save();
        if (on) { tray ??= BuildTray(); tray.Visible = true; }
        else if (tray is not null) tray.Visible = false;
    }
    private NotifyIcon BuildTray()
    {
        var menu = new ContextMenuStrip { Font = F(9) };
        menu.Items.Add("Open Quality of Life Series", null, (_, _) => RestoreFromTray());
        menu.Items.Add("Check for updates", null, async (_, _) => await CheckUpdates());
        menu.Items.Add("Exit", null, (_, _) => { tray?.Dispose(); Application.Exit(); });
        var icon = new NotifyIcon { Icon = Icon, Text = "Quality of Life Series", ContextMenuStrip = menu, Visible = true };
        icon.DoubleClick += (_, _) => RestoreFromTray();
        return icon;
    }
    private void RestoreFromTray() { Show(); WindowState = FormWindowState.Normal; Activate(); }
    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        if (WindowState == FormWindowState.Minimized && settings.Tray)
        {
            Hide();
            if (tray is not null && !settings.MinimizedHintShown)
            {
                tray.ShowBalloonTip(2000, "Quality of Life Series", "Still running in the notification area.", ToolTipIcon.Info);
                settings.MinimizedHintShown = true; settings.Save();
            }
        }
    }

    private async Task<string?> AskText(string message, string value)
    {
        var tcs = new TaskCompletionSource<string?>();
        var wasBusy = busy; busy = true;
        var scrim = NewScrim(); overlay = scrim;
        int pad = Dp(this, 28), btnH = Dp(this, 40);
        var cardWidth = Math.Min(Dp(this, 560), Math.Max(Dp(this, 320), content.ClientSize.Width - Dp(this, 48)));
        var inner = cardWidth - pad * 2;
        var font = F(10);
        var textHeight = Math.Max(Dp(this, 24), TextRenderer.MeasureText(message, font, new Size(inner, 0), TextFormatFlags.WordBreak | TextFormatFlags.TextBoxControl).Height + Dp(this, 6));
        int boxY = pad + textHeight + Dp(this, 14), boxH = Dp(this, 32);
        int btnY = boxY + boxH + Dp(this, 22);
        var card = new RoundedPanel { Width = cardWidth, Height = btnY + btnH + Dp(this, 22), BackColor = Surface0, BorderColor = Surface1, HoverBorderColor = Surface1, Radius = 16, Padding = new Padding(0) };
        var label = new Label { AutoSize = false, Bounds = new Rectangle(pad, pad, inner, textHeight), Text = message, ForeColor = Ink, Font = font, BackColor = Surface0, UseMnemonic = false };
        var box = new TextBox { Bounds = new Rectangle(pad, boxY, inner, boxH), Text = value, BackColor = Surface1, ForeColor = Ink, BorderStyle = BorderStyle.FixedSingle, Font = font };
        var half = (inner - Dp(this, 12)) / 2;
        var save = new RoundButton { Bounds = new Rectangle(pad, btnY, half, btnH), Radius = btnH / 2, Text = "Save", BackColor = Teal, HoverColor = Sky, ForeColor = Crust, Font = F(9.5f, true), Cursor = Cursors.Hand, TextAlign = ContentAlignment.MiddleCenter };
        var cancel = new RoundButton { Bounds = new Rectangle(pad + half + Dp(this, 12), btnY, half, btnH), Radius = btnH / 2, Text = "Cancel", BackColor = Surface1, HoverColor = Surface2, ForeColor = Ink, Font = F(9.5f, true), Cursor = Cursors.Hand, TextAlign = ContentAlignment.MiddleCenter };
        save.Click += (_, _) => tcs.TrySetResult(box.Text);
        cancel.Click += (_, _) => tcs.TrySetResult(null);
        box.KeyDown += (_, e) => { if (e.KeyCode == Keys.Enter) { e.SuppressKeyPress = true; tcs.TrySetResult(box.Text); } else if (e.KeyCode == Keys.Escape) { e.SuppressKeyPress = true; tcs.TrySetResult(null); } };
        card.Controls.Add(label); card.Controls.Add(box); card.Controls.Add(save); card.Controls.Add(cancel);
        scrim.Controls.Add(card);
        CentreCard(scrim, card);
        content.Controls.Add(scrim); scrim.BringToFront(); box.Focus(); box.SelectAll();
        var result = await tcs.Task;
        content.Controls.Remove(scrim); scrim.Dispose(); overlay = null; busy = wasBusy;
        return result;
    }

    private Progress<string> Reporter() => new(s => footer.Text = s);

    protected override void OnHandleCreated(EventArgs e) { base.OnHandleCreated(e); ApplyTitleBar(CurrentTheme(settings)); }
    protected override void OnShown(EventArgs e) { base.OnShown(e); ApplyTitleBar(CurrentTheme(settings)); }
    [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);
    [DllImport("user32.dll")] private static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)] private static extern int SetWindowTheme(IntPtr hwnd, string? subApp, string? subId);

    private sealed class Row : RoundedPanel
    {
        internal readonly Label Title = new();
        internal readonly Label Description = new();
        internal readonly Label Status = new();
        internal readonly RoundButton Button = new();
        internal Row()
        {
            Margin = new Padding(0, 0, 0, 8); Radius = 10; BackColor = Surface0; BorderColor = Surface0; HoverBorderColor = Surface0; HoverFill = Color.Empty;
            Title.AutoSize = false; Title.Font = F(10.5f, true); Title.ForeColor = Ink; Title.BackColor = Surface0; Title.AutoEllipsis = true; Title.TextAlign = ContentAlignment.MiddleLeft; Title.UseMnemonic = false;
            Description.AutoSize = false; Description.Font = F(9); Description.ForeColor = Subtext0; Description.BackColor = Surface0; Description.AutoEllipsis = true; Description.TextAlign = ContentAlignment.MiddleLeft; Description.UseMnemonic = false;
            Status.AutoSize = false; Status.Font = F(8.5f); Status.ForeColor = Overlay2; Status.BackColor = Surface0; Status.TextAlign = ContentAlignment.MiddleRight; Status.AutoEllipsis = true; Status.UseMnemonic = false;
            Button.Radius = 15; Button.Font = F(8.5f, true); Button.Cursor = Cursors.Hand;
            Controls.Add(Title); Controls.Add(Description); Controls.Add(Status); Controls.Add(Button);
            Status.TextChanged += (_, _) => LayoutRow();
            Button.TextChanged += (_, _) => LayoutRow();
            Height = Dp(this, 68);
        }
        protected override void OnResize(EventArgs e) { base.OnResize(e); LayoutRow(); }
        protected override void OnDpiChangedAfterParent(EventArgs e) { base.OnDpiChangedAfterParent(e); Height = Dp(this, 68); LayoutRow(); }

        // Title/description own the left run; status sits between them and the button, never under either.
        private void LayoutRow()
        {
            int pad = Dp(this, 16), gap = Dp(this, 14);
            Button.Size = new Size(Dp(this, 124), Dp(this, 30));
            var buttonLeft = Width - pad - Button.Width;
            Button.Location = new Point(buttonLeft, (Height - Button.Height) / 2);

            var statusRight = buttonLeft - gap;
            var wanted = Status.Text.Length == 0 ? 0 : TextRenderer.MeasureText(Status.Text, Status.Font).Width + Dp(this, 4);
            var room = Math.Max(0, (statusRight - pad - Dp(this, 140)));
            var statusWidth = Math.Min(wanted, Math.Min(Dp(this, 210), room));
            Status.Bounds = new Rectangle(statusRight - statusWidth, 0, statusWidth, Height);

            var textRight = statusWidth > 0 ? statusRight - statusWidth - gap : statusRight;
            var textWidth = Math.Max(Dp(this, 60), textRight - pad);
            Title.Bounds = new Rectangle(pad, Dp(this, 9), textWidth, Dp(this, 23));
            Description.Bounds = new Rectangle(pad, Dp(this, 34), textWidth, Dp(this, 21));
        }
    }

}
