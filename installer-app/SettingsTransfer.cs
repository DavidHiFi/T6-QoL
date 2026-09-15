using System.IO.Compression;
using System.Text;
using System.Text.Json;

namespace QolSeriesInstaller;

/// <summary>What a settings file turned out to contain.</summary>
internal sealed record TransferSummary(bool HasApp, int ModFiles, string Exported, string FromVersion);

/// <summary>
/// One file carrying both halves of "my settings": this app's own options, and the mod's in-game
/// configuration - key binds, graphics, the menu's saved toggles. Exporting only one of the two
/// would surprise whichever half someone meant.
/// </summary>
internal static class SettingsTransfer
{
    internal const string Extension = ".qolsettings";
    private const string Manifest = "manifest.json";
    private const string AppEntry = "app-settings.json";
    private const string ModFolder = "mod-settings/";

    internal static string SuggestedName() => $"Quality of Life settings {DateTime.Now:yyyy-MM-dd}{Extension}";

    internal static TransferSummary Export(string path, AppSettings settings, InstallerService service)
    {
        var mod = service.CfgDir;
        var files = Directory.Exists(mod)
            ? Directory.EnumerateFiles(mod).Where(f => !f.EndsWith(".tmp", StringComparison.OrdinalIgnoreCase)).ToList()
            : [];

        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory)) Directory.CreateDirectory(directory);
        if (File.Exists(path)) File.Delete(path);

        using (var zip = ZipFile.Open(path, ZipArchiveMode.Create))
        {
            Write(zip, Manifest, JsonSerializer.Serialize(new
            {
                schema = 1,
                app = "Quality of Life Series",
                version = service.ProductVersion,
                exported = DateTime.Now.ToString("yyyy-MM-dd HH:mm"),
                modFiles = files.Count
            }, new JsonSerializerOptions { WriteIndented = true }));

            Write(zip, AppEntry, JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true }));

            foreach (var file in files)
                zip.CreateEntryFromFile(file, ModFolder + Path.GetFileName(file));
        }

        service.Log($"exported settings to {path} ({files.Count} mod file(s))");
        return new(true, files.Count, DateTime.Now.ToString("yyyy-MM-dd HH:mm"), service.ProductVersion);
    }

    /// <summary>Reads what is inside without changing anything, so the user can be told before it is applied.</summary>
    internal static TransferSummary Peek(string path)
    {
        using var zip = ZipFile.OpenRead(path);
        if (zip.GetEntry(Manifest) is null)
            throw new InvalidOperationException("That is not a Quality of Life settings file.");

        var hasApp = zip.GetEntry(AppEntry) is not null;
        var mods = zip.Entries.Count(IsModSetting);
        string exported = "", version = "";
        try
        {
            using var reader = new StreamReader(zip.GetEntry(Manifest)!.Open(), Encoding.UTF8);
            using var doc = JsonDocument.Parse(reader.ReadToEnd());
            if (doc.RootElement.TryGetProperty("exported", out var e)) exported = e.GetString() ?? "";
            if (doc.RootElement.TryGetProperty("version", out var v)) version = v.GetString() ?? "";
        }
        catch { }
        return new(hasApp, mods, exported, version);
    }

    /// <summary>
    /// Applies a settings file. The app's own options come back as an object for the caller to
    /// adopt; the mod's files are written straight to its config folder.
    /// </summary>
    internal static AppSettings? Import(string path, InstallerService service, out int modFiles, bool appOnly = false)
    {
        modFiles = 0;
        using var zip = ZipFile.OpenRead(path);
        if (zip.GetEntry(Manifest) is null)
            throw new InvalidOperationException("That is not a Quality of Life settings file.");

        var mods = appOnly ? [] : zip.Entries.Where(IsModSetting).ToList();
        // Only guard when game files are actually about to be written. The app's own options are
        // this app's file and are safe to restore whether or not Plutonium is running.
        if (mods.Count > 0)
        {
            service.Guard();
            Directory.CreateDirectory(service.CfgDir);
            foreach (var entry in mods)
            {
                var name = Path.GetFileName(entry.FullName);
                if (name.Length == 0 || name.Contains("..")) continue;   // never write outside the folder
                entry.ExtractToFile(Path.Combine(service.CfgDir, name), true);
                modFiles++;
            }
        }

        AppSettings? app = null;
        if (zip.GetEntry(AppEntry) is { } appEntry)
        {
            using var reader = new StreamReader(appEntry.Open(), Encoding.UTF8);
            try { app = JsonSerializer.Deserialize<AppSettings>(reader.ReadToEnd()); } catch { }
        }

        service.Log($"imported settings from {path} ({modFiles} mod file(s), app={(app is not null)})");
        return app;
    }

    /// <summary>
    /// Zip entry names are meant to use forward slashes, but plenty of tools - including
    /// ZipFile.CreateFromDirectory on Windows - write backslashes. Match either, or a file made
    /// by another tool silently arrives with its mod settings missing.
    /// </summary>
    private static bool IsModSetting(ZipArchiveEntry entry) =>
        entry.Name.Length > 0 && entry.FullName.Replace('\\', '/').StartsWith(ModFolder, StringComparison.OrdinalIgnoreCase);

    private static void Write(ZipArchive zip, string name, string text)
    {
        using var stream = zip.CreateEntry(name).Open();
        using var writer = new StreamWriter(stream, Encoding.UTF8);
        writer.Write(text);
    }
}
