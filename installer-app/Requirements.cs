using Microsoft.Win32;

namespace QolSeriesInstaller;

internal sealed record Requirement(string Name, string Why, bool Present, string Detail, string? Url);

/// <summary>
/// What the games and ReShade need from Windows, as opposed to what this app needs - the app
/// carries its own .NET runtime inside the exe and needs nothing installed.
///
/// Everything here is checked, never assumed, and nothing is installed without being asked. A
/// requirement that is already satisfied says so once and is not mentioned again.
/// </summary>
internal static class Requirements
{
    private const string VcUrlX86 = "https://aka.ms/vs/17/release/vc_redist.x86.exe";
    private const string VcUrlX64 = "https://aka.ms/vs/17/release/vc_redist.x64.exe";
    private const string DirectXUrl = "https://www.microsoft.com/download/details.aspx?id=35";
    private const string PlutoniumUrl = "https://plutonium.pw/download";

    internal static IReadOnlyList<Requirement> Check(InstallerService service)
    {
        var list = new List<Requirement>
        {
            Plutonium(service),
            VisualCpp("x86", "The Call of Duty games are 32-bit, and ReShade hooks them in-process.", VcUrlX86),
            VisualCpp("x64", "Used by 64-bit tools that sit alongside them.", VcUrlX64),
            DirectX()
        };
        return list;
    }

    internal static int Missing(InstallerService service) => Check(service).Count(r => !r.Present);

    private static Requirement Plutonium(InstallerService service)
    {
        var found = Directory.Exists(service.Pluto);
        return new("Plutonium", "The launcher every one of these games runs through.", found,
            found ? service.Pluto : "not found - run it once so it creates its folder", PlutoniumUrl);
    }

    /// <summary>
    /// The 2015-2022 runtimes share one registry entry - 14.x covers 2015, 2017, 2019 and 2022,
    /// so a single check answers for all of them.
    /// </summary>
    private static Requirement VisualCpp(string arch, string why, string url)
    {
        var name = $"Visual C++ 2015-2022 Redistributable ({arch})";
        try
        {
            using var key = Registry.LocalMachine.OpenSubKey($@"SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\{arch}")
                         ?? Registry.LocalMachine.OpenSubKey($@"SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\{arch}");
            var installed = key?.GetValue("Installed") as int? == 1;
            var version = key?.GetValue("Version") as string ?? "";
            return new(name, why, installed, installed ? version.TrimStart('v') : "not installed", url);
        }
        catch { return new(name, why, false, "could not be read", url); }
    }

    private static Requirement DirectX()
    {
        // d3dx9_43 is the last D3DX9 release and the one these games load; it ships only in the
        // end-user runtime, never with Windows itself.
        var system = Environment.GetFolderPath(Environment.SpecialFolder.System);
        var wow = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "SysWOW64");
        var present = File.Exists(Path.Combine(wow, "d3dx9_43.dll")) || File.Exists(Path.Combine(system, "d3dx9_43.dll"));
        return new("DirectX 9 end-user runtime", "World at War and Black Ops load D3DX9, which Windows does not ship.",
            present, present ? "d3dx9_43.dll found" : "d3dx9_43.dll not found", DirectXUrl);
    }
}
