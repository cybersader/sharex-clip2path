# install-zipline.ps1 - Add Zipline upload hotkeys to ShareX
#
# Adds a custom uploader definition and TWO hotkey entries:
#   clip2path: zipline capture   — Capture region → upload to Zipline → URL to clipboard
#   clip2path: zipline clipboard — Clipboard image → upload to Zipline → URL to clipboard
#
# Run: powershell.exe -ExecutionPolicy Bypass -File install-zipline.ps1 -ZiplineUrl "https://your-zipline" -Token "your-token"

param(
    [string]$ZiplineUrl,
    [string]$Token,
    [string]$CaptureHotkey = "None",
    [string]$ClipboardHotkey = "None",
    [switch]$SaveLocally
)

# Check ShareX is not running (do this before reading config)
$sharex = Get-Process -Name "ShareX" -ErrorAction SilentlyContinue
if ($sharex) {
    Write-Host "ERROR: ShareX is running. Please close it first." -ForegroundColor Red
    Write-Host "ShareX overwrites its config on exit, so changes would be lost."
    exit 1
}

# --- Find ShareX config files ---
$searchPaths = @(
    "$env:USERPROFILE\Documents\ShareX",
    "$env:APPDATA\ShareX"
)

$sharexDir = $null
foreach ($path in $searchPaths) {
    if (Test-Path (Join-Path $path "HotkeysConfig.json")) {
        $sharexDir = $path
        break
    }
}

if (-not $sharexDir) {
    Write-Host "ERROR: ShareX config directory not found." -ForegroundColor Red
    Write-Host "Is ShareX installed? Run it once to generate config."
    exit 1
}

$hotkeysConfigPath = Join-Path $sharexDir "HotkeysConfig.json"
$uploadersConfigPath = Join-Path $sharexDir "UploadersConfig.json"

if (-not (Test-Path $uploadersConfigPath)) {
    Write-Host "ERROR: UploadersConfig.json not found at $uploadersConfigPath" -ForegroundColor Red
    exit 1
}

# --- Try to reuse existing config if URL/Token not provided ---
$uploadersConfig = Get-Content $uploadersConfigPath -Raw | ConvertFrom-Json
$existingUploader = $uploadersConfig.CustomUploadersList | Where-Object { $_.Name -eq "clip2path-zipline" } | Select-Object -First 1

if ($existingUploader) {
    if (-not $ZiplineUrl) {
        # Extract base URL from existing RequestURL (strip /api/upload)
        $existingUrl = $existingUploader.RequestURL -replace '/api/upload$', ''
        $ZiplineUrl = $existingUrl
        Write-Host "Reusing existing Zipline URL: $ZiplineUrl" -ForegroundColor Gray
    }
    if (-not $Token) {
        $Token = $existingUploader.Headers.Authorization
        Write-Host "Reusing existing Zipline token." -ForegroundColor Gray
    }
}

# Prompt if still missing
if (-not $ZiplineUrl) {
    $ZiplineUrl = Read-Host "Zipline URL (e.g., http://img.home)"
}
if (-not $Token) {
    $Token = Read-Host "Zipline upload token"
}

if (-not $ZiplineUrl -or -not $Token) {
    Write-Host "ERROR: Zipline URL and Token are required." -ForegroundColor Red
    exit 1
}

# Normalize URL — strip paths like /dashboard down to scheme://host:port
$uri = [System.Uri]$ZiplineUrl
$ZiplineUrl = "$($uri.Scheme)://$($uri.Authority)"

# --- Backup configs ---
Copy-Item $hotkeysConfigPath "$hotkeysConfigPath.bak" -Force
Copy-Item $uploadersConfigPath "$uploadersConfigPath.bak" -Force
Write-Host "Backed up ShareX configs." -ForegroundColor Green

# --- Add custom uploader to UploadersConfig.json ---
# (already loaded above)

# Remove existing clip2path-zipline uploader if present
$uploaderName = "clip2path-zipline"
$existingUploaders = @($uploadersConfig.CustomUploadersList | Where-Object { $_.Name -ne $uploaderName })
$uploadersConfig.CustomUploadersList = $existingUploaders

# Create new custom uploader entry
$newUploader = [PSCustomObject]@{
    Name = $uploaderName
    DestinationType = "ImageUploader, FileUploader"
    RequestMethod = "POST"
    RequestURL = "$ZiplineUrl/api/upload"
    Headers = [PSCustomObject]@{
        Authorization = $Token
    }
    Body = "MultipartFormData"
    FileFormName = "file"
    URL = "{json:files[0].url}"
    ThumbnailURL = "{json:files[0].url}"
    ErrorMessage = "{json:error}"
}

# Add to list
$uploadersConfig.CustomUploadersList = @($uploadersConfig.CustomUploadersList) + @($newUploader)

