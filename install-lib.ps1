function Assert-Windows {
    if ($env:OS -ne 'Windows_NT') { throw 'This installer requires Windows. The Python tests can run on other platforms.' }
}

# Keep the Windows and Git Bash entry points from the original installer.
function Write-BatStub($ToolName, $Content, $ToolsDir) {
    Set-Content -LiteralPath (Join-Path $ToolsDir "$ToolName.bat") -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -LiteralPath (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
    Write-Host "  Launchers written to $ToolsDir" -ForegroundColor Green
}

# PNG-in-ICO preserves alpha, unlike conversion through GetHicon().
# Both supplied icons are 16 by 16 pixels.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
    }
}

function Get-UnmultitrackMenuRoots {
    $extensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts', '.flv', '.f4v')
    foreach ($extension in $extensions) {
        "HKCU:\Software\Classes\SystemFileAssociations\$extension\shell\MikesTools"
    }
}

function Set-MikesToolsRoot($rootKey, $icon) {
    # Other standalone tools share this key. Leave their submenu settings alone.
    if (-not (Test-Path $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -Path $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -Path $rootKey -Name 'Icon' -Value $icon
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    New-Item -Path $verbKey -Force | Out-Null
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -Path $verbKey -Name 'MUIVerb' -Value $label
    Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -Path $cmdKey -Name '(Default)' -Value $command
}

function Add-UnmultitrackMenus($filmIcon, $menuIcon, $ToolsDir) {
    $stub = Join-Path $ToolsDir 'unmultitrack.bat'
    $command = 'cmd.exe /k ""{0}" "%1""' -f $stub
    foreach ($root in Get-UnmultitrackMenuRoots) {
        Set-MikesToolsRoot $root $menuIcon
        Add-MikesVerb $root 'Unmultitrack' 'Un-multi-track Video' $filmIcon $command
    }
}

function Remove-UnmultitrackMenus {
    foreach ($root in Get-UnmultitrackMenuRoots) {
        $verb = "$root\shell\Unmultitrack"
        if (Test-Path $verb) { Remove-Item -Path $verb -Recurse -Force }
    }
}
