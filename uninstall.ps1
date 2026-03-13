# uninstall.ps1 - Remove clip2path hotkeys from ShareX and delete installed scripts
# Run: powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1

$sharex = Get-Process -Name "ShareX" -ErrorAction SilentlyContinue
if ($sharex) {
    Write-Host "ERROR: ShareX is running. Please close it first." -ForegroundColor Red
    exit 1
}

# --- Remove ShareX hotkey entries ---
$configPaths = @(
    "$env:USERPROFILE\Documents\ShareX\HotkeysConfig.json",
    "$env:APPDATA\ShareX\HotkeysConfig.json"
)

$hotkeysConfig = $null
foreach ($path in $configPaths) {
    if (Test-Path $path) { $hotkeysConfig = $path; break }
}

if (-not $hotkeysConfig) {
    Write-Host "ShareX config not found. Skipping hotkey removal." -ForegroundColor Yellow
} else {
    Copy-Item $hotkeysConfig "$hotkeysConfig.bak" -Force
    $config = Get-Content $hotkeysConfig -Raw | ConvertFrom-Json

    $before = $config.Hotkeys.Count
    $config.Hotkeys = @($config.Hotkeys | Where-Object {
        $desc = $_.TaskSettings.Description
        -not ($desc -eq "clip2path" -or $desc -like "clip2path:*")
    })
    $removed = $before - $config.Hotkeys.Count

    if ($removed -eq 0) {
        Write-Host "No clip2path hotkey entries found." -ForegroundColor Yellow
    } else {
        $config | ConvertTo-Json -Depth 20 | Set-Content $hotkeysConfig -Encoding UTF8
        Write-Host "Removed $removed clip2path hotkey entries." -ForegroundColor Green
    }
}

# --- Remove installed scripts from %APPDATA%\clip2path\ ---
$installDir = Join-Path $env:APPDATA "clip2path"
if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
    Write-Host "Removed installed scripts: $installDir" -ForegroundColor Green
} else {
    Write-Host "No installed scripts found at $installDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "clip2path uninstalled. Reopen ShareX to apply." -ForegroundColor Green