# Set as selected custom image uploader (index of our entry)
$uploaderIndex = $uploadersConfig.CustomUploadersList.Count - 1
$uploadersConfig.CustomImageUploaderSelected = $uploaderIndex
$uploadersConfig.CustomFileUploaderSelected = $uploaderIndex

# Save uploaders config
$uploadersConfig | ConvertTo-Json -Depth 20 | Set-Content $uploadersConfigPath -Encoding UTF8
Write-Host "Added Zipline custom uploader." -ForegroundColor Green

# --- Add hotkeys to HotkeysConfig.json ---
$hotkeysConfig = Get-Content $hotkeysConfigPath -Raw | ConvertFrom-Json

# Remove existing zipline hotkeys
$before = $hotkeysConfig.Hotkeys.Count
$hotkeysConfig.Hotkeys = @($hotkeysConfig.Hotkeys | Where-Object {
    $desc = $_.TaskSettings.Description
    -not ($desc -like "clip2path: zipline*")
})
$removed = $before - $hotkeysConfig.Hotkeys.Count
if ($removed -gt 0) {
    Write-Host "Removed $removed old Zipline hotkey entries." -ForegroundColor Gray
}

# Determine AfterCaptureJob flags
$afterCapture = "UploadImageToHost"
if ($SaveLocally) {
    $afterCapture = "SaveImageToFile, UploadImageToHost"
}

# Capture hotkey
$captureEntry = [PSCustomObject]@{
    HotkeyInfo = [PSCustomObject]@{
        Hotkey = $CaptureHotkey
        Win = $false
    }
    TaskSettings = [PSCustomObject]@{
        Description = "clip2path: zipline capture"
        Job = "RectangleRegion"
        UseDefaultAfterCaptureJob = $false
        AfterCaptureJob = $afterCapture
        UseDefaultAfterUploadJob = $false
        AfterUploadJob = "CopyURLToClipboard"
        UseDefaultDestinations = $false
        ImageDestination = "CustomImageUploader"
        ImageFileDestination = "None"
        TextDestination = "None"
        TextFileDestination = "None"
        FileDestination = "CustomFileUploader"
        URLShortenerDestination = "None"
        URLSharingServiceDestination = "None"
        OverrideFTP = $false
        FTPIndex = 0
        OverrideCustomUploader = $true
        CustomUploaderIndex = $uploaderIndex
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
        UseDefaultActions = $true
        ExternalPrograms = @()
        UseDefaultToolsSettings = $true
        ToolsSettings = $null
        UseDefaultAdvancedSettings = $true
        AdvancedSettings = $null
        WatchFolderEnabled = $false
        WatchFolderList = @()
    }
}

# Clipboard hotkey
$clipboardEntry = [PSCustomObject]@{
    HotkeyInfo = [PSCustomObject]@{
        Hotkey = $ClipboardHotkey
        Win = $false
    }
    TaskSettings = [PSCustomObject]@{
        Description = "clip2path: zipline clipboard"
        Job = "ClipboardUpload"
        UseDefaultAfterCaptureJob = $false
        AfterCaptureJob = $afterCapture
        UseDefaultAfterUploadJob = $false
        AfterUploadJob = "CopyURLToClipboard"
        UseDefaultDestinations = $false
        ImageDestination = "CustomImageUploader"
        ImageFileDestination = "None"
        TextDestination = "None"
        TextFileDestination = "None"
        FileDestination = "CustomFileUploader"
        URLShortenerDestination = "None"
        URLSharingServiceDestination = "None"
        OverrideFTP = $false
        FTPIndex = 0
        OverrideCustomUploader = $true
        CustomUploaderIndex = $uploaderIndex
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
        UseDefaultActions = $true
        ExternalPrograms = @()
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

$hotkeysConfig.Hotkeys += $captureEntry
$hotkeysConfig.Hotkeys += $clipboardEntry

# Save hotkeys config
$hotkeysConfig | ConvertTo-Json -Depth 20 | Set-Content $hotkeysConfigPath -Encoding UTF8

Write-Host ""
Write-Host "SUCCESS! Zipline hotkeys added to ShareX." -ForegroundColor Green
Write-Host ""
Write-Host "  clip2path: zipline capture   - Capture region, upload to Zipline" -ForegroundColor Cyan
Write-Host "  clip2path: zipline clipboard - Clipboard image, upload to Zipline" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Zipline URL: $ZiplineUrl" -ForegroundColor Gray
if ($SaveLocally) {
    Write-Host "  Also saving locally to ShareX screenshots folder." -ForegroundColor Gray
}
Write-Host ""
if ($CaptureHotkey -eq "None" -or $ClipboardHotkey -eq "None") {
    Write-Host "  ASSIGN HOTKEYS: Open ShareX > Hotkey Settings" -ForegroundColor Yellow
    Write-Host "  Click 'None' next to each Zipline entry and press your desired key combo." -ForegroundColor Yellow
    Write-Host ""
}
