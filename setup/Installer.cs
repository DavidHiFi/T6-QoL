using System.Diagnostics;
using System.IO.Compression;
using System.Runtime.InteropServices;
using System.Text.Json;
using Microsoft.Win32;

namespace QolSeriesSetup;

internal static class Installer
{
    internal const string AppName = "Quality of Life Series";
    internal const string ExeName = "QualityOfLifeSeries.exe";
    internal const string PortableZip = "QualityOfLifeSeries-portable.zip";
    internal const string Repo = "DavidHiFi/T6-QoL";
    internal const string UninstallKey = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\QualityOfLifeSeries";
    internal const string ShortcutName = "Quality of Life Series.lnk";

    internal static string DefaultTarget => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", AppName);
    internal static string StartMenuDir => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Microsoft", "Windows", "Start Menu", "Programs", AppName);

    internal static string? FindPayloadZip()
    {
        var beside = Directory.EnumerateFiles(AppContext.BaseDirectory, "*.zip").ToList();
        var parent = Directory.GetParent(AppContext.BaseDirectory)?.FullName;
        if (parent is not null) beside.AddRange(Directory.EnumerateFiles(parent, "*.zip"));
        return beside.FirstOrDefault(z => Path.GetFileName(z).Contains("portable", StringComparison.OrdinalIgnoreCase))
            ?? beside.FirstOrDefault(z => Path.GetFileName(z).Contains("qol", StringComparison.OrdinalIgnoreCase) || Path.GetFileName(z).Contains("quality", StringComparison.OrdinalIgnoreCase))
            ?? beside.FirstOrDefault(z => !Path.GetFileName(z).Contains("texture", StringComparison.OrdinalIgnoreCase) && !Path.GetFileName(z).Contains("sound", StringComparison.OrdinalIgnoreCase));
    }

    internal static async Task<string> DownloadPayloadAsync(IProgress<string> progress)
    {
        var temp = Path.Combine(Path.GetTempPath(), "qol-setup", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(temp);
        using var http = new HttpClient();
        http.DefaultRequestHeaders.UserAgent.ParseAdd("QolSeriesSetup/1.0");
        progress.Report("Asking GitHub for the latest release");
        using var json = JsonDocument.Parse(await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases/latest"));
        string? url = null; string? name = null;
        if (json.RootElement.TryGetProperty("assets", out var assets))
        {
            foreach (var asset in assets.EnumerateArray())
            {
                var assetName = asset.GetProperty("name").GetString() ?? "";
                if (!assetName.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)) continue;
                if (assetName.Contains("portable", StringComparison.OrdinalIgnoreCase)) { url = asset.GetProperty("browser_download_url").GetString(); name = assetName; break; }
                if (url is null && !assetName.Contains("texture", StringComparison.OrdinalIgnoreCase) && !assetName.Contains("sound", StringComparison.OrdinalIgnoreCase)) { url = asset.GetProperty("browser_download_url").GetString(); name = assetName; }
            }
        }
        if (url is null || name is null) throw new InvalidOperationException("The latest release has no app package attached.");
        var zip = Path.Combine(temp, name);
        progress.Report($"Downloading {name}");
        await using (var output = File.Create(zip))
            await (await http.GetAsync(url, HttpCompletionOption.ResponseHeadersRead)).Content.CopyToAsync(output);
        return zip;
    }

    internal static string ExtractApp(string zip)
    {
        var outDir = Path.Combine(Path.GetTempPath(), "qol-setup", Guid.NewGuid().ToString("N"));
        ZipFile.ExtractToDirectory(zip, outDir);
        var exe = Directory.EnumerateFiles(outDir, ExeName, SearchOption.AllDirectories).FirstOrDefault()
            ?? throw new InvalidOperationException("That package did not contain the app.");
        return Path.GetDirectoryName(exe)!;
    }

    internal static void InstallFiles(string source, string target, IProgress<string> progress)
    {
        Directory.CreateDirectory(target);
        foreach (var file in Directory.EnumerateFiles(source, "*", SearchOption.AllDirectories))
        {
            var rel = Path.GetRelativePath(source, file);
            var dest = Path.Combine(target, rel);
            Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
            File.Copy(file, dest, true);
            progress.Report($"Copying {rel}");
        }
    }

    internal static void CreateShortcut(string target, bool on)
    {
        if (!on) { RemoveShortcut(); return; }
        Directory.CreateDirectory(StartMenuDir);
        var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!)!;
        try
        {
            dynamic lnk = shell.GetType().InvokeMember("CreateShortcut", System.Reflection.BindingFlags.InvokeMethod, null, shell, [Path.Combine(StartMenuDir, ShortcutName)])!;
            lnk.TargetPath = Path.Combine(target, ExeName);
            lnk.WorkingDirectory = target;
            lnk.Description = "Install, update or remove the Quality of Life mods";
            var icon = Path.Combine(target, "Mod Files", "qol_installer.ico");
            if (File.Exists(icon)) lnk.IconLocation = icon + ",0";
            lnk.Save();
            Marshal.FinalReleaseComObject(lnk);
        }
        finally { Marshal.FinalReleaseComObject(shell); }
    }

    internal static void RemoveShortcut()
    {
        var lnk = Path.Combine(StartMenuDir, ShortcutName);
        if (File.Exists(lnk)) File.Delete(lnk);
        if (Directory.Exists(StartMenuDir) && !Directory.EnumerateFileSystemEntries(StartMenuDir).Any()) Directory.Delete(StartMenuDir);
    }

    internal static void RegisterUninstall(string target, string version)
    {
        using var key = Registry.CurrentUser.CreateSubKey(UninstallKey);
        key.SetValue("DisplayName", AppName);
        key.SetValue("DisplayVersion", version);
        key.SetValue("Publisher", "DavidHiFi");
        key.SetValue("DisplayIcon", Path.Combine(target, ExeName));
        key.SetValue("InstallLocation", target);
        key.SetValue("UninstallString", $"\"{Path.Combine(target, "Uninstall.exe")}\" --uninstall");
        key.SetValue("QuietUninstallString", $"\"{Path.Combine(target, "Uninstall.exe")}\" --uninstall");
        key.SetValue("NoModify", 1);
        key.SetValue("NoRepair", 1);
    }

    internal static void Uninstall()
    {
        var target = AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
        RemoveShortcut();
        try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false); } catch { }
        var cleanup = Path.Combine(Path.GetTempPath(), "qol-uninstall.cmd");
        File.WriteAllText(cleanup, string.Join(Environment.NewLine,
        [
            "@echo off",
            "timeout /t 2 /nobreak >nul",
            $"rmdir /s /q \"{target}\"",
            "del \"%~f0\"",
        ]));
        Process.Start(new ProcessStartInfo("cmd.exe", $"/c \"{cleanup}\"") { UseShellExecute = true, WindowStyle = ProcessWindowStyle.Hidden });
    }
}