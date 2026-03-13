# install.ps1 - Install clip2path scripts and add hotkeys to ShareX
#
# Copies scripts to %APPDATA%\clip2path\ (survives repo deletion).
# Adds TWO hotkey entries (no key assigned by default — user picks in ShareX):
#   clip2path: capture   — Capture region → save → path to clipboard
#   clip2path: clipboard — Clipboard image → save → path to clipboard
#
# Run: powershell.exe -ExecutionPolicy Bypass -File install.ps1
# With keys: powershell.exe -ExecutionPolicy Bypass -File install.ps1 -CaptureHotkey "S, Shift, Alt" -ClipboardHotkey "V, Shift, Alt"

param(
    [string]$CaptureHotkey = "None",
    [string]$ClipboardHotkey = "None"
)

# Check ShareX is not running
$sharex = Get-Process -Name "ShareX" -ErrorAction SilentlyContinue
if ($sharex) {
    Write-Host "ERROR: ShareX is running. Please close it first." -ForegroundColor Red
    Write-Host "ShareX overwrites its config on exit, so changes would be lost."
    exit 1
}

# Find HotkeysConfig.json
$configPaths = @(
    "$env:USERPROFILE\Documents\ShareX\HotkeysConfig.json",
    "$env:APPDATA\ShareX\HotkeysConfig.json"
)

$hotkeysConfig = $null
foreach ($path in $configPaths) {
    if (Test-Path $path) { $hotkeysConfig = $path; break }
}

if (-not $hotkeysConfig) {
    Write-Host "ERROR: ShareX HotkeysConfig.json not found." -ForegroundColor Red
    Write-Host "Is ShareX installed? Run it once to generate config."
    exit 1
}

# --- Install scripts to %APPDATA%\clip2path\ ---
$installDir = Join-Path $env:APPDATA "clip2path"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Copy scripts (always overwrite for upgrades)
Copy-Item (Join-Path $scriptDir "clip2path.ps1") $installDir -Force

# Copy config template only if user config doesn't exist yet
$installedConfig = Join-Path $installDir "config.json"
if (-not (Test-Path $installedConfig)) {
    $exampleConfig = Join-Path $scriptDir "config.example.json"
    if (Test-Path $exampleConfig) {
        Copy-Item $exampleConfig $installedConfig -Force
        Write-Host "Created default config.json" -ForegroundColor Gray
    }
}

Write-Host "Scripts installed to: $installDir" -ForegroundColor Green

# Script path (what ShareX will call)
$captureScript = Join-Path $installDir "clip2path.ps1"

if (-not (Test-Path $captureScript)) {
    Write-Host "ERROR: $captureScript not found after copy." -ForegroundColor Red
    exit 1
}

# --- Update ShareX HotkeysConfig.json ---

# Backup config
Copy-Item $hotkeysConfig "$hotkeysConfig.bak" -Force
Write-Host "Backed up ShareX config." -ForegroundColor Green

# Load config
$config = Get-Content $hotkeysConfig -Raw | ConvertFrom-Json

# Remove any existing clip2path entries
$before = $config.Hotkeys.Count
$config.Hotkeys = @($config.Hotkeys | Where-Object {
    $desc = $_.TaskSettings.Description
    -not ($desc -eq "clip2path" -or $desc -like "clip2path:*")
})
$removed = $before - $config.Hotkeys.Count
if ($removed -gt 0) {
    Write-Host "Removed $removed old clip2path entries." -ForegroundColor Gray
}

# Helper: build a ShareX hotkey entry for capture (uses ShareX's native pipeline)
function New-CaptureHotkeyEntry {
    param([string]$Hotkey)
    return [PSCustomObject]@{
        HotkeyInfo = [PSCustomObject]@{
            Hotkey = $Hotkey
            Win = $false
        }
        TaskSettings = [PSCustomObject]@{
            Description = "clip2path: capture"
            Job = "RectangleRegion"
            UseDefaultAfterCaptureJob = $false
            AfterCaptureJob = "SaveImageToFile, CopyFilePathToClipboard, PerformActions"
            UseDefaultAfterUploadJob = $false
            AfterUploadJob = "None"
            UseDefaultDestinations = $false
            ImageDestination = "FileUploader"
            ImageFileDestination = "None"
            TextDestination = "None"
            TextFileDestination = "None"
            FileDestination = "None"
            URLShortenerDestination = "None"
            URLSharingServiceDestination = "None"
            OverrideFTP = $false
            FTPIndex = 0
            OverrideCustomUploader = $false
            CustomUploaderIndex = 0
            OverrideScreenshotsFolder = $false
            ScreenshotsFolder = ""
            UseDefaultGeneralSettings = $true
            GeneralSettings = $null
            UseDefaultImageSettings = $true
            ImageSettings = $null
            UseDefaultCaptureSettings = $true
            CaptureSettings = $null
            UseDefaultUploadSettings = $true
            UploadSettings = $null
            UseDefaultActions = $false
            ExternalPrograms = @(
                [PSCustomObject]@{
                    IsActive = $true
                    Name = "clip2path"
                    Path = "powershell.exe"
                    Args = "-NoProfile -ExecutionPolicy Bypass -File `"$captureScript`" `"`$input`""
                    OutputExtension = ""
                    Extensions = "png,jpg,jpeg,gif,bmp,webp"
                    HiddenWindow = $true
                    DeleteInputFile = $false
                }
            )
            UseDefaultToolsSettings = $true
            ToolsSettings = $null
            UseDefaultAdvancedSettings = $true
            AdvancedSettings = $null
            WatchFolderEnabled = $false
            WatchFolderList = @()
        }
    }
}

