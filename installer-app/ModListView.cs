using System.Drawing.Drawing2D;

namespace QolSeriesInstaller;

/// <summary>
/// A mod list that is one control rather than one control per row.
///
/// Built out of Rows, a game with 82 mods came to roughly 500 child windows, and WinForms moves
/// every one of them on every scroll tick - which is what made scrolling crawl. This paints only
/// the rows actually on screen (about a dozen), so the cost of scrolling no longer depends on how
/// many mods are installed.
/// </summary>
internal sealed class ModListView : Control
{
    internal sealed record Item(string Name, string Detail, string Size, string Folder);

    private readonly List<Item> source = [];
    private readonly List<Item> view = [];
    private string filter = "";
    private int offset;
    private int hoverRow = -1, hoverButton = -1, downRow = -1, downButton = -1;
    private bool railHot, railDragging;
    private int railGrab;

    internal Color Surface = Color.FromArgb(35, 37, 43);
    internal Color Ink = Color.White;
    internal Color Sub = Color.Silver;
    internal Color Muted = Color.Gray;
    internal Color Button = Color.DimGray;
    internal Color ButtonHot = Color.Gray;
    internal Color ButtonInk = Color.White;
    internal Color RailColor = Color.DimGray;
    internal Color RailHotColor = Color.Silver;

    internal Action<Item>? OpenFolder;
    internal Action<Item>? RemoveMod;
    internal string EmptyText = "Nothing here.";

