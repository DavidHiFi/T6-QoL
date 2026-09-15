using System.Diagnostics;
using System.IO.Compression;
using System.Net.Http.Headers;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace QolSeriesInstaller;

internal sealed record InstallStatus(bool PlutoniumFound, bool PlutoniumRunning, string Mod, string Textures, string Sounds, string Controller, string ReShade, string Shortcuts, string Backups, string Root);

internal sealed record BackupState(string Kind, string Label, string Title, bool Exists, int Files, long Bytes, DateTime? When, int LiveFiles, long LiveBytes);

internal sealed record ShortcutInfo(string File, string Label, string Target, bool Present, bool Broken);

internal sealed record UpdateResult(bool Ok, string Summary, bool CanInstall);

internal sealed record UpdateCheck(bool Ok, string Summary, string ModTag, string AppTag, bool ModUpdate, bool AppUpdate, bool CanInstallMod, bool CanInstallApp);

internal sealed record InstalledMod(string Folder, string Name, string Version, string Path, long Bytes, bool QualityOfLife);

internal sealed class InstallerService
{
    internal static string RootOverride = "";
    internal static string StartMenuOverride = "";
    internal static bool SkipRunningCheck = false;

    private static readonly string[] ModFiles = ["mod.ff", "mod.iwd", "mod.json", "mod.all.sabl", "mod.all.sabs"];
    private static readonly string[] SettingsFiles = ["plutonium_zm.cfg", "bindings_zm.bdg", "hardware_zm.chp", "user_zm.cgp", "user_common.cgp"];
    private static readonly string[] ReshadeFiles = ["ReShade.ini", "Cinematic Colour Grading.ini", "BO2.ini", "BO1.ini", "MW3.ini", "WAW.ini", "dxgi.dll"];
    private static readonly int[] AaValid = [1, 2, 4, 8];
    private static readonly string[] ControllerNames = ["xenon_controller_top.iwi", "xenonbutton_a.iwi", "xenonbutton_b.iwi", "xenonbutton_x.iwi", "xenonbutton_y.iwi", "xenonbutton_back.iwi", "xenonbutton_start.iwi", "xenonbutton_lb.iwi", "xenonbutton_rb.iwi", "xenonbutton_lt.iwi", "xenonbutton_rt.iwi", "xenonbutton_ls.iwi", "xenonbutton_rs.iwi", "xenonbutton_dpad_all.iwi", "xenonbutton_dpad_up.iwi", "xenonbutton_dpad_down.iwi", "xenonbutton_dpad_left.iwi", "xenonbutton_dpad_right.iwi", "xenonbutton_dpad_ud.iwi", "xenonbutton_dpad_rl.iwi"];

    private const int AaFallback = 4;
    internal const string SeriesName = "Quality of Life Series";
    internal const string LauncherShortcut = "Quality of Life Series Launcher.lnk";
    internal const string WatcherShortcut = "Plutonium ReShade Watcher.lnk";
    private const string Repo = "DavidHiFi/T6-QoL";
    private const string ToolRepo = "DavidHiFi/QualityOfLifeSeries";
    internal const string ModRepoUrl = "https://github.com/" + Repo;
    internal const string ToolRepoUrl = "https://github.com/" + ToolRepo;

    private readonly HttpClient http = new();
    private string? updateZipUrl;
    private string? updateZipName;
    private string? appZipUrl;
    private string? appZipName;

    // Resolved rather than assumed: the support files ride inside the exe and are unpacked beside
    // it, or into the profile when the exe sits somewhere unwritable.
    internal readonly string Payload = QolSeriesInstaller.Payload.Dir;
    internal readonly string Pluto = RootOverride.Length > 0 ? RootOverride : System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Plutonium");
    internal string T6 => System.IO.Path.Combine(Pluto, "storage", "t6");
    internal string Storage => Directory.Exists(System.IO.Path.Combine(Pluto, "storage")) ? System.IO.Path.Combine(Pluto, "storage") : Pluto;
    internal string StorageFor(string game) => System.IO.Path.Combine(Pluto, "storage", game);
    internal string ModsDir(string game) => System.IO.Path.Combine(StorageFor(game), "mods");
    internal static string FormatSize(long bytes) => bytes >= 1L << 30 ? $"{bytes / (double)(1L << 30):0.#} GB" : bytes >= 1L << 20 ? $"{bytes / (double)(1L << 20):0.#} MB" : bytes >= 1L << 10 ? $"{bytes / (double)(1L << 10):0.#} KB" : $"{bytes} B";

    /// <summary>
    /// Just how many, without walking every file for a size. Some of these folders hold 25 GB
    /// across 80-odd mods, so the overview page must not pay for that three times over.
    /// </summary>
    internal int CountMods(string game)
    {
        var dir = ModsDir(game);
        try { return Directory.Exists(dir) ? Directory.EnumerateDirectories(dir).Count() : 0; }
        catch { return 0; }
    }

    internal IReadOnlyList<InstalledMod> GetInstalledMods(string game)
    {
        var dir = ModsDir(game);
        if (!Directory.Exists(dir)) return [];
        var list = new List<InstalledMod>();
        foreach (var folder in Directory.EnumerateDirectories(dir))
        {
            var name = Regex.Replace(System.IO.Path.GetFileName(folder), @"\^[0-9:;]", "").Trim();
            var version = "";
            var json = System.IO.Path.Combine(folder, "mod.json");
            if (File.Exists(json))
            {
                try
                {
                    using var doc = JsonDocument.Parse(File.ReadAllText(json));
                    // Mod names carry Call of Duty colour codes (^1, ^5). They mean nothing outside
                    // the game's own text renderer, so they do not belong in this list.
                    if (doc.RootElement.TryGetProperty("name", out var n)) name = Regex.Replace(n.GetString() ?? name, @"\^[0-9:;]", "").Trim();
                    if (doc.RootElement.TryGetProperty("version", out var v)) version = "v" + Regex.Replace(v.GetString() ?? "", @"\^[0-9]", "");
                }
                catch { }
            }
            // DirectoryInfo hands back the length from the directory entry it already read;
            // new FileInfo(path).Length would stat every file again - six times slower over 25 GB.
            long bytes = 0;
            try { foreach (var f in new DirectoryInfo(folder).EnumerateFiles("*", SearchOption.AllDirectories)) bytes += f.Length; } catch { }
            list.Add(new(folder, name, version, folder, bytes, System.IO.Path.GetFileName(folder).Equals("zm_qol", StringComparison.OrdinalIgnoreCase)));
        }
        return list.OrderBy(m => m.Name, StringComparer.OrdinalIgnoreCase).ToList();
    }

