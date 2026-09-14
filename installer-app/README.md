# Portable installer app

`QualityOfLifeSeries.exe` replaces the console installer on Windows. It is a native WinForms app published as one self-contained x64 executable. It does not invoke PowerShell.

Build the release file:

```powershell
dotnet publish .\installer-app\QolSeriesInstaller.csproj -c Release -r win-x64 --self-contained true -o .\installer
```

Keep `Mod Files` beside the executable. Large optional packs remain separate and the app can fetch the texture and sound archives from GitHub releases.

For an automated read-only check, run `QualityOfLifeSeries.exe --status-json` from a console.
