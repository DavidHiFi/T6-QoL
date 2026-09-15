using System.Diagnostics;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace QolSeriesInstaller;

// The support files (icon, launch scripts, ReShade presets) ride inside the exe, so a single
// downloaded file is a complete, working program. They are unpacked next to the exe on first
// run - ReShade needs a real dxgi.dll on disk, not a stream.
internal static class Payload
{
    private const string Resource = "ModFiles.zip";
    internal static string Dir { get; } = Resolve();

    private static bool Complete(string dir) =>
        File.Exists(Path.Combine(dir, "qol_installer.ico")) && File.Exists(Path.Combine(dir, "lan-launch.ps1"));

    private static string Resolve()
    {
        var beside = Path.Combine(AppContext.BaseDirectory, "Mod Files");
        if (Complete(beside)) return beside;
        try { Unpack(beside, false); } catch { }
        if (Complete(beside)) return beside;

        // Read-only location (a network share, Program Files without rights): fall back to the profile.
        var fallback = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "QualityOfLifeSeries", "Mod Files");
        try { Unpack(fallback, false); } catch { }
        return Complete(fallback) ? fallback : beside;
    }

    internal static void Unpack(string dir, bool overwrite)
    {
        using var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(Resource);
        if (stream is null) return;
        Directory.CreateDirectory(dir);
        using var zip = new ZipArchive(stream, ZipArchiveMode.Read);
        foreach (var entry in zip.Entries)
        {
            if (entry.Name.Length == 0) continue;
            var dest = Path.Combine(dir, entry.FullName);
            Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
            // Never clobber an edited ReShade preset on a plain run; a deliberate install may.
            if (overwrite || !File.Exists(dest)) entry.ExtractToFile(dest, true);
        }
    }
}

internal static class Setup
{
    internal const string AppName = "Quality of Life Series";
    internal const string ExeName = "QualityOfLifeSeries.exe";
    private const string ShortcutName = "Quality of Life Series.lnk";
    private const string Key = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\QualityOfLifeSeries";

