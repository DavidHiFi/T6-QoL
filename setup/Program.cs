namespace QolSeriesSetup;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        if (args.Contains("--uninstall", StringComparer.OrdinalIgnoreCase))
        {
            Installer.Uninstall();
            return;
        }
        ApplicationConfiguration.Initialize();
        Application.Run(new SetupForm());
    }
}