    internal ModListView()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);
        TabStop = true;
    }

    internal int Shown => view.Count;

    internal void SetItems(IEnumerable<Item> items)
    {
        source.Clear();
        source.AddRange(items);
        Rebuild();
    }

    internal void SetFilter(string text)
    {
        filter = text.Trim();
        Rebuild();
    }

    private void Rebuild()
    {
        view.Clear();
        foreach (var item in source)
            if (filter.Length == 0
                || item.Name.Contains(filter, StringComparison.OrdinalIgnoreCase)
                || item.Folder.Contains(filter, StringComparison.OrdinalIgnoreCase))
                view.Add(item);
        offset = 0;
        Clamp();
        Invalidate();
    }

    private int D(int v) => Ui.Dp(this, v);
    private int RowHeight => D(68);
    private int Step => RowHeight + D(8);
    private int ContentHeight => view.Count * Step;
    private int MaxOffset => Math.Max(0, ContentHeight - ClientSize.Height);
    private int RailWidth => D(12);
    private void Clamp() => offset = Math.Clamp(offset, 0, MaxOffset);

    private Rectangle ButtonRect(int row, int which)
    {
        int pad = D(16), gap = D(8), w = D(110), h = D(30);
        var right = ClientSize.Width - RailWidth;
        var y = row * Step - offset + (RowHeight - h) / 2;
        var removeLeft = right - pad - w;
        return new Rectangle(which == 1 ? removeLeft : removeLeft - gap - w, y, w, h);
    }

    private (int Row, int Button) Hit(Point p)
    {
        if (view.Count == 0) return (-1, -1);
        var row = (p.Y + offset) / Step;
        if (row < 0 || row >= view.Count) return (-1, -1);
        if (ButtonRect(row, 0).Contains(p)) return (row, 0);
        if (ButtonRect(row, 1).Contains(p)) return (row, 1);
        return (row, -1);
    }

    private Rectangle RailRect() => new(ClientSize.Width - RailWidth, 0, RailWidth, ClientSize.Height);

    private Rectangle ThumbRect()
    {
        if (ContentHeight <= ClientSize.Height || ClientSize.Height <= 0) return Rectangle.Empty;
        var track = Math.Max(1, ClientSize.Height - D(8));
        var h = Math.Max(D(28), (int)((long)track * ClientSize.Height / ContentHeight));
        var span = Math.Max(1, track - h);
        var y = D(4) + (int)((long)span * offset / Math.Max(1, MaxOffset));
        return new Rectangle(ClientSize.Width - D(9), y, D(5), h);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.Clear(BackColor);
        if (view.Count == 0)
        {
            TextRenderer.DrawText(g, EmptyText, Ui.F(9.5f), ClientRectangle, Muted,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
            return;
        }

        g.SmoothingMode = SmoothingMode.AntiAlias;
        int pad = D(16), radius = D(10);
        var width = ClientSize.Width - RailWidth;

        // Only what is on screen, plus one row of slack either side.
        var first = Math.Max(0, offset / Step - 1);
        var last = Math.Min(view.Count - 1, (offset + ClientSize.Height) / Step + 1);

        var titleFont = Ui.F(10.5f, true);
        var detailFont = Ui.F(9);
        var sizeFont = Ui.F(8.5f);
        var buttonFont = Ui.F(8.5f, true);

        for (var i = first; i <= last; i++)
        {
            var y = i * Step - offset;
            var card = new Rectangle(0, y, Math.Max(1, width - 1), RowHeight - 1);
            using (var path = RoundedPanel.RoundedPath(card, radius))
            using (var brush = new SolidBrush(Surface))
                g.FillPath(brush, path);

            var open = ButtonRect(i, 0);
            var remove = ButtonRect(i, 1);

            // Size sits between the text and the buttons, never under either.
            var sizeText = view[i].Size;
            var sizeWidth = sizeText.Length == 0 ? 0 : TextRenderer.MeasureText(sizeText, sizeFont).Width + D(4);
            var sizeRight = open.Left - D(14);
            if (sizeWidth > 0)
                TextRenderer.DrawText(g, sizeText, sizeFont, new Rectangle(sizeRight - sizeWidth, y, sizeWidth, RowHeight), Muted,
                    TextFormatFlags.Right | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);

            var textWidth = Math.Max(D(60), (sizeWidth > 0 ? sizeRight - sizeWidth - D(14) : sizeRight) - pad);
            TextRenderer.DrawText(g, view[i].Name, titleFont, new Rectangle(pad, y + D(9), textWidth, D(23)), Ink,
                TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
            TextRenderer.DrawText(g, view[i].Detail, detailFont, new Rectangle(pad, y + D(34), textWidth, D(21)), Sub,
                TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.PathEllipsis);

            DrawButton(g, open, "Open folder", buttonFont, i, 0);
            DrawButton(g, remove, "Remove", buttonFont, i, 1);
        }

        var thumb = ThumbRect();
        if (!thumb.IsEmpty)
        {
            using var path = RoundedPanel.RoundedPath(thumb, D(3));
            using var brush = new SolidBrush(railHot || railDragging ? RailHotColor : RailColor);
            g.FillPath(brush, path);
        }
    }

    private void DrawButton(Graphics g, Rectangle r, string text, Font font, int row, int which)
    {
        var hot = hoverRow == row && hoverButton == which;
        var down = downRow == row && downButton == which;
        using (var path = RoundedPanel.RoundedPath(new Rectangle(r.X, r.Y, r.Width - 1, r.Height - 1), r.Height / 2))
        using (var brush = new SolidBrush(hot || down ? ButtonHot : Button))
            g.FillPath(brush, path);
        TextRenderer.DrawText(g, text, font, r, ButtonInk,
            TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
    }

    protected override void OnMouseWheel(MouseEventArgs e)
    {
        base.OnMouseWheel(e);
        offset -= e.Delta / 120 * Step * 3;
        Clamp();
        Invalidate();
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (railDragging) { DragTo(e.Y); return; }

        var overRail = RailRect().Contains(e.Location) && !ThumbRect().IsEmpty;
        if (overRail != railHot) { railHot = overRail; Invalidate(); }

        var (row, button) = Hit(e.Location);
        if (row == hoverRow && button == hoverButton) return;
        hoverRow = row; hoverButton = button;
        Cursor = button >= 0 ? Cursors.Hand : Cursors.Default;
        Invalidate();
    }

    protected override void OnMouseLeave(EventArgs e)
    {
        base.OnMouseLeave(e);
        hoverRow = hoverButton = -1; railHot = false;
        Cursor = Cursors.Default;
        Invalidate();
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        Focus();
        var thumb = ThumbRect();
        if (RailRect().Contains(e.Location) && !thumb.IsEmpty)
        {
            if (e.Y >= thumb.Y && e.Y < thumb.Bottom) { railDragging = true; railGrab = e.Y - thumb.Y; }
            else DragTo(e.Y - thumb.Height / 2);
            Invalidate();
            return;
        }
        (downRow, downButton) = Hit(e.Location);
        if (downButton >= 0) Invalidate();
    }

    protected override void OnMouseUp(MouseEventArgs e)
    {
        base.OnMouseUp(e);
        railDragging = false;
        var (row, button) = Hit(e.Location);
        if (button >= 0 && row >= 0 && row == downRow && button == downButton)
        {
            var item = view[row];
            downRow = downButton = -1;
            Invalidate();
            if (button == 0) OpenFolder?.Invoke(item); else RemoveMod?.Invoke(item);
            return;
        }
        downRow = downButton = -1;
        Invalidate();
    }

    private void DragTo(int y)
    {
        var track = Math.Max(1, ClientSize.Height - D(8));
        var h = Math.Max(D(28), (int)((long)track * ClientSize.Height / Math.Max(1, ContentHeight)));
        var span = Math.Max(1, track - h);
        offset = (int)((long)MaxOffset * Math.Clamp(y - railGrab - D(4), 0, span) / span);
        Clamp();
        Invalidate();
    }

    protected override bool IsInputKey(Keys key) => key is Keys.Up or Keys.Down or Keys.PageUp or Keys.PageDown or Keys.Home or Keys.End || base.IsInputKey(key);

    protected override void OnKeyDown(KeyEventArgs e)
    {
        base.OnKeyDown(e);
        var before = offset;
        offset += e.KeyCode switch
        {
            Keys.Up => -Step,
            Keys.Down => Step,
            Keys.PageUp => -ClientSize.Height,
            Keys.PageDown => ClientSize.Height,
            _ => 0
        };
        if (e.KeyCode == Keys.Home) offset = 0;
        if (e.KeyCode == Keys.End) offset = MaxOffset;
        Clamp();
        if (offset != before) { e.Handled = true; Invalidate(); }
    }

    protected override void OnResize(EventArgs e) { base.OnResize(e); Clamp(); Invalidate(); }
}
