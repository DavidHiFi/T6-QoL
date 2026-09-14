using System.Diagnostics;
using System.IO.Compression;
using System.Net.Http.Headers;
using System.Text.Json;

namespace QolSeriesInstaller;

internal sealed record InstallStatus(bool PlutoniumFound, bool PlutoniumRunning, string Mod, string Textures, string Sounds, string Controller, string ReShade, string Root);

internal sealed class InstallerService
{
    private static readonly string[] ModFiles = ["mod.ff", "mod.iwd", "mod.json", "mod.all.sabl", "mod.all.sabs"];
    private static readonly string[] ControllerNames = ["xenon_controller_top.iwi", "xenonbutton_a.iwi", "xenonbutton_b.iwi", "xenonbutton_x.iwi", "xenonbutton_y.iwi", "xenonbutton_back.iwi", "xenonbutton_start.iwi", "xenonbutton_lb.iwi", "xenonbutton_rb.iwi", "xenonbutton_lt.iwi", "xenonbutton_rt.iwi", "xenonbutton_ls.iwi", "xenonbutton_rs.iwi", "xenonbutton_dpad_all.iwi", "xenonbutton_dpad_up.iwi", "xenonbutton_dpad_down.iwi", "xenonbutton_dpad_left.iwi", "xenonbutton_dpad_right.iwi", "xenonbutton_dpad_ud.iwi", "xenonbutton_dpad_rl.iwi"];
    private readonly HttpClient http = new();
    internal readonly string Payload = Path.Combine(AppContext.BaseDirectory, "Mod Files");
    internal readonly string Pluto = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Plutonium");
    internal string T6 => Path.Combine(Pluto, "storage", "t6");
    internal string ModDir => Path.Combine(T6, "mods", "zm_qol");
    internal string Images => Path.Combine(T6, "images");
    internal string Zone => Path.Combine(T6, "zone");
    internal string State => Path.Combine(T6, "_zm_qol_installer");
    internal string Backups => Path.Combine(T6, "backups");
    internal string LogFile => Path.Combine(State, "installer.log");