# Helper: build a ShareX hotkey entry for clipboard (script handles everything)
function New-ClipboardHotkeyEntry {
    param([string]$Hotkey)
    return [PSCustomObject]@{
        HotkeyInfo = [PSCustomObject]@{
            Hotkey = $Hotkey
            Win = $false
        }
        TaskSettings = [PSCustomObject]@{
            Description = "clip2path: clipboard"
            Job = "ClipboardUpload"
            UseDefaultAfterCaptureJob = $false
            AfterCaptureJob = "SaveImageToFile, CopyFilePathToClipboard, PerformActions"
            UseDefaultAfterUploadJob = $false
            AfterUploadJob = "None"
            UseDefaultDestinations = $false
            ImageDestination = "FileUploader"
            ImageFileDestination = "None"
            TextDestination = "None"
            TextFileDestination = "None"
            FileDestination = "None"
            URLShortenerDestination = "None"
            URLSharingServiceDestination = "None"
            OverrideFTP = $false
            FTPIndex = 0
            OverrideCustomUploader = $false
            CustomUploaderIndex = 0
            OverrideScreenshotsFolder = $false
            ScreenshotsFolder = ""
            UseDefaultGeneralSettings = $true
            GeneralSettings = $null
            UseDefaultImageSettings = $true
            ImageSettings = $null
            UseDefaultCaptureSettings = $true
            CaptureSettings = $null
            UseDefaultUploadSettings = $true
            UploadSettings = $null
            UseDefaultActions = $false
            ExternalPrograms = @(
                [PSCustomObject]@{
                    IsActive = $true
                    Name = "clip2path"
                    Path = "powershell.exe"
                    Args = "-NoProfile -ExecutionPolicy Bypass -File `"$captureScript`" `"`$input`""
                    OutputExtension = ""
                    Extensions = "png,jpg,jpeg,gif,bmp,webp"
                    HiddenWindow = $true
                    DeleteInputFile = $false
                }
            )
            UseDefaultToolsSettings = $true
            ToolsSettings = $null
            UseDefaultAdvancedSettings = $false
            AdvancedSettings = [PSCustomObject]@{
                ProcessImagesDuringClipboardUpload = $true
            }
            WatchFolderEnabled = $false
            WatchFolderList = @()
        }
    }
}

# Add both hotkeys
$config.Hotkeys += (New-CaptureHotkeyEntry -Hotkey $CaptureHotkey)
$config.Hotkeys += (New-ClipboardHotkeyEntry -Hotkey $ClipboardHotkey)

# Save
$config | ConvertTo-Json -Depth 20 | Set-Content $hotkeysConfig -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS! clip2path hotkeys added to ShareX." -ForegroundColor Green
Write-Host ""
Write-Host "  clip2path: capture   - Capture screen region, save, copy path" -ForegroundColor Cyan
Write-Host "  clip2path: clipboard - Save clipboard image, copy path" -ForegroundColor Cyan
Write-Host ""
if ($CaptureHotkey -eq "None" -or $ClipboardHotkey -eq "None") {
    Write-Host "  ASSIGN HOTKEYS: Open ShareX > Hotkey Settings" -ForegroundColor Yellow
    Write-Host "  Click 'None' next to each entry and press your desired key combo." -ForegroundColor Yellow
    Write-Host ""
}
Write-Host "  Scripts: $installDir"
Write-Host "  Config:  $installedConfig"
Write-Host ""
Write-Host "  You can safely delete this repo folder. Scripts are installed." -ForegroundColor Gray