    internal void RemoveModFolder(string game, string path, IProgress<string> progress)
    {
        Guard();
        var root = System.IO.Path.GetFullPath(ModsDir(game));
        var full = System.IO.Path.GetFullPath(path);
        if (!full.StartsWith(root, StringComparison.OrdinalIgnoreCase) || full.Equals(root, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("That folder is not inside this game's mods folder.");
        progress.Report("Removing " + System.IO.Path.GetFileName(full));
        Directory.Delete(full, true);
        Log($"removed mod folder {full}");
    }

    internal async Task InstallModFromFileAsync(string game, string file, IProgress<string> progress)
    {
        Guard();
        var mods = ModsDir(game);
        Directory.CreateDirectory(mods);
        var ext = System.IO.Path.GetExtension(file).ToLowerInvariant();
        if (ext == ".zip")
        {
            var target = System.IO.Path.Combine(mods, System.IO.Path.GetFileNameWithoutExtension(file));
            if (Directory.Exists(target)) throw new InvalidOperationException($"{System.IO.Path.GetFileName(target)} is already installed - remove it first.");
            Directory.CreateDirectory(target);
            ZipFile.ExtractToDirectory(file, target);
            var entries = Directory.EnumerateDirectories(target).ToList();
            if (!File.Exists(System.IO.Path.Combine(target, "mod.json")) && entries.Count == 1 && File.Exists(System.IO.Path.Combine(entries[0], "mod.json")))
            {
                foreach (var entry in Directory.EnumerateFileSystemEntries(entries[0])) Directory.Move(entry, System.IO.Path.Combine(target, System.IO.Path.GetFileName(entry)));
                Directory.Delete(entries[0]);
            }
            progress.Report($"Installed {System.IO.Path.GetFileNameWithoutExtension(file)}");
            Log($"installed mod from {file} into {target}");
        }
        else if (new[] { ".ff", ".iwd", ".sabl", ".sabs", ".json" }.Contains(ext))
        {
            var target = System.IO.Path.Combine(mods, System.IO.Path.GetFileNameWithoutExtension(file));
            Directory.CreateDirectory(target);
            File.Copy(file, System.IO.Path.Combine(target, System.IO.Path.GetFileName(file)), true);
            progress.Report($"Installed {System.IO.Path.GetFileName(file)}");
            Log($"installed mod file {file} into {target}");
        }
        else throw new InvalidOperationException("Pick a .zip or a mod .ff/.iwd file.");
        await Task.CompletedTask;
    }
    internal string ModDir => System.IO.Path.Combine(T6, "mods", "zm_qol");
    internal string CfgDir => System.IO.Path.Combine(T6, "players", "mods", "zm_qol");
    internal string Images => System.IO.Path.Combine(T6, "images");
    internal string Zone => System.IO.Path.Combine(T6, "zone");
    internal string BinDir => System.IO.Path.Combine(Pluto, "bin");
    internal string State => System.IO.Path.Combine(T6, "_zm_qol_installer");
    internal string Backups => System.IO.Path.Combine(T6, "backups");
    internal string LogFile => System.IO.Path.Combine(State, "installer.log");
    internal string StartMenuDir => StartMenuOverride.Length > 0 ? StartMenuOverride : System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Microsoft", "Windows", "Start Menu", "Programs", SeriesName);
    internal string ProductVersion => typeof(InstallerService).Assembly.GetName().Version?.ToString(3) ?? "2.16.7";

    internal InstallerService() => http.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("QolSeriesInstaller", ProductVersion));

    private sealed record BackupPart(string Sub, string Path, bool Folder, string[]? Items = null, string? Glob = null);
    private sealed record BackupSet(string Label, string Title, BackupPart[] Parts);

    private Dictionary<string, BackupSet> Sets() => new()
    {
        ["images"] = new("My textures", "your textures", [new("images", Images, true)]),
        ["zone"] = new("My sounds", "your sounds", [new("zone", Zone, true)]),
        ["controller"] = new("My controller icons", "your controller icons", [new("controller", Images, false, ControllerNames)]),
        ["reshade"] = new("My ReShade setup", "your ReShade setup", [new("bin", BinDir, false, ReshadeFiles, "*.ini"), new("reshade-shaders", System.IO.Path.Combine(BinDir, "reshade-shaders"), true)]),
        ["mod"] = new("The mod + my settings", "the mod", [new("files", ModDir, true), new("settings", CfgDir, false, SettingsFiles)]),
    };

    internal IReadOnlyList<string> BackupKinds => ["images", "zone", "controller", "reshade", "mod"];

    internal InstallStatus GetStatus()
    {
        var backed = BackupKinds.Count(k => Directory.Exists(System.IO.Path.Combine(Backups, k)));
        return new(
            Directory.Exists(Pluto), IsPlutoniumRunning(), ReadModVersion(), ManifestStatus("images", "not installed", "installed"),
            ManifestStatus("zone", "not installed", "installed"), ManifestStatus("controller", "game defaults", File.Exists(System.IO.Path.Combine(State, "controller-pack.txt")) ? File.ReadAllText(System.IO.Path.Combine(State, "controller-pack.txt")).Trim() : "installed"),
            File.Exists(System.IO.Path.Combine(BinDir, "dxgi.dll")) ? "installed" : "not installed",
            ShortcutStatus(), backed == 0 ? "none yet" : $"{backed} of {BackupKinds.Count} backed up", Pluto);
    }

    private string ManifestStatus(string name, string missing, string present) => File.Exists(System.IO.Path.Combine(State, $"installed-{name}.txt")) ? present : missing;
    private bool IsPlutoniumRunning() => new[] { "plutonium-launcher-win32", "plutonium-bootstrapper-win32", "t6zm", "t6mp" }.Any(n => Process.GetProcessesByName(n).Length > 0);
    private void Guard() { if (!SkipRunningCheck && IsPlutoniumRunning()) throw new InvalidOperationException("Close Plutonium before changing installed files."); }
    internal void Log(string text) { Directory.CreateDirectory(State); File.AppendAllText(LogFile, $"{DateTime.Now:h:mm:ss tt}  {text}{Environment.NewLine}"); }

    internal string ReadModVersion()
    {
        var path = System.IO.Path.Combine(ModDir, "mod.json");
        if (!File.Exists(path)) return "not installed";
        try
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(path));
            var value = doc.RootElement.GetProperty("version").GetString() ?? "";
            return "v" + Regex.Replace(value, @"\^[0-9]", "");
        }
        catch { return "installed"; }
    }

    private void RepairBadAaSamples(IProgress<string>? progress)
    {
        foreach (var path in new[] { System.IO.Path.Combine(CfgDir, "plutonium_zm.cfg"), System.IO.Path.Combine(Backups, "mod", "settings", "plutonium_zm.cfg") })
        {
            if (!File.Exists(path)) continue;
            string raw;
            try { raw = File.ReadAllText(path); } catch { continue; }
            var match = Regex.Match(raw, "(?m)^[ \t]*seta[ \t]+r_aaSamples[ \t]+\"?(-?\\d+)\"?");
            if (!match.Success || !int.TryParse(match.Groups[1].Value, out var value) || AaValid.Contains(value)) continue;
            var fixedText = Regex.Replace(raw, "(?m)^([ \t]*seta[ \t]+r_aaSamples[ \t]+)\"?-?\\d+\"?", m => m.Groups[1].Value + "\"" + AaFallback + "\"");
            try { File.WriteAllText(path, fixedText, new UTF8Encoding(false)); } catch { continue; }
            Log($"repaired r_aaSamples {value} -> {AaFallback} in {path}");
            progress?.Report($"Set r_aaSamples back to {AaFallback}x (it was saved as {value}x and stops the game starting)");
        }
    }

    internal async Task InstallModAsync(bool fresh, IProgress<string> progress)
    {
        Guard();
        RepairBadAaSamples(progress);
        var source = Payload;
        if (ModFiles.Any(f => !File.Exists(System.IO.Path.Combine(source, f))))
        {
            progress.Report("The mod files are not beside this app - downloading them");
            source = await DownloadModPackageAsync(progress) ?? throw new FileNotFoundException("The package is missing the mod files and the download from GitHub failed.");
        }
        if (fresh && Directory.Exists(CfgDir)) Directory.Delete(CfgDir, true);
        Directory.CreateDirectory(ModDir);
        foreach (var old in Directory.EnumerateFiles(ModDir).Where(p => new[] { ".ff", ".iwd", ".json", ".sabl", ".sabs" }.Contains(System.IO.Path.GetExtension(p), StringComparer.OrdinalIgnoreCase))) File.Delete(old);
        foreach (var file in ModFiles) { progress.Report($"Copying {file}"); File.Copy(System.IO.Path.Combine(source, file), System.IO.Path.Combine(ModDir, file), true); await Task.Yield(); }
        Log($"Installed mod, fresh={fresh}");
    }

    private async Task<string?> DownloadModPackageAsync(IProgress<string> progress)
    {
        using var doc = JsonDocument.Parse(await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases?per_page=30"));
        foreach (var release in doc.RootElement.EnumerateArray()) foreach (var asset in release.GetProperty("assets").EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (!name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase) || name.Contains("texture", StringComparison.OrdinalIgnoreCase) || name.Contains("sound", StringComparison.OrdinalIgnoreCase) || name.Contains("portable", StringComparison.OrdinalIgnoreCase)) continue;
            var temp = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "qol-series-installer", Guid.NewGuid().ToString("N")); Directory.CreateDirectory(temp);
            var zip = System.IO.Path.Combine(temp, name); progress.Report($"Downloading {name}");
            await using (var output = File.Create(zip)) await (await http.GetAsync(asset.GetProperty("browser_download_url").GetString(), HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
            progress.Report("Unpacking");
            var outDir = System.IO.Path.Combine(temp, "unpack");
            ZipFile.ExtractToDirectory(zip, outDir);
            var modJson = Directory.EnumerateFiles(outDir, "mod.json", SearchOption.AllDirectories).FirstOrDefault();
            var source = modJson is null ? null : System.IO.Path.GetDirectoryName(modJson);
            if (source is not null && ModFiles.All(f => File.Exists(System.IO.Path.Combine(source, f)))) return source;
        }
        return null;
    }

    internal async Task InstallEverythingAsync(IProgress<string> progress)
    {
        await InstallModAsync(false, progress);
        await InstallPackAsync("images", true, progress);
        await InstallPackAsync("zone", true, progress);
    }

    internal async Task InstallPackAsync(string kind, bool backup, IProgress<string> progress)
    {
        Guard();
        var dest = kind == "images" ? Images : Zone;
        var asset = kind == "images" ? "zm_qol-textures.zip" : "zm_qol-sounds.zip";
        var source = FindPayload(kind) ?? await DownloadAssetAsync(asset, kind, progress);
        if (source is null) throw new InvalidOperationException($"Could not find or download the {kind} pack.");
        if (backup) BackupKind(kind, false, progress);
        CopyTreeTracked(source, dest, kind, progress, kind == "images" ? ControllerNames.Append("hud_dpad_blood.iwi").ToHashSet(StringComparer.OrdinalIgnoreCase) : null);
        if (kind == "images") ReapplyController(progress);
        Log($"Installed {kind}");
    }

    private void ReapplyController(IProgress<string>? progress)
    {
        var packFile = System.IO.Path.Combine(State, "controller-pack.txt");
        if (!File.Exists(packFile)) return;
        var pack = File.ReadAllText(packFile).Trim();
        var source = ResolveControllerSource(pack);
        if (source is null) { Log($"controller pack {pack} not in package, could not re-apply after texture install"); return; }
        progress?.Report("Re-applying your controller icons");
        CopyTreeTracked(source, Images, "controller", progress ?? new Progress<string>());
    }

    internal async Task InstallControllerAsync(string pack, IProgress<string> progress)
    {
        Guard();
        var root = ResolveControllerSource(pack) ?? throw new InvalidOperationException($"The {pack} controller pack is not in this package.");
        var groups = Directory.EnumerateFiles(root, "*.iwi", SearchOption.AllDirectories).GroupBy(System.IO.Path.GetDirectoryName).OrderByDescending(g => g.Count()).FirstOrDefault();
        if (groups is null) throw new InvalidOperationException("The controller pack contains no IWI files.");
        RemoveTracked("controller", Images, progress);
        CopyTreeTracked(groups.Key!, Images, "controller", progress);
        Directory.CreateDirectory(State); File.WriteAllText(System.IO.Path.Combine(State, "controller-pack.txt"), pack);
        await Task.CompletedTask;
    }

    private string? ResolveControllerSource(string pack)
    {
        var folder = pack switch { "ps5" => "Dualsense Icons", "switch" => "Nintendo Switch Icons", _ => "Xbox One Buttons" };
        return FindPayload(folder);
    }

    internal async Task InstallReShadeAsync(IProgress<string> progress)
    {
        Guard();
        var source = System.IO.Path.Combine(Payload, "reshade");
        if (!Directory.Exists(source)) throw new DirectoryNotFoundException("The ReShade payload is missing.");
        BackupReShade(BinDir, progress);
        foreach (var name in ReshadeFiles.Where(n => n.EndsWith(".ini", StringComparison.OrdinalIgnoreCase)).Append("ReShade.ini").Distinct())
        {
            var p = System.IO.Path.Combine(BinDir, name);
            if (File.Exists(p) && !File.Exists(p + ".backup")) File.Copy(p, p + ".backup", true);
        }
        CopyTreeTracked(source, BinDir, "reshade", progress);
        var vault = System.IO.Path.Combine(State, "reshade-vault");
        if (Directory.Exists(vault)) Directory.Delete(vault, true);
        CopyDirectory(source, vault, progress);
        await Task.CompletedTask;
    }

    internal void Remove(string kind, bool restore, IProgress<string> progress)
    {
        Guard();
        var dest = kind switch { "mod" => ModDir, "images" or "controller" => Images, "zone" => Zone, "reshade" => BinDir, _ => throw new ArgumentOutOfRangeException(nameof(kind)) };
        if (kind == "mod") { foreach (var f in ModFiles) { var p = System.IO.Path.Combine(dest, f); if (File.Exists(p)) File.Delete(p); } }
        else RemoveTracked(kind, dest, progress);
        if (kind == "controller") File.Delete(System.IO.Path.Combine(State, "controller-pack.txt"));
        if (kind == "reshade")
        {
            var vault = System.IO.Path.Combine(State, "reshade-vault");
            if (Directory.Exists(vault)) Directory.Delete(vault, true);
        }
        if (restore) RestoreKind(kind, progress);
        Log($"Removed {kind}, restore={restore}");
    }

    internal void RemoveEverything(bool restore, IProgress<string> progress)
    {
        Remove("images", restore, progress);
        Remove("zone", restore, progress);
        Remove("controller", restore, progress);
        RemoveShortcuts();
        Remove("reshade", restore, progress);
        Remove("mod", restore, progress);
        Log($"Removed everything, restore={restore}");
    }

    internal bool HasBackup(string kind) => Directory.Exists(System.IO.Path.Combine(Backups, kind));

    private IEnumerable<FileInfo> BackupSource(BackupPart part)
    {
        if (part.Folder)
        {
            if (!Directory.Exists(part.Path)) yield break;
            foreach (var f in Directory.EnumerateFiles(part.Path, "*", SearchOption.AllDirectories)) yield return new FileInfo(f);
            yield break;
        }
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var name in part.Items ?? [])
        {
            var p = System.IO.Path.Combine(part.Path, name);
            if (File.Exists(p) && seen.Add(name)) yield return new FileInfo(p);
        }
        if (part.Glob is not null && Directory.Exists(part.Path))
            foreach (var f in Directory.EnumerateFiles(part.Path, part.Glob)) if (seen.Add(System.IO.Path.GetFileName(f))) yield return new FileInfo(f);
    }

    private (int Count, long Bytes) MeasureBackupSource(string kind)
    {
        var count = 0; long bytes = 0;
        foreach (var part in Sets()[kind].Parts) foreach (var f in BackupSource(part)) { count++; bytes += f.Length; }
        return (count, bytes);
    }

    internal BackupState GetBackup(string kind)
    {
        var set = Sets()[kind];
        var dir = System.IO.Path.Combine(Backups, kind);
        var (liveCount, liveBytes) = MeasureBackupSource(kind);
        if (!Directory.Exists(dir)) return new(kind, set.Label, set.Title, false, 0, 0, null, liveCount, liveBytes);
        var files = Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories).ToList();
        long bytes = 0; foreach (var f in files) bytes += new FileInfo(f).Length;
        return new(kind, set.Label, set.Title, true, files.Count, bytes, Directory.GetLastWriteTime(dir), liveCount, liveBytes);
    }

    internal IReadOnlyList<BackupState> GetBackups() => BackupKinds.Select(GetBackup).ToList();

    internal string BackupKind(string kind, bool replace, IProgress<string>? progress = null)
    {
        var set = Sets()[kind];
        var dest = System.IO.Path.Combine(Backups, kind);
        var (count, bytes) = MeasureBackupSource(kind);
        if (count == 0) return "Nothing to back up - there are no files of yours there yet.";
        if (Directory.Exists(dest) && !replace) return $"A backup of {set.Title} already exists - keeping the older one.";
        if (Directory.Exists(dest)) Directory.Delete(dest, true);
        Directory.CreateDirectory(dest);
        foreach (var part in set.Parts)
        {
            var files = BackupSource(part).ToList();
            if (files.Count == 0) continue;
            var to = System.IO.Path.Combine(dest, part.Sub);
            if (part.Folder) { CopyDirectory(part.Path, to, progress ?? new Progress<string>()); }
            else
            {
                Directory.CreateDirectory(to);
                foreach (var f in files) { File.Copy(f.FullName, System.IO.Path.Combine(to, f.Name), true); progress?.Report($"Backing up {f.Name}"); }
            }
        }
        Log($"backup: {kind} -> {dest}");
        return $"Backed up {set.Title} - {count} file(s).";
    }

    internal bool RestoreKind(string kind, IProgress<string>? progress = null)
    {
        Guard();
        var set = Sets()[kind];
        var dir = System.IO.Path.Combine(Backups, kind);
        if (!Directory.Exists(dir)) return false;
        var did = 0;
        foreach (var part in set.Parts)
        {
            var from = System.IO.Path.Combine(dir, part.Sub);
            if (!Directory.Exists(from)) continue;
            if (part.Folder) { CopyDirectory(from, part.Path, progress ?? new Progress<string>()); did++; }
            else
            {
                Directory.CreateDirectory(part.Path);
                foreach (var f in Directory.EnumerateFiles(from)) { File.Copy(f, System.IO.Path.Combine(part.Path, System.IO.Path.GetFileName(f)), true); did++; }
            }
        }
        if (did == 0) return false;
        Log($"restore: {kind}");
        return true;
    }

    internal void DeleteBackup(string kind)
    {
        var dir = System.IO.Path.Combine(Backups, kind);
        if (Directory.Exists(dir)) Directory.Delete(dir, true);
        Log($"backup deleted: {kind}");
    }

    internal string ShortcutStatus()
    {
        var list = GetShortcuts();
        var present = list.Count(s => s.Present);
        if (present == 0) return "not added";
        if (list.Any(s => s.Broken)) return "target missing";
        return present == list.Count ? "installed" : $"{present} of {list.Count} added";
    }

    internal IReadOnlyList<ShortcutInfo> GetShortcuts()
    {
        var list = new List<ShortcutInfo> { DescribeShortcut(LauncherShortcut, "Quality of Life Series Launcher"), DescribeShortcut(WatcherShortcut, "Plutonium ReShade Watcher") };
        return list;
    }

    private ShortcutInfo DescribeShortcut(string file, string label)
    {
        var path = System.IO.Path.Combine(StartMenuDir, file);
        if (!File.Exists(path)) return new(file, label, "", false, false);
        string target = "", args = "";
        try
        {
            var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!)!;
            try
            {
                dynamic lnk = shell.GetType().InvokeMember("CreateShortcut", System.Reflection.BindingFlags.InvokeMethod, null, shell, [path])!;
                target = (string)lnk.TargetPath;
                args = (string)lnk.Arguments;
                Marshal.FinalReleaseComObject(lnk);
            }
            finally { Marshal.FinalReleaseComObject(shell); }
        }
        catch { return new(file, label, target, true, true); }
        var alive = target.Length > 0 && File.Exists(target);
        var match = Regex.Match(args, "-File\\s+\"([^\"]+)\"");
        if (alive && match.Success && !File.Exists(match.Groups[1].Value)) alive = false;
        return new(file, label, target, true, !alive);
    }

    internal string InstallShortcuts(bool launcher, bool watcher, IProgress<string>? progress = null)
    {
        var made = 0;
        var manifest = ReadManifest("shortcuts");
        if (launcher)
        {
            var exe = Environment.ProcessPath;
            if (exe is not null && File.Exists(exe))
            {
                var icon = System.IO.Path.Combine(Payload, "qol_installer.ico");
                WriteShortcut(LauncherShortcut, exe, "", System.IO.Path.GetDirectoryName(exe)!, "The Quality of Life Series launcher - install, update or remove the mods", icon);
                manifest.Add(LauncherShortcut); made++; progress?.Report("Added the launcher shortcut");
            }
        }
        if (watcher)
        {
            var bat = System.IO.Path.Combine(Payload, "Play BO2 with ReShade.bat");
            var ps1 = System.IO.Path.Combine(Payload, "reshade-watchdog.ps1");
            var icon = System.IO.Path.Combine(Payload, "reshade_watcher.ico");
            if (File.Exists(bat))
            {
                WriteShortcut(WatcherShortcut, bat, "", Payload, "Puts ReShade back whenever Plutonium clears it out - leave it open while you play", icon);
                manifest.Add(WatcherShortcut); made++; progress?.Report("Added the ReShade watcher shortcut");
            }
            else if (File.Exists(ps1))
            {
                var powershell = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
                if (!File.Exists(powershell)) powershell = "powershell.exe";
                WriteShortcut(WatcherShortcut, powershell, $"-NoProfile -ExecutionPolicy Bypass -File \"{ps1}\"", Payload, "Puts ReShade back whenever Plutonium clears it out - leave it open while you play", icon);
                manifest.Add(WatcherShortcut); made++; progress?.Report("Added the ReShade watcher shortcut");
            }
        }
        if (made > 0) WriteManifest("shortcuts", manifest);
        return made == 0 ? "Nothing was added - the target files are not in this package." : $"Added {made} shortcut(s) to the Start menu.";
    }

    private void WriteShortcut(string file, string target, string args, string workdir, string description, string icon)
    {
        Directory.CreateDirectory(StartMenuDir);
        var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!)!;
        try
        {
            dynamic lnk = shell.GetType().InvokeMember("CreateShortcut", System.Reflection.BindingFlags.InvokeMethod, null, shell, [System.IO.Path.Combine(StartMenuDir, file)])!;
            lnk.TargetPath = target;
            if (args.Length > 0) lnk.Arguments = args;
            lnk.WorkingDirectory = workdir;
            lnk.Description = description;
            if (File.Exists(icon)) lnk.IconLocation = icon + ",0";
            lnk.Save();
            Marshal.FinalReleaseComObject(lnk);
        }
        finally { Marshal.FinalReleaseComObject(shell); }
        Log($"shortcut: {file} -> {target}");
    }

    internal void RemoveShortcuts()
    {
        var manifest = ReadManifest("shortcuts");
        foreach (var file in manifest) { var p = System.IO.Path.Combine(StartMenuDir, file); if (File.Exists(p)) File.Delete(p); }
        WriteManifest("shortcuts", []);
        if (Directory.Exists(StartMenuDir) && !Directory.EnumerateFileSystemEntries(StartMenuDir).Any()) Directory.Delete(StartMenuDir);
        Log("shortcuts removed");
    }

    private List<string> ReadManifest(string name)
    {
        var path = System.IO.Path.Combine(State, $"installed-{name}.txt");
        return File.Exists(path) ? File.ReadAllLines(path).Where(l => l.Trim().Length > 0).ToList() : [];
    }

    private void WriteManifest(string name, IEnumerable<string> lines)
    {
        Directory.CreateDirectory(State);
        File.WriteAllLines(System.IO.Path.Combine(State, $"installed-{name}.txt"), lines);
    }

    internal void OpenLog() { Directory.CreateDirectory(State); if (!File.Exists(LogFile)) File.WriteAllText(LogFile, "No actions recorded yet." + Environment.NewLine); Process.Start(new ProcessStartInfo(LogFile) { UseShellExecute = true }); }
    internal void OpenFolder(string path) { Directory.CreateDirectory(path); Process.Start(new ProcessStartInfo("explorer.exe", $"\"{path}\"") { UseShellExecute = true }); }
    internal void OpenReleases() => Process.Start(new ProcessStartInfo($"https://github.com/{Repo}/releases/latest") { UseShellExecute = true });
    internal void OpenUrl(string url) => Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });

    internal void StartBundled(string file)
    {
        var path = System.IO.Path.Combine(Payload, file);
        if (!File.Exists(path)) throw new FileNotFoundException($"The package is missing {file}.");
        Process.Start(new ProcessStartInfo(path) { UseShellExecute = true, WorkingDirectory = Payload });
        Log($"Started {file}");
    }

    internal void StartWatchdog()
    {
        var ps1 = System.IO.Path.Combine(Payload, "reshade-watchdog.ps1");
        if (!File.Exists(ps1)) throw new FileNotFoundException("reshade-watchdog.ps1 is missing from this package - reinstall from the full download.");
        Process.Start(new ProcessStartInfo("powershell.exe", $"-NoProfile -ExecutionPolicy Bypass -File \"{ps1}\"") { UseShellExecute = true, WorkingDirectory = Payload, WindowStyle = ProcessWindowStyle.Normal });
        Log("Started ReShade watchdog");
    }

    /// <summary>
    /// The mod and this app are two projects with two release lines, so this asks each repository
    /// about itself. Asking the mod repository about both was why a mod tag (v2.15.51) came back
    /// as an app update, with no app package behind it to install.
    /// </summary>
    internal async Task<UpdateCheck> CheckForUpdatesAsync()
    {
        updateZipUrl = updateZipName = appZipUrl = appZipName = null;
        var lines = new List<string>();
        bool reached = false, modUpdate = false, appUpdate = false, throttled = false;
        string modTag = "", appTag = "";

        // GitHub allows 60 unauthenticated calls an hour per address. On a shared or carrier-grade
        // NAT connection that runs out without anything being wrong, and "check your connection"
        // would send the user hunting for a fault that is not there.
        static bool RateLimited(Exception ex) =>
            ex is HttpRequestException { StatusCode: System.Net.HttpStatusCode.Forbidden or System.Net.HttpStatusCode.TooManyRequests };

        var modCurrent = ReadModVersion().TrimStart('v');
        try
        {
            using var doc = JsonDocument.Parse(await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases/latest"));
            var root = doc.RootElement;
            reached = true;
            modTag = root.GetProperty("tag_name").GetString() ?? "";
            var latest = Parse(modTag);
            // ReadModVersion says "not installed" rather than "", so compare on whether it parses:
            // no readable version means there is nothing installed to be newer than the release.
            var haveMod = Version.TryParse(modCurrent, out var installed);
            modUpdate = latest is not null && (!haveMod || latest > installed);

            // The release also carries the texture, sound and controller packs. Pick the one that
            // is actually the mod, or InstallUpdateAsync unpacks icons and finds no mod files.
            string? otherUrl = null, otherName = null;
            foreach (var (name, url) in Zips(root))
            {
                if (name.Contains("texture", StringComparison.OrdinalIgnoreCase)
                    || name.Contains("sound", StringComparison.OrdinalIgnoreCase)
                    || name.Contains("controller", StringComparison.OrdinalIgnoreCase)
                    || name.Contains("icon", StringComparison.OrdinalIgnoreCase)
                    || name.Contains("portable", StringComparison.OrdinalIgnoreCase)) continue;
                if (name.Contains("mod", StringComparison.OrdinalIgnoreCase)) { updateZipUrl ??= url; updateZipName ??= name; }
                else { otherUrl ??= url; otherName ??= name; }
            }
            updateZipUrl ??= otherUrl; updateZipName ??= otherName;
            lines.Add($"Mod: {(haveMod ? "v" + modCurrent : "not installed")}, latest {modTag}{(modUpdate ? "  -  update available" : "  -  up to date")}");
        }
        catch (Exception ex)
        {
            Log($"mod update check failed: {ex.Message}");
            throttled |= RateLimited(ex);
            lines.Add(RateLimited(ex) ? "Mod: GitHub is rate-limiting this connection." : "Mod: could not reach its releases.");
        }

        var appCurrent = ProductVersion;
        try
        {
            using var doc = JsonDocument.Parse(await http.GetStringAsync($"https://api.github.com/repos/{ToolRepo}/releases/latest"));
            var root = doc.RootElement;
            reached = true;
            appTag = root.GetProperty("tag_name").GetString() ?? "";
            var latest = Parse(appTag);
            appUpdate = latest is not null && Version.TryParse(appCurrent, out var running) && latest > running;
            // The portable zip is the self-update package: it holds the exe this replaces itself with.
            foreach (var (name, url) in Zips(root))
                if (name.Contains("portable", StringComparison.OrdinalIgnoreCase)) { appZipUrl ??= url; appZipName ??= name; }
            lines.Add($"This app: v{appCurrent}, latest {appTag}{(appUpdate ? "  -  update available" : "  -  up to date")}");
        }
        catch (Exception ex)
        {
            Log($"app update check failed: {ex.Message}");
            throttled |= RateLimited(ex);
            lines.Add(RateLimited(ex) ? "This app: GitHub is rate-limiting this connection." : "This app: could not reach its releases.");
        }

        var canMod = modUpdate && updateZipUrl is not null;
        var canApp = appUpdate && appZipUrl is not null;
        // Never offer an update whose package is missing - that is a dialog that can only fail.
        if (modUpdate && !canMod) lines.Add("The mod release has no package attached yet.");
        if (appUpdate && !canApp) lines.Add("The app release has no package attached yet.");

        Log($"update check: modTag={modTag} mod={modCurrent} modUpdate={modUpdate}/{canMod}; appTag={appTag} app={appCurrent} appUpdate={appUpdate}/{canApp}");
        if (!reached) return new(false, throttled
            ? "GitHub is rate-limiting this connection - it allows 60 checks an hour. Try again in a few minutes."
            : "Could not reach GitHub. Check your connection and try again.", "", "", false, false, false, false);
        return new(true, string.Join(Environment.NewLine, lines), modTag, appTag, modUpdate, appUpdate, canMod, canApp);
    }

    private static Version? Parse(string tag) => Version.TryParse(tag.TrimStart('v', 'V'), out var v) ? v : null;

    private static IEnumerable<(string Name, string Url)> Zips(JsonElement release)
    {
        if (!release.TryGetProperty("assets", out var assets)) yield break;
        foreach (var asset in assets.EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            if (!name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)) continue;
            var url = asset.GetProperty("browser_download_url").GetString();
            if (url is not null) yield return (name, url);
        }
    }

    internal async Task InstallUpdateAsync(IProgress<string> progress)
    {
        Guard();
        if (updateZipUrl is null || updateZipName is null) throw new InvalidOperationException("There is no release package to install.");
        var temp = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "qol-series-installer", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(temp);
        var zip = System.IO.Path.Combine(temp, updateZipName);
        progress.Report($"Downloading {updateZipName}");
        await using (var output = File.Create(zip))
            await (await http.GetAsync(updateZipUrl, HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
        progress.Report("Unpacking");
        var outDir = System.IO.Path.Combine(temp, "unpack");
        ZipFile.ExtractToDirectory(zip, outDir);
        var modJson = Directory.EnumerateFiles(outDir, "mod.json", SearchOption.AllDirectories).FirstOrDefault() ?? throw new InvalidOperationException("That download did not contain the mod.");
        var source = System.IO.Path.GetDirectoryName(modJson)!;
        foreach (var file in ModFiles) if (!File.Exists(System.IO.Path.Combine(source, file))) throw new InvalidOperationException($"Incomplete download - missing {file}.");
        Directory.CreateDirectory(ModDir);
        foreach (var file in ModFiles) { progress.Report($"Copying {file}"); File.Copy(System.IO.Path.Combine(source, file), System.IO.Path.Combine(ModDir, file), true); }
        Log($"update installed from {updateZipName}");
    }

    internal async Task InstallAppUpdateAsync(IProgress<string> progress)
    {
        if (appZipUrl is null || appZipName is null) throw new InvalidOperationException("There is no app package to install.");
        var temp = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "qol-app-update", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(temp);
        var zip = System.IO.Path.Combine(temp, appZipName);
        progress.Report($"Downloading {appZipName}");
        await using (var output = File.Create(zip))
            await (await http.GetAsync(appZipUrl, HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
        progress.Report("Unpacking");
        var outDir = System.IO.Path.Combine(temp, "new");
        ZipFile.ExtractToDirectory(zip, outDir);
        var exe = Directory.EnumerateFiles(outDir, "QualityOfLifeSeries.exe", SearchOption.AllDirectories).FirstOrDefault() ?? throw new InvalidOperationException("That download did not contain the app.");
        var source = System.IO.Path.GetDirectoryName(exe)!;
        var appDir = AppContext.BaseDirectory.TrimEnd(System.IO.Path.DirectorySeparatorChar);
        var script = System.IO.Path.Combine(System.IO.Path.GetTempPath(), $"qol-self-update-{Guid.NewGuid():N}.cmd");
        var pid = Environment.ProcessId;

        // Wait for this process to actually exit rather than guessing at two seconds: the exe
        // cannot be overwritten while it is still running, and a flat sleep left the user on the
        // old version with nothing said about it. Robocopy retries, and only a copy that really
        // worked gets to relaunch.
        File.WriteAllText(script, string.Join(Environment.NewLine,
        [
            "@echo off",
            "setlocal",
            $"for /l %%i in (1,1,60) do (",
            $"  tasklist /fi \"PID eq {pid}\" 2>nul | find \"{pid}\" >nul || goto ready",
            "  ping -n 2 127.0.0.1 >nul",
            ")",
            ":ready",
            $"robocopy \"{source}\" \"{appDir}\" /E /R:5 /W:1 /NFL /NDL /NJH /NJS /NP >nul",
            "if errorlevel 8 (",
            $"  echo {DateTime.Now:h:mm:ss tt}  app update FAILED - files could not be replaced>>\"{LogFile}\"",
            ") else (",
            $"  echo {DateTime.Now:h:mm:ss tt}  app update applied>>\"{LogFile}\"",
            ")",
            $"start \"\" \"{System.IO.Path.Combine(appDir, "QualityOfLifeSeries.exe")}\"",
            $"rmdir /s /q \"{temp}\"",
            "(goto) 2>nul & del \"%~f0\""
        ]));
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("cmd.exe", $"/c \"{script}\"") { UseShellExecute = false, CreateNoWindow = true });
        Log($"app update started from {appZipName}, source {source}, pid {pid}");
        await Task.CompletedTask;
    }

    private string? FindPayload(string name)
    {
        var direct = System.IO.Path.Combine(Payload, name); if (Directory.Exists(direct)) return direct;
        var parent = Directory.GetParent(AppContext.BaseDirectory)?.FullName;
        return parent is null ? null : Directory.EnumerateDirectories(parent, name, SearchOption.AllDirectories).FirstOrDefault();
    }

    private async Task<string?> DownloadAssetAsync(string assetName, string folder, IProgress<string> progress)
    {
        progress.Report($"Finding {assetName} on GitHub");
        using var json = JsonDocument.Parse(await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases?per_page=30"));
        foreach (var release in json.RootElement.EnumerateArray()) foreach (var asset in release.GetProperty("assets").EnumerateArray())
        {
            if (!asset.GetProperty("name").GetString()!.Equals(assetName, StringComparison.OrdinalIgnoreCase)) continue;
            var temp = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "qol-series-installer", Guid.NewGuid().ToString("N")); Directory.CreateDirectory(temp);
            var zip = System.IO.Path.Combine(temp, assetName); progress.Report($"Downloading {assetName}");
            await using (var output = File.Create(zip)) await (await http.GetAsync(asset.GetProperty("browser_download_url").GetString(), HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
            var outputDir = System.IO.Path.Combine(temp, folder); ZipFile.ExtractToDirectory(zip, outputDir); var inner = System.IO.Path.Combine(outputDir, folder); return Directory.Exists(inner) ? inner : outputDir;
        }
        return null;
    }

    private void CopyTreeTracked(string source, string dest, string kind, IProgress<string> progress, HashSet<string>? blocked = null)
    {
        Directory.CreateDirectory(dest); var written = new List<string>();
        foreach (var file in Directory.EnumerateFiles(source, "*", SearchOption.AllDirectories))
        {
            if (blocked?.Contains(System.IO.Path.GetFileName(file)) == true) continue;
            var rel = System.IO.Path.GetRelativePath(source, file); var target = System.IO.Path.Combine(dest, rel); Directory.CreateDirectory(System.IO.Path.GetDirectoryName(target)!); File.Copy(file, target, true); written.Add(rel); progress.Report($"Copying {rel}");
        }
        Directory.CreateDirectory(State); File.WriteAllLines(System.IO.Path.Combine(State, $"installed-{kind}.txt"), written);
    }

    private void RemoveTracked(string kind, string dest, IProgress<string> progress)
    {
        var manifest = System.IO.Path.Combine(State, $"installed-{kind}.txt"); if (!File.Exists(manifest)) return;
        foreach (var rel in File.ReadLines(manifest)) { var path = System.IO.Path.GetFullPath(System.IO.Path.Combine(dest, rel)); if (!path.StartsWith(System.IO.Path.GetFullPath(dest), StringComparison.OrdinalIgnoreCase)) continue; if (File.Exists(path)) { File.Delete(path); progress.Report($"Removed {rel}"); } }
        File.Delete(manifest);
    }

    private void BackupReShade(string source, IProgress<string> progress)
    {
        var dest = System.IO.Path.Combine(Backups, "reshade"); if (Directory.Exists(dest)) return; Directory.CreateDirectory(dest);
        foreach (var name in ReshadeFiles) { var f = System.IO.Path.Combine(source, name); if (File.Exists(f)) File.Copy(f, System.IO.Path.Combine(dest, name), true); }
        var shaders = System.IO.Path.Combine(source, "reshade-shaders"); if (Directory.Exists(shaders)) CopyDirectory(shaders, System.IO.Path.Combine(dest, "reshade-shaders"), progress);
    }

    private static void CopyDirectory(string source, string dest, IProgress<string> progress) { foreach (var file in Directory.EnumerateFiles(source, "*", SearchOption.AllDirectories)) { var rel = System.IO.Path.GetRelativePath(source, file); var target = System.IO.Path.Combine(dest, rel); Directory.CreateDirectory(System.IO.Path.GetDirectoryName(target)!); File.Copy(file, target, true); progress.Report($"Copying {rel}"); } }
}