    internal InstallerService() => http.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("QolSeriesInstaller", "2.16.7"));

    internal InstallStatus GetStatus() => new(
        Directory.Exists(Pluto), IsPlutoniumRunning(), ReadModVersion(), ManifestStatus("images", "not installed", "installed"),
        ManifestStatus("zone", "not installed", "installed"), ManifestStatus("controller", "game defaults", File.Exists(Path.Combine(State, "controller-pack.txt")) ? File.ReadAllText(Path.Combine(State, "controller-pack.txt")).Trim() : "installed"),
        File.Exists(Path.Combine(Pluto, "bin", "dxgi.dll")) ? "installed" : "not installed", Pluto);

    private string ManifestStatus(string name, string missing, string present) => File.Exists(Path.Combine(State, $"installed-{name}.txt")) ? present : missing;
    private bool IsPlutoniumRunning() => new[] { "plutonium-launcher-win32", "plutonium-bootstrapper-win32", "t6zm", "t6mp" }.Any(n => Process.GetProcessesByName(n).Length > 0);
    private void Guard() { if (IsPlutoniumRunning()) throw new InvalidOperationException("Close Plutonium before changing installed files."); }
    private void Log(string text) { Directory.CreateDirectory(State); File.AppendAllText(LogFile, $"{DateTime.Now:h:mm:ss tt}  {text}{Environment.NewLine}"); }
    private string ReadModVersion()
    {
        var path = Path.Combine(ModDir, "mod.json");
        if (!File.Exists(path)) return "not installed";
        try
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(path));
            var value = doc.RootElement.GetProperty("version").GetString() ?? "";
            return "v" + System.Text.RegularExpressions.Regex.Replace(value, @"\^[0-9]", "");
        }
        catch { return "installed"; }
    }

    internal async Task InstallModAsync(bool fresh, IProgress<string> progress)
    {
        Guard();
        foreach (var file in ModFiles) if (!File.Exists(Path.Combine(Payload, file))) throw new FileNotFoundException($"The package is missing {file}.");
        if (fresh) { var cfg = Path.Combine(T6, "players", "mods", "zm_qol"); if (Directory.Exists(cfg)) Directory.Delete(cfg, true); }
        Directory.CreateDirectory(ModDir);
        foreach (var old in Directory.EnumerateFiles(ModDir).Where(p => new[] { ".ff", ".iwd", ".json", ".sabl", ".sabs" }.Contains(Path.GetExtension(p), StringComparer.OrdinalIgnoreCase))) File.Delete(old);
        foreach (var file in ModFiles) { progress.Report($"Copying {file}"); File.Copy(Path.Combine(Payload, file), Path.Combine(ModDir, file), true); await Task.Yield(); }
        Log($"Installed mod, fresh={fresh}");
    }

    internal async Task InstallPackAsync(string kind, bool backup, IProgress<string> progress)
    {
        Guard();
        var dest = kind == "images" ? Images : Zone;
        var asset = kind == "images" ? "zm_qol-textures.zip" : "zm_qol-sounds.zip";
        var source = FindPayload(kind) ?? await DownloadAssetAsync(asset, kind, progress);
        if (source is null) throw new InvalidOperationException($"Could not find or download the {kind} pack.");
        if (backup) BackupFolder(kind, dest, progress);
        CopyTreeTracked(source, dest, kind, progress, kind == "images" ? ControllerNames.Append("hud_dpad_blood.iwi").ToHashSet(StringComparer.OrdinalIgnoreCase) : null);
        Log($"Installed {kind}");
    }

    internal async Task InstallControllerAsync(string pack, IProgress<string> progress)
    {
        Guard();
        var folder = pack switch { "ps5" => "Dualsense Icons", "switch" => "Nintendo Switch Icons", _ => "Xbox One Buttons" };
        var root = FindPayload(folder) ?? throw new InvalidOperationException($"The {folder} payload is not in this package.");
        var groups = Directory.EnumerateFiles(root, "*.iwi", SearchOption.AllDirectories).GroupBy(Path.GetDirectoryName).OrderByDescending(g => g.Count()).FirstOrDefault();
        if (groups is null) throw new InvalidOperationException("The controller pack contains no IWI files.");
        RemoveTracked("controller", Images, progress);
        CopyTreeTracked(groups.Key!, Images, "controller", progress);
        Directory.CreateDirectory(State); File.WriteAllText(Path.Combine(State, "controller-pack.txt"), pack);
        await Task.CompletedTask;
    }

    internal async Task InstallReShadeAsync(IProgress<string> progress)
    {
        Guard();
        var source = Path.Combine(Payload, "reshade");
        if (!Directory.Exists(source)) throw new DirectoryNotFoundException("The ReShade payload is missing.");
        var dest = Path.Combine(Pluto, "bin");
        BackupReShade(dest, progress);
        CopyTreeTracked(source, dest, "reshade", progress);
        var vault = Path.Combine(State, "reshade-vault"); if (Directory.Exists(vault)) Directory.Delete(vault, true); CopyDirectory(source, vault, progress);
        await Task.CompletedTask;
    }

    internal void Remove(string kind, bool restore, IProgress<string> progress)
    {
        Guard();
        var dest = kind switch { "mod" => ModDir, "images" or "controller" => Images, "zone" => Zone, "reshade" => Path.Combine(Pluto, "bin"), _ => throw new ArgumentOutOfRangeException(nameof(kind)) };
        if (kind == "mod") { foreach (var f in ModFiles) { var p = Path.Combine(dest, f); if (File.Exists(p)) File.Delete(p); } }
        else RemoveTracked(kind, dest, progress);
        if (restore) Restore(kind, dest, progress);
        Log($"Removed {kind}, restore={restore}");
    }

    internal void OpenLog() { Directory.CreateDirectory(State); if (!File.Exists(LogFile)) File.WriteAllText(LogFile, "No actions recorded yet." + Environment.NewLine); Process.Start(new ProcessStartInfo(LogFile) { UseShellExecute = true }); }
    internal void OpenFolder(string path) { Directory.CreateDirectory(path); Process.Start(new ProcessStartInfo("explorer.exe", $"\"{path}\"") { UseShellExecute = true }); }
    internal void OpenReleases() => Process.Start(new ProcessStartInfo("https://github.com/DavidHiFi/T6-QoL/releases/latest") { UseShellExecute = true });
    internal void StartBundled(string file)
    {
        var path = Path.Combine(Payload, file);
        if (!File.Exists(path)) throw new FileNotFoundException($"The package is missing {file}.");
        Process.Start(new ProcessStartInfo(path) { UseShellExecute = true, WorkingDirectory = Payload });
        Log($"Started {file}");
    }

    private string? FindPayload(string name)
    {
        var direct = Path.Combine(Payload, name); if (Directory.Exists(direct)) return direct;
        var parent = Directory.GetParent(AppContext.BaseDirectory)?.FullName;
        return parent is null ? null : Directory.EnumerateDirectories(parent, name, SearchOption.AllDirectories).FirstOrDefault();
    }

    private async Task<string?> DownloadAssetAsync(string assetName, string folder, IProgress<string> progress)
    {
        progress.Report($"Finding {assetName} on GitHub");
        using var json = JsonDocument.Parse(await http.GetStringAsync("https://api.github.com/repos/DavidHiFi/T6-QoL/releases?per_page=30"));
        foreach (var release in json.RootElement.EnumerateArray()) foreach (var asset in release.GetProperty("assets").EnumerateArray())
        {
            if (!asset.GetProperty("name").GetString()!.Equals(assetName, StringComparison.OrdinalIgnoreCase)) continue;
            var temp = Path.Combine(Path.GetTempPath(), "qol-series-installer", Guid.NewGuid().ToString("N")); Directory.CreateDirectory(temp);
            var zip = Path.Combine(temp, assetName); progress.Report($"Downloading {assetName}");
            await using (var output = File.Create(zip)) await (await http.GetAsync(asset.GetProperty("browser_download_url").GetString(), HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
            var outputDir = Path.Combine(temp, folder); ZipFile.ExtractToDirectory(zip, outputDir); var inner = Path.Combine(outputDir, folder); return Directory.Exists(inner) ? inner : outputDir;
        }
        return null;
    }

    private void CopyTreeTracked(string source, string dest, string kind, IProgress<string> progress, HashSet<string>? blocked = null)
    {
        Directory.CreateDirectory(dest); var written = new List<string>();
        foreach (var file in Directory.EnumerateFiles(source, "*", SearchOption.AllDirectories))
        {
            if (blocked?.Contains(Path.GetFileName(file)) == true) continue;
            var rel = Path.GetRelativePath(source, file); var target = Path.Combine(dest, rel); Directory.CreateDirectory(Path.GetDirectoryName(target)!); File.Copy(file, target, true); written.Add(rel); progress.Report($"Copying {rel}");
        }
        Directory.CreateDirectory(State); File.WriteAllLines(Path.Combine(State, $"installed-{kind}.txt"), written);
    }

    private void RemoveTracked(string kind, string dest, IProgress<string> progress)
    {
        var manifest = Path.Combine(State, $"installed-{kind}.txt"); if (!File.Exists(manifest)) return;
        foreach (var rel in File.ReadLines(manifest)) { var path = Path.GetFullPath(Path.Combine(dest, rel)); if (!path.StartsWith(Path.GetFullPath(dest), StringComparison.OrdinalIgnoreCase)) continue; if (File.Exists(path)) { File.Delete(path); progress.Report($"Removed {rel}"); } }
        File.Delete(manifest);
    }

    private void BackupFolder(string kind, string source, IProgress<string> progress)
    {
        var dest = Path.Combine(Backups, kind); if (Directory.Exists(dest) || !Directory.Exists(source)) return; CopyDirectory(source, dest, progress);
    }
    private void BackupReShade(string source, IProgress<string> progress)
    {
        var dest = Path.Combine(Backups, "reshade"); if (Directory.Exists(dest)) return; Directory.CreateDirectory(dest);
        foreach (var name in new[] { "dxgi.dll", "ReShade.ini", "BO1.ini", "BO2.ini", "MW3.ini", "WAW.ini", "Cinematic Colour Grading.ini" }) { var f = Path.Combine(source, name); if (File.Exists(f)) File.Copy(f, Path.Combine(dest, name), true); }
        var shaders = Path.Combine(source, "reshade-shaders"); if (Directory.Exists(shaders)) CopyDirectory(shaders, Path.Combine(dest, "reshade-shaders"), progress);
    }
    private void Restore(string kind, string dest, IProgress<string> progress) { var source = Path.Combine(Backups, kind); if (Directory.Exists(source)) CopyDirectory(source, dest, progress); }
    private static void CopyDirectory(string source, string dest, IProgress<string> progress) { foreach (var file in Directory.EnumerateFiles(source, "*", SearchOption.AllDirectories)) { var rel = Path.GetRelativePath(source, file); var target = Path.Combine(dest, rel); Directory.CreateDirectory(Path.GetDirectoryName(target)!); File.Copy(file, target, true); progress.Report($"Copying {rel}"); } }
}
