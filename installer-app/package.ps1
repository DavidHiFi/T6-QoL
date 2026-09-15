# Builds the two release downloads from one binary.
#
#   QualityOfLifeSeriesSetup.exe          double-click installer (Start menu, desktop, uninstaller)
#   QualityOfLifeSeries-portable.zip      unzip and run, installs nothing
#
# They are the same executable. Program.Main looks at its own file name: anything ending in
# "Setup" opens the install window, everything else opens the app. That is why the two downloads
# are the same size and can never disagree about what the app does.
param([string]$OutDir = "$PSScriptRoot\..\dist")

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'QolSeriesInstaller.csproj'
$publish = Join-Path $PSScriptRoot 'bin\Release\net8.0-windows\win-x64\publish'
$modFiles = Join-Path $PSScriptRoot '..\installer\Mod Files'
$readme = Join-Path $PSScriptRoot '..\installer\README.txt'

Write-Host 'Publishing...'
dotnet publish $project -c Release -r win-x64 --self-contained true -v q --nologo
if ($LASTEXITCODE -ne 0) { throw 'publish failed' }

$exe = Join-Path $publish 'QualityOfLifeSeries.exe'
if (-not (Test-Path $exe)) { throw "no exe at $exe" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Get-ChildItem $OutDir -Filter 'QualityOfLifeSeries*' | Remove-Item -Recurse -Force

# 1. The installer.
Copy-Item $exe (Join-Path $OutDir 'QualityOfLifeSeriesSetup.exe') -Force

# 2. The portable zip. Mod Files ships loose here as well as inside the exe, so presets and the
#    .bat launchers are editable without unpacking anything.
$stage = Join-Path $OutDir '_portable'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item $exe $stage -Force
Copy-Item $modFiles $stage -Recurse -Force
if (Test-Path $readme) { Copy-Item $readme $stage -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath (Join-Path $OutDir 'QualityOfLifeSeries-portable.zip') -Force
Remove-Item $stage -Recurse -Force

Get-ChildItem $OutDir -File | ForEach-Object {
    '{0,-40} {1,8:N1} MB' -f $_.Name, ($_.Length / 1MB)
}
