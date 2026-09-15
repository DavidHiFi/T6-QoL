using System.Drawing.Drawing2D;

namespace QolSeriesInstaller;

/// <summary>A panel with rounded corners, painted from colours the caller supplies.</summary>
internal class RoundedPanel : Panel
{
    internal int Radius { get; set; } = 16;
    internal Color BorderColor { get; set; } = Color.Empty;
    internal Color HoverBorderColor { get; set; } = Color.Empty;
    internal Color HoverFill { get; set; }
    private bool hover;

    internal RoundedPanel()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        MouseEnter += (_, _) => { hover = true; Invalidate(); };
        MouseLeave += (_, _) => { hover = false; Invalidate(); };
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        e.Graphics.Clear(Parent?.BackColor ?? BackColor);
        using var path = RoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), Radius);
        using var fill = new SolidBrush(hover && HoverFill != Color.Empty ? HoverFill : BackColor);
        e.Graphics.FillPath(fill, path);
        var border = hover && HoverBorderColor != Color.Empty ? HoverBorderColor : BorderColor;
        if (border != Color.Empty && border != BackColor)
        {
            using var pen = new Pen(border, 1.1f);
            e.Graphics.DrawPath(pen, path);
        }
    }

    internal static GraphicsPath RoundedPath(Rectangle r, int radius)
    {
        var path = new GraphicsPath();
        var d = Math.Max(1, Math.Min(radius * 2, Math.Min(r.Width, r.Height)));
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}

/// <summary>A pill button. Draws an optional leading glyph, and honours TextAlign for centring.</summary>
internal sealed class RoundButton : Button
{
    internal int Radius { get; set; } = 12;
    internal string Glyph { get; set; } = "";
    internal Color HoverColor { get; set; }
    internal Color SelectedColor { get; set; }
    internal Color SelectedForeColor { get; set; }
    /// <summary>A colour swatch drawn before the text - used by the theme picker.</summary>
    internal Color Dot { get; set; } = Color.Empty;
    internal Color BorderColor { get; set; } = Color.Empty;
    internal bool Selected { get; set; }
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
        var fill = Selected ? SelectedColor : hover && HoverColor != Color.Empty ? HoverColor : BackColor;
        using var path = RoundedPanel.RoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), Radius);
        using (var brush = new SolidBrush(Enabled ? fill : Blend(fill, Parent?.BackColor ?? fill, 0.45f)))
            e.Graphics.FillPath(brush, path);

        if (BorderColor != Color.Empty)
        {
            using var pen = new Pen(BorderColor, 1.4f);
            e.Graphics.DrawPath(pen, path);
        }

        var fore = Selected ? SelectedForeColor : ForeColor;
        if (!Enabled) fore = Blend(fore, Parent?.BackColor ?? fore, 0.45f);
        var inset = Ui.Dp(this, 14);
        var x = Padding.Left + inset;
        if (Dot != Color.Empty)
        {
            var d = Ui.Dp(this, 14);
            using var swatch = new SolidBrush(Dot);
            e.Graphics.FillEllipse(swatch, x, (Height - d) / 2, d, d);
            x += d + Ui.Dp(this, 10);
        }
        if (Glyph.Length > 0)
        {
            var gw = Ui.Dp(this, 20);
            TextRenderer.DrawText(e.Graphics, Glyph, GlyphFont, new Rectangle(x, 0, gw, Height), fore, TextFormatFlags.Left | TextFormatFlags.VerticalCenter);
            x += gw + Ui.Dp(this, 8);
        }
        var centred = Glyph.Length == 0 && TextAlign is ContentAlignment.MiddleCenter or ContentAlignment.TopCenter or ContentAlignment.BottomCenter;
        var align = centred ? TextFormatFlags.HorizontalCenter : TextFormatFlags.Left;
        var box = centred ? new Rectangle(inset, 0, Width - inset * 2, Height) : new Rectangle(x, 0, Width - x - inset, Height);
        TextRenderer.DrawText(e.Graphics, Text, Font, box, fore, align | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
    }

    private static Color Blend(Color a, Color b, float t) =>
        Color.FromArgb((int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));

    private Font? glyphFont;
    private Font GlyphFont => glyphFont ??= new Font("Segoe MDL2 Assets", 11, FontStyle.Regular, GraphicsUnit.Point);
}

/// <summary>The rounded brand tile: the app artwork, or a glyph when there is none.</summary>
internal sealed class LogoMark : RoundedPanel
{
    internal string Glyph { get; set; } = "";
    internal Color GlyphColor { get; set; } = Color.Gainsboro;
    internal Image? Artwork { get; set; }
    private static readonly Font IconFont = new("Segoe MDL2 Assets", 14, FontStyle.Regular, GraphicsUnit.Point);

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (Artwork is not null)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            e.Graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            using var path = RoundedPath(new Rectangle(0, 0, Width, Height), Radius);
            var state = e.Graphics.Save();
            e.Graphics.SetClip(path);
            // Fill the tile and crop the overhang, rather than squashing a 16:9 banner into a
            // square. The centre of a piece of cover art is the part worth showing.
            var scale = Math.Max((float)Width / Artwork.Width, (float)Height / Artwork.Height);
            var w = Artwork.Width * scale;
            var h = Artwork.Height * scale;
            e.Graphics.DrawImage(Artwork, new RectangleF((Width - w) / 2f, (Height - h) / 2f, w, h));
            e.Graphics.Restore(state);
            return;
        }
        TextRenderer.DrawText(e.Graphics, Glyph, IconFont, ClientRectangle, GlyphColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
    }
}
