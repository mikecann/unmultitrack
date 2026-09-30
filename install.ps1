# Install from this clone. No administrator access or API keys are needed.
param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-lib.ps1')
Assert-Windows

New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

$machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$onPath = (($machinePath -split ';') + ($userPath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        $newUserPath = ("$userPath".TrimEnd(';') + ";$ToolsDir").TrimStart(';')
        [System.Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
        $env:PATH += ";$ToolsDir"
        Write-Host 'Open a new terminal to pick up the PATH change.' -ForegroundColor Yellow
    }
}

Write-BatStub 'unmultitrack' @"
@echo off
setlocal
set "EXEDIR=%~dp0"
call "$PSScriptRoot\unmultitrack.bat" %*
"@ $ToolsDir

$iconsDir = Join-Path $env:LOCALAPPDATA 'unmultitrack\icons'
$sharedIconsDir = Join-Path $env:LOCALAPPDATA 'MikesTools\icons'
New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
New-Item -ItemType Directory -Path $sharedIconsDir -Force | Out-Null
$filmIcon = Join-Path $iconsDir 'unmultitrack.ico'
$menuIcon = Join-Path $sharedIconsDir 'mikes-tools.ico'
ConvertTo-Ico (Join-Path $PSScriptRoot 'icons/film.png') $filmIcon
if (-not (Test-Path $menuIcon)) {
    ConvertTo-Ico (Join-Path $PSScriptRoot 'icons/wrench.png') $menuIcon
}
Add-UnmultitrackMenus $filmIcon $menuIcon $ToolsDir

if (-not $SkipDeps) { & (Join-Path $PSScriptRoot 'deps.ps1') -ToolsDir $ToolsDir }
Write-Host "Installed unmultitrack. Right-click a video and choose Mike's Tools > Un-multi-track Video." -ForegroundColor Green
