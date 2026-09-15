using System.Text.Json;
using System.Text.Json.Serialization;

namespace QolSeriesInstaller;

// Properties, not fields: System.Text.Json only writes public properties, so fields here meant
// every saved setting came back as "{}" on the next run.
internal sealed class AppSettings
{
    [JsonPropertyName("theme")] public string Theme { get; set; } = "classic";
    [JsonPropertyName("playerName")] public string PlayerName { get; set; } = "";
    [JsonPropertyName("autoUpdate")] public bool AutoUpdate { get; set; } = true;
    [JsonPropertyName("tray")] public bool Tray { get; set; }
    [JsonPropertyName("minimizedHintShown")] public bool MinimizedHintShown { get; set; }
    /// <summary>Where settings were last exported, so importing offers that file back.</summary>
    [JsonPropertyName("lastExport")] public string LastExport { get; set; } = "";

    private static string? resolved;
    private static string Location
    {
        get
        {
            if (resolved is not null) return resolved;
            var local = Path.Combine(AppContext.BaseDirectory, "settings.json");
            try
            {
                using (File.Open(local, FileMode.OpenOrCreate, FileAccess.ReadWrite)) { }
                return resolved = local;
            }
            catch { }
            var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "QualityOfLifeSeries");
            Directory.CreateDirectory(dir);
            return resolved = Path.Combine(dir, "settings.json");
        }
    }

    internal static AppSettings Load()
    {
        try
        {
            var text = File.Exists(Location) ? File.ReadAllText(Location) : "";
            if (text.Trim().Length > 0)
                return JsonSerializer.Deserialize<AppSettings>(text) ?? new AppSettings();
        }
        catch { }
        return new AppSettings();
    }

    internal void Save()
    {
        try { File.WriteAllText(Location, JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true })); } catch { }
    }

    internal static string FilePath => Location;
}
