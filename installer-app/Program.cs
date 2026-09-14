namespace QolSeriesInstaller;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
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