    internal static string DefaultTarget => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", AppName);
    internal static string StartMenuDir => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Microsoft", "Windows", "Start Menu", "Programs", AppName);
    private static string StartMenuLink => Path.Combine(StartMenuDir, ShortcutName);
    private static string DesktopLink => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), ShortcutName);

    internal static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "2.16.7";

    /// <summary>Where a previous install put the app, or null when it is not installed.</summary>
    internal static string? InstalledAt
    {
        get
        {
            try
            {
                using var key = Registry.CurrentUser.OpenSubKey(Key);
                var at = key?.GetValue("InstallLocation") as string;
                return at is { Length: > 0 } && File.Exists(Path.Combine(at, ExeName)) ? at : null;
            }
            catch { return null; }
        }
    }

    internal static bool HasStartMenu => File.Exists(StartMenuLink);
    internal static bool HasDesktop => File.Exists(DesktopLink);

    /// <summary>True when this very exe is the installed copy, not a portable one.</summary>
    internal static bool RunningInstalled =>
        InstalledAt is { } at && Same(at, AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar));

    private static bool Same(string a, string b) =>
        string.Equals(Path.GetFullPath(a).TrimEnd(Path.DirectorySeparatorChar), Path.GetFullPath(b).TrimEnd(Path.DirectorySeparatorChar), StringComparison.OrdinalIgnoreCase);

    internal static void Install(string target, bool startMenu, bool desktop, IProgress<string> report)
    {
        target = Path.GetFullPath(target.Trim());
        Directory.CreateDirectory(target);
        var exe = Path.Combine(target, ExeName);
        var self = Environment.ProcessPath ?? Application.ExecutablePath;

        if (!Same(self, exe))
        {
            report.Report("Copying the app");
            // An older copy may be running from the target; move it aside rather than failing.
            if (File.Exists(exe))
            {
                try { File.Delete(exe); }
                catch (IOException) { File.Move(exe, exe + $".old-{DateTime.Now:yyyyMMddHHmmss}", true); }
            }
            File.Copy(self, exe, true);
        }

        report.Report("Unpacking the support files");
        Payload.Unpack(Path.Combine(target, "Mod Files"), true);

        report.Report("Creating shortcuts");
        SetShortcut(StartMenuLink, exe, target, startMenu);
        SetShortcut(DesktopLink, exe, target, desktop);

        report.Report("Registering with Windows");
        Register(target);
        report.Report("Installed");
    }

    /// <summary>Creates the shortcut, or removes it - so every switch here has an off position.</summary>
    internal static void SetShortcut(string link, string exe, string workingDir, bool on)
    {
        if (!on)
        {
            if (File.Exists(link)) File.Delete(link);
            var dir = Path.GetDirectoryName(link)!;
            if (Same(dir, StartMenuDir) && Directory.Exists(dir) && !Directory.EnumerateFileSystemEntries(dir).Any()) Directory.Delete(dir);
            return;
        }
        Directory.CreateDirectory(Path.GetDirectoryName(link)!);
        var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell")!)!;
        try
        {
            dynamic lnk = shell.GetType().InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, [link])!;
            lnk.TargetPath = exe;
            lnk.WorkingDirectory = workingDir;
            lnk.Description = "Install, update or remove the Quality of Life mods";
            var icon = Path.Combine(workingDir, "Mod Files", "qol_installer.ico");
            lnk.IconLocation = File.Exists(icon) ? icon + ",0" : exe + ",0";
            lnk.Save();
            Marshal.FinalReleaseComObject(lnk);
        }
        finally { Marshal.FinalReleaseComObject(shell); }
    }

    internal static void SetStartMenu(bool on) => SetShortcut(StartMenuLink, Path.Combine(InstalledAt ?? AppContext.BaseDirectory, ExeName), InstalledAt ?? AppContext.BaseDirectory, on);
    internal static void SetDesktop(bool on) => SetShortcut(DesktopLink, Path.Combine(InstalledAt ?? AppContext.BaseDirectory, ExeName), InstalledAt ?? AppContext.BaseDirectory, on);

    /// <summary>
    /// Keeps the Apps &amp; features entry honest. A self-update replaces the exe in place and knows
    /// nothing about the registry, so the recorded version drifts from the one actually installed.
    /// </summary>
    internal static void RefreshRegistration()
    {
        try
        {
            if (InstalledAt is not { } at) return;
            if (!Same(at, AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar))) return;
            using var key = Registry.CurrentUser.OpenSubKey(Key);
            if (key?.GetValue("DisplayVersion") as string == Version) return;
            Register(at);
        }
        catch { }
    }

    private static void Register(string target)
    {
        using var key = Registry.CurrentUser.CreateSubKey(Key);
        var exe = Path.Combine(target, ExeName);
        var size = 0L;
        try { size = new DirectoryInfo(target).EnumerateFiles("*", SearchOption.AllDirectories).Sum(f => f.Length); } catch { }
        key.SetValue("DisplayName", AppName);
        key.SetValue("DisplayVersion", Version);
        key.SetValue("Publisher", "DavidHiFi");
        key.SetValue("DisplayIcon", exe);
        key.SetValue("InstallLocation", target);
        key.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
        key.SetValue("URLInfoAbout", "https://github.com/DavidHiFi/T6-QoL");
        key.SetValue("UninstallString", $"\"{exe}\" --uninstall");
        key.SetValue("QuietUninstallString", $"\"{exe}\" --uninstall --quiet");
        key.SetValue("EstimatedSize", (int)(size / 1024), RegistryValueKind.DWord);
        key.SetValue("NoModify", 1, RegistryValueKind.DWord);
        key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
    }

    /// <summary>
    /// Removes the shortcuts and the Windows entry now, then has a detached script delete the
    /// folder - this exe is running from inside it and cannot delete itself.
    /// </summary>
    internal static void Uninstall(bool keepSettings)
    {
        var target = (InstalledAt ?? AppContext.BaseDirectory).TrimEnd(Path.DirectorySeparatorChar);
        SetShortcut(StartMenuLink, "", "", false);
        SetShortcut(DesktopLink, "", "", false);
        try { Registry.CurrentUser.DeleteSubKeyTree(Key, false); } catch { }

        if (keepSettings)
        {
            try
            {
                var keep = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "QualityOfLifeSeries");
                Directory.CreateDirectory(keep);
                var from = Path.Combine(target, "settings.json");
                if (File.Exists(from)) File.Copy(from, Path.Combine(keep, "settings.json"), true);
            }
            catch { }
        }

        var script = Path.Combine(Path.GetTempPath(), $"qol-uninstall-{Guid.NewGuid():N}.cmd");
        File.WriteAllText(script, string.Join(Environment.NewLine,
        [
            "@echo off",
            "ping -n 4 127.0.0.1 >nul",
            $"rmdir /s /q \"{target}\"",
            "(goto) 2>nul & del \"%~f0\""
        ]));
        Process.Start(new ProcessStartInfo("cmd.exe", $"/c \"{script}\"") { UseShellExecute = false, CreateNoWindow = true });
    }
}
