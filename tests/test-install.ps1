# Portable helper checks. Registry calls are simulated; no user settings are changed.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../install-lib.ps1')

function Assert-True($condition, $message) {
    if (-not $condition) { throw $message }
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    Write-BatStub 'unmultitrack' "@echo off`r`ncall `"C:\clone with spaces\unmultitrack.bat`" %*" $tempDir
    $stub = Join-Path $tempDir 'unmultitrack.bat'
    Assert-True ((Get-Content $stub -Raw).Contains('"C:\clone with spaces\unmultitrack.bat" %*')) 'Stub must preserve quoted paths and arguments'
    Assert-True (@([System.IO.File]::ReadAllBytes($stub) | Where-Object { $_ -gt 127 }).Count -eq 0) 'Batch stub must be ASCII'
    Assert-True ((Get-Content (Join-Path $tempDir 'unmultitrack') -Raw).Contains('exec "$SCRIPT_DIR/unmultitrack.bat" "$@"')) 'Git Bash wrapper must forward arguments'

    $icoPath = Join-Path $tempDir 'film.ico'
    $pngPath = Join-Path $PSScriptRoot '../icons/film.png'
    ConvertTo-Ico $pngPath $icoPath
    $ico = [System.IO.File]::ReadAllBytes($icoPath)
    $png = [System.IO.File]::ReadAllBytes($pngPath)
    Assert-True ($ico.Length -eq $png.Length + 22) 'ICO must contain the full PNG'
    Assert-True ([BitConverter]::ToUInt16($ico, 2) -eq 1) 'ICO type must be an icon'
    Assert-True ([BitConverter]::ToUInt32($ico, 18) -eq 22) 'PNG offset must follow the ICO header'
    Assert-True ([Convert]::ToBase64String($ico[22..($ico.Length - 1)]) -eq [Convert]::ToBase64String($png)) 'ICO must preserve PNG alpha data'

    # Simulate another tool already owning the submenu and its icon.
    $script:registry = @{}
    function Test-Path($Path) { $script:registry.ContainsKey($Path) }
    function New-Item($Path, [switch]$Force) {
        if (-not $script:registry.ContainsKey($Path)) { $script:registry[$Path] = @{} }
    }
    function Set-ItemProperty($Path, $Name, $Value) { $script:registry[$Path][$Name] = $Value }
    function Remove-Item($Path, [switch]$Recurse, [switch]$Force) {
        foreach ($key in @($script:registry.Keys)) {
            if ($key -eq $Path -or $key.StartsWith($Path + '\')) { $script:registry.Remove($key) }
        }
    }

    $roots = @(Get-UnmultitrackMenuRoots)
    Assert-True ($roots.Count -eq 14) 'All original video extensions must be registered'
    $root = $roots[0]
    $script:registry[$root] = @{ MUIVerb = "Mike's Tools"; Icon = 'existing.ico'; SubCommands = '' }
    $script:registry["$root\shell\OtherTool"] = @{ MUIVerb = 'Keep me' }

    $toolsPath = Join-Path $tempDir 'tools with spaces'
    $expectedCommand = 'cmd.exe /k ""{0}" "%1""' -f (Join-Path $toolsPath 'unmultitrack.bat')
    Add-UnmultitrackMenus 'film.ico' 'wrench.ico' $toolsPath
    Add-UnmultitrackMenus 'film.ico' 'wrench.ico' $toolsPath
    Assert-True ($script:registry[$root].Icon -eq 'existing.ico') 'Installing must preserve the shared submenu icon'
    foreach ($menuRoot in $roots) {
        $command = $script:registry["$menuRoot\shell\Unmultitrack\command"]['(Default)']
        Assert-True ($command -eq $expectedCommand) 'Explorer must quote both the stub and selected file'
    }
    Assert-True ($script:registry[$roots[1]].Icon -eq 'wrench.ico') 'New submenu must use the shared icon'

    Remove-UnmultitrackMenus
    Remove-UnmultitrackMenus
    Assert-True ($script:registry.ContainsKey("$root\shell\OtherTool")) 'Uninstall must preserve other tools'
    Assert-True ($script:registry.ContainsKey($root)) 'Uninstall must preserve the shared submenu'
    foreach ($menuRoot in $roots) {
        Assert-True (-not $script:registry.ContainsKey("$menuRoot\shell\Unmultitrack")) 'Uninstall must remove its own verb'
    }
    Write-Host 'Installer helper checks passed.' -ForegroundColor Green
} finally {
    Microsoft.PowerShell.Management\Remove-Item -LiteralPath $tempDir -Recurse -Force
}
