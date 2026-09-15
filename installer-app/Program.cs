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

    private static bool NamedAsSetup() =>
        Path.GetFileNameWithoutExtension(Environment.ProcessPath ?? "").EndsWith("Setup", StringComparison.OrdinalIgnoreCase);
}
