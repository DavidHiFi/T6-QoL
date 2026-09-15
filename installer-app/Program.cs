namespace QolSeriesInstaller;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        for (var i = 0; i < args.Length; i++)
        {
            if (args[i].Equals("--root", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length) InstallerService.RootOverride = args[++i];
        }
        var service = new InstallerService();
        if (args.Contains("--status-json", StringComparer.OrdinalIgnoreCase))
        {
            Console.WriteLine(System.Text.Json.JsonSerializer.Serialize(service.GetStatus(), new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));
            return;
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new MainForm(service));
    }
}