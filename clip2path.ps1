# clip2path.ps1 - Convert a file path to WSL format and copy to clipboard
# Called by ShareX as an action after capturing a screenshot.
# Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "clip2path.ps1" "$input"

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FilePath
)

# Validate file exists
if (-not (Test-Path $FilePath)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("File not found: $FilePath", "clip2path Error", 0, 16)
    exit 1
}

# Only process image files
$imageExts = @('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.tiff')
$ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
if ($ext -notin $imageExts) {
    exit 0
}

# Load config
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"
$pathFormat = "wsl"
$showNotification = $true
$notifySeconds = 3

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($config.pathFormat) { $pathFormat = $config.pathFormat }
        if ($null -ne $config.showNotification) { $showNotification = $config.showNotification }
        if ($config.notificationDurationSeconds) { $notifySeconds = $config.notificationDurationSeconds }
    } catch {}
}

# Convert Windows path to WSL path
function Convert-ToWslPath {
    param([string]$WinPath)
    $p = $WinPath -replace '\\', '/'
    if ($p -match '^([A-Za-z]):(.*)') {
        return "/mnt/$($Matches[1].ToLower())$($Matches[2])"
    }
    return $p
}

# Determine what to copy
$wslPath = Convert-ToWslPath $FilePath
switch ($pathFormat) {
    "windows" { $clipText = $FilePath }
    "both"    { $clipText = "$wslPath`n$FilePath" }
    default   { $clipText = $wslPath }  # "wsl" is default
}

Set-Clipboard -Value $clipText

# Notification
if ($showNotification) {
    $title = "Path Copied"
    $body = $wslPath
    if ($pathFormat -eq "windows") { $body = $FilePath }

    try {
        Import-Module BurntToast -ErrorAction Stop
        New-BurntToastNotification -Text $title, $body -AppLogo $FilePath
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.BalloonTipTitle = $title
        $notify.BalloonTipText = "$wslPath`n$FilePath"
        $notify.Visible = $true
        $notify.ShowBalloonTip($notifySeconds * 1000)
        Start-Sleep -Seconds ($notifySeconds + 1)
        $notify.Dispose()
    }
}
