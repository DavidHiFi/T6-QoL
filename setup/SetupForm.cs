using System.Diagnostics;
using System.Drawing.Drawing2D;
using System.Reflection;

namespace QolSeriesSetup;

internal sealed class SetupForm : Form
{
    private static readonly Color Side = Color.FromArgb(21, 22, 26);
    private static readonly Color Base = Color.FromArgb(26, 27, 32);
    private static readonly Color Card = Color.FromArgb(35, 37, 43);
    private static readonly Color Secondary = Color.FromArgb(47, 50, 58);
    private static readonly Color SecondaryHover = Color.FromArgb(57, 61, 70);
    private static readonly Color Ink = Color.FromArgb(232, 234, 238);
    private static readonly Color Sub = Color.FromArgb(178, 184, 196);
    private static readonly Color Muted = Color.FromArgb(154, 160, 172);
    private static readonly Color Accent = Color.FromArgb(79, 156, 249);
    private static readonly Color AccentHover = Color.FromArgb(108, 176, 255);
    private static readonly Color Crust = Color.FromArgb(12, 22, 36);
    private static readonly Color Good = Color.FromArgb(109, 205, 138);

    private static Font F(float size, bool bold = false) => new("Segoe UI", size, bold ? FontStyle.Bold : FontStyle.Regular, GraphicsUnit.Point);

    private readonly TextBox pathBox;
    private readonly RoundButton install;
    private readonly Label state;
    private bool working;

    internal SetupForm()
    {
        Text = "Quality of Life Series - Setup"; ClientSize = new Size(620, 330); StartPosition = FormStartPosition.CenterScreen; FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false; MinimizeBox = false;
        BackColor = Base; ForeColor = Ink; Font = F(10);
        Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);

        var title = new Label { Location = new Point(30, 24), AutoSize = true, Text = "Quality of Life Series", Font = F(19, true), ForeColor = Ink, BackColor = Base };
        var subtitle = new Label { Location = new Point(32, 60), AutoSize = true, Text = "Installs the mod installer on this PC, with an uninstaller. The portable download works without this.", Font = F(9.5f), ForeColor = Muted, BackColor = Base };
        pathBox = new TextBox { Location = new Point(32, 100), Size = new Size(486, 28), Text = Installer.DefaultTarget, BackColor = Secondary, ForeColor = Ink, BorderStyle = BorderStyle.FixedSingle, Font = F(10) };
        var browse = new RoundButton { Location = new Point(526, 99), Size = new Size(62, 30), Radius = 15, Text = "Browse", BackColor = Secondary, HoverColor = SecondaryHover, ForeColor = Ink, Font = F(9, true), Cursor = Cursors.Hand };
        browse.Click += (_, _) => { using var pick = new FolderBrowserDialog { SelectedPath = Directory.Exists(pathBox.Text) ? pathBox.Text : Installer.DefaultTarget }; if (pick.ShowDialog(this) == DialogResult.OK) pathBox.Text = pick.SelectedPath; };
        state = new Label { Location = new Point(32, 146), Size = new Size(556, 44), Text = "Ready. The package is fetched from GitHub if it is not beside this setup file.", ForeColor = Sub, BackColor = Base, Font = F(9.5f), AutoEllipsis = true };
        install = new RoundButton { Location = new Point(32, 250), Size = new Size(556, 44), Radius = 22, Text = "Install", BackColor = Accent, HoverColor = AccentHover, ForeColor = Crust, Font = F(10, true), Cursor = Cursors.Hand };
        install.Click += async (_, _) => await InstallAsync();
        Controls.Add(title); Controls.Add(subtitle); Controls.Add(pathBox); Controls.Add(browse); Controls.Add(state); Controls.Add(install);
    }

    private async Task InstallAsync()
    {
        if (working) return;
        var target = pathBox.Text.Trim();
        if (target.Length == 0) return;
        working = true; install.Enabled = false;
        var progress = new Progress<string>(s => state.Text = s);
        try
        {
            var zip = Installer.FindPayloadZip();
            zip ??= await Installer.DownloadPayloadAsync(progress);
            state.Text = "Unpacking...";
            var source = Installer.ExtractApp(zip);
            Installer.InstallFiles(source, target, progress);
            var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "2.17.0";
            Installer.CreateShortcut(target, true);
            File.Copy(Environment.ProcessPath!, Path.Combine(target, "Uninstall.exe"), true);
            Installer.RegisterUninstall(target, version);
            state.Text = "Installed. A Start menu entry and an uninstaller are in place.";
            install.Text = "Open Quality of Life Series";
            install.Click += (_, _) => { Process.Start(new ProcessStartInfo(Path.Combine(target, Installer.ExeName)) { UseShellExecute = true }); Close(); };
            install.BackColor = Good; install.HoverColor = Color.FromArgb(140, 222, 160); install.Invalidate();
            working = false; install.Enabled = true;
        }
        catch (Exception ex)
        {
            state.Text = "That did not work: " + ex.Message;
            state.ForeColor = Color.FromArgb(243, 139, 168);
            working = false; install.Enabled = true;
        }
    }

    private sealed class RoundButton : Button
    {
        internal int Radius { get; set; } = 14;
        internal Color HoverColor { get; set; }
        private bool hover;
        internal RoundButton()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            FlatStyle = FlatStyle.Flat; FlatAppearance.BorderSize = 0;
            MouseEnter += (_, _) => { hover = true; Invalidate(); };
            MouseLeave += (_, _) => { hover = false; Invalidate(); };
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            e.Graphics.Clear(Parent?.BackColor ?? BackColor);
            using var path = Rounded(new Rectangle(0, 0, Width - 1, Height - 1), Radius);
            using var brush = new SolidBrush(hover && HoverColor != Color.Empty ? HoverColor : BackColor);
            e.Graphics.FillPath(brush, path);
            TextRenderer.DrawText(e.Graphics, Text, Font, ClientRectangle, ForeColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
        }
        private static GraphicsPath Rounded(Rectangle r, int radius)
        {
            var path = new GraphicsPath();
            var d = Math.Min(radius * 2, Math.Min(r.Width, r.Height));
            path.AddArc(r.X, r.Y, d, d, 180, 90);
            path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
            path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
            path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }
    }
}