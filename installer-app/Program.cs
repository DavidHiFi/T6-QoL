namespace QolSeriesInstaller;

internal static class Program
{
    /// <summary>
    /// One binary, three jobs. Named "...Setup.exe" (or run with --setup) it is the installer;
    /// with --uninstall it is the uninstaller Windows calls from Apps &amp; features; otherwise it
    /// is the app. That is why the portable download and the installer download are the same
    /// size and can never disagree with each other.
    /// </summary>
    [STAThread]
    private static void Main(string[] args)
    {
        for (var i = 0; i < args.Length; i++)
        {
            if (args[i].Equals("--root", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length) InstallerService.RootOverride = args[++i];
        }

        var service = new InstallerService();
        if (Has(args, "--status-json"))
        {
            Console.WriteLine(System.Text.Json.JsonSerializer.Serialize(service.GetStatus(), new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));
            return;
        }

        // Settings transfer from the command line, for scripted backups and for moving a setup
        // between machines without opening the window.
        if (Value(args, "--export-settings") is { } exportTo)
        {
            var summary = SettingsTransfer.Export(exportTo, AppSettings.Load(), service);
            Console.WriteLine($"Exported to {exportTo} (app options + {summary.ModFiles} mod setting file(s))");
            return;
        }
        if (Value(args, "--import-settings") is { } importFrom)
        {
            var imported = SettingsTransfer.Import(importFrom, service, out var restored, Has(args, "--app-only"));
            if (imported is not null) imported.Save();
            Console.WriteLine($"Imported from {importFrom} (app options={imported is not null}, {restored} mod setting file(s))");
            return;
        }

        ApplicationConfiguration.Initialize();

        if (Has(args, "--uninstall"))
        {
            if (Has(args, "--quiet")) { Setup.Uninstall(true); return; }
            Application.Run(new SetupForm(uninstall: true));
            return;
        }

        if (Has(args, "--setup") || (!Has(args, "--portable") && NamedAsSetup()))
        {
            Application.Run(new SetupForm(uninstall: false));
            return;
        }

        Application.Run(new MainForm(service));
    }

    private static bool Has(string[] args, string flag) => args.Contains(flag, StringComparer.OrdinalIgnoreCase);

    private static string? Value(string[] args, string flag)
    {
        for (var i = 0; i < args.Length - 1; i++)
            if (args[i].Equals(flag, StringComparison.OrdinalIgnoreCase)) return args[i + 1];
        return null;
    }

    private static bool NamedAsSetup() =>
        Path.GetFileNameWithoutExtension(Environment.ProcessPath ?? "").EndsWith("Setup", StringComparison.OrdinalIgnoreCase);
}
