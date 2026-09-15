using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace QolSeriesInstaller;

/// <summary>One browsable community mod. "install" is either "mods" or "external".</summary>
internal sealed record CatalogMod(
    string Id, string Name, string Game, string Author, string Version, string Size,
    string Summary, string Image, string Repo, string Asset, string Install, string Url, string[] Tags)
{
    /// <summary>True when this app can put it in place itself: a package that drops into a mods folder.</summary>
    internal bool Installable => Install.Equals("mods", StringComparison.OrdinalIgnoreCase) && Repo.Length > 0;
}

/// <summary>
/// The browsable list. A copy ships inside the exe so the page works offline and on first run;
/// the live one is fetched from the repository, so mods can be added without a new build.
/// </summary>
internal static class Catalog
{
    private const string Remote = "https://raw.githubusercontent.com/DavidHiFi/QualityOfLifeSeries/main/catalog.json";
    private const string Resource = "catalog.json";

    internal static IReadOnlyList<CatalogMod> Bundled() => Parse(ReadBundled());

    internal static async Task<IReadOnlyList<CatalogMod>> LoadAsync(HttpClient http)
    {
        try
        {
            var text = await http.GetStringAsync(Remote);
            var live = Parse(text);
            if (live.Count > 0) return live;
        }
        catch { }
        return Bundled();
    }

    private static string ReadBundled()
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource);
        if (stream is null) return "";
        using var reader = new StreamReader(stream, Encoding.UTF8);
        return reader.ReadToEnd();
    }

    private static List<CatalogMod> Parse(string text)
    {
        var list = new List<CatalogMod>();
        if (text.Trim().Length == 0) return list;
        try
        {
            using var doc = JsonDocument.Parse(text);
            if (!doc.RootElement.TryGetProperty("mods", out var mods)) return list;
            foreach (var m in mods.EnumerateArray())
            {
                string S(string name) => m.TryGetProperty(name, out var v) ? v.GetString() ?? "" : "";
                var tags = m.TryGetProperty("tags", out var t) && t.ValueKind == JsonValueKind.Array
                    ? t.EnumerateArray().Select(x => x.GetString() ?? "").Where(x => x.Length > 0).ToArray()
                    : [];
                var id = S("id");
                if (id.Length == 0) continue;
                list.Add(new(id, S("name"), S("game"), S("author"), S("version"), S("size"),
                    S("summary"), S("image"), S("repo"), S("asset"), S("install"), S("url"), tags));
            }
        }
        catch { }
        return list;
    }
}

/// <summary>
/// Preview art, fetched once and kept on disk. Browsing must not re-download the same picture on
/// every visit, and must never block the window while a picture is in flight.
/// </summary>
internal static class ImageCache
{
    private static readonly Dictionary<string, Image?> Memory = [];
    private static string Dir => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "QualityOfLifeSeries", "previews");

    private static string FileFor(string url)
    {
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(url)))[..16];
        return Path.Combine(Dir, hash + ".img");
    }

    /// <summary>The picture if it is already to hand, otherwise null - never a download.</summary>
    internal static Image? Ready(string url)
    {
        if (url.Length == 0) return null;
        lock (Memory) { if (Memory.TryGetValue(url, out var cached)) return cached; }
        var file = FileFor(url);
        if (!File.Exists(file)) return null;
        try
        {
            using var raw = new MemoryStream(File.ReadAllBytes(file));
            var image = Image.FromStream(raw);
            lock (Memory) Memory[url] = image;
            return image;
        }
        catch { return null; }
    }

    internal static async Task<Image?> FetchAsync(string url, HttpClient http)
    {
        if (url.Length == 0) return null;
        var have = Ready(url);
        if (have is not null) return have;
        try
        {
            Directory.CreateDirectory(Dir);
            var bytes = await http.GetByteArrayAsync(url);
            await File.WriteAllBytesAsync(FileFor(url), bytes);
            return Ready(url);
        }
        catch
        {
            lock (Memory) Memory[url] = null;   // do not hammer a URL that will not load
            return null;
        }
    }
}
