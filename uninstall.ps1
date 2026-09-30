# Remove only unmultitrack. The shared menu, icon and PATH entry serve other tools.
param([string]$ToolsDir = 'C:\dev\tools')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-lib.ps1')
Assert-Windows
Remove-UnmultitrackMenus
foreach ($name in @('unmultitrack.bat', 'unmultitrack')) {
    $path = Join-Path $ToolsDir $name
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'unmultitrack\icons\unmultitrack.ico'
if (Test-Path -LiteralPath $icon) { Remove-Item -LiteralPath $icon -Force }
Write-Host 'Uninstalled unmultitrack. Your recordings and this clone have been kept.' -ForegroundColor Green
