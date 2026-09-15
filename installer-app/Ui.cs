namespace QolSeriesInstaller;

// Shared by the app window and the setup window, so the two can never drift apart on the
// things that make them look like one product: the typeface and the DPI scale.
internal static class Ui
{
    // A machine-wide FontSubstitutes entry can silently redirect "Segoe UI" to something else
    // (a monospace nerd font, on at least one machine), and GDI honours that while GDI+ does not -
    // so the family reports as Segoe UI while every label draws in the substitute. Pick a family
    // that survives the round trip instead of changing the user's registry.
    internal static readonly string Family = ResolveFamily();

    // Fonts are immutable and a page of 80-odd rows asks for the same half-dozen over and over,
    // so hand back one instance per size instead of a fresh GDI+ object each time.
    private static readonly Dictionary<(float, bool), Font> Cache = [];

    internal static Font F(float size, bool bold = false)
    {
        lock (Cache)
        {
            if (!Cache.TryGetValue((size, bold), out var font))
                Cache[(size, bold)] = font = new Font(Family, size, bold ? FontStyle.Bold : FontStyle.Regular, GraphicsUnit.Point);
            return font;
        }
    }

    // Every hand-placed bound goes through this, so the layout survives 125% and 150% displays.
    internal static int Dp(Control c, int value) => (int)Math.Round(value * c.DeviceDpi / 96.0);

    private static string ResolveFamily()
    {
        string[] candidates = ["Segoe UI", "Segoe UI Variable Text", "Tahoma", "Verdana", "Arial"];
        var installed = new HashSet<string>(FontFamily.Families.Select(f => f.Name), StringComparer.OrdinalIgnoreCase);
        var swapped = Substituted();
        foreach (var name in candidates)
            if (installed.Contains(name) && !swapped.Contains(name) && !Monospaced(name)) return name;
        return SystemFonts.MessageBoxFont?.FontFamily.Name ?? "Tahoma";
    }

    private static HashSet<string> Substituted()
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes");
            foreach (var value in key?.GetValueNames() ?? [])
            {
                var from = value.Split(',')[0].Trim();
                var to = ((key!.GetValue(value) as string) ?? "").Split(',')[0].Trim();
                if (from.Length > 0 && to.Length > 0 && !from.Equals(to, StringComparison.OrdinalIgnoreCase)) set.Add(from);
            }
        }
        catch { }
        return set;
    }

    private static bool Monospaced(string family)
    {
        try
        {
            using var probe = new Font(family, 10f, FontStyle.Regular, GraphicsUnit.Point);
            return TextRenderer.MeasureText("iiiiiiii", probe).Width == TextRenderer.MeasureText("WWWWWWWW", probe).Width;
        }
        catch { return true; }
    }
}
