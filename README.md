# sharex-clip2path

Screenshot or clipboard image to file path in one keystroke.

Adds dedicated hotkeys to [ShareX](https://getsharex.com/) that save images and copy the file path to your clipboard — in WSL format (`/mnt/c/...`), Windows format, or both.

Your normal ShareX hotkeys are not affected.

## Why

AI coding tools in WSL (Claude Code, OpenCode, Cursor) need **file paths** to reference images. ShareX saves to Windows paths. This bridges the gap automatically.

## Hotkeys

The installer adds two entries to ShareX's Hotkey Settings:

| Entry | What it does |
|-------|-------------|
| **clip2path: capture** | Capture screen region → save → copy path |
| **clip2path: clipboard** | Save clipboard image → copy path |

No keys are assigned by default — you pick your own in ShareX to avoid conflicts.

## Install

### Prerequisites

- Windows 10/11
- [ShareX](https://getsharex.com/)
- PowerShell 5.1+ (built into Windows)

### Setup

```powershell
git clone https://github.com/cybersader/sharex-clip2path.git
```

```powershell
cd sharex-clip2path
```

Close ShareX first (right-click tray icon > Exit), then run the installer:

```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1
```

Open ShareX > Hotkey Settings > assign keys to the new entries.

Optionally pre-assign keys:

```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -CaptureHotkey "S, Shift, Alt" -ClipboardHotkey "V, Shift, Alt"
```

Scripts are copied to `%APPDATA%\clip2path\` — you can delete the repo folder after install.

### Upgrading

Re-run `install.ps1`. Your `config.json` is preserved.

### Uninstall

Close ShareX first, then:

```powershell
powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1
```

Removes all clip2path hotkey entries (including Zipline), the custom uploader, and installed scripts.

## Zipline (Self-Hosted Image Upload)

If you run [Zipline](https://github.com/diced/zipline) on your own server, you can add hotkeys that upload to Zipline and copy the private URL.

### Script Setup

Close ShareX first, then run one of:

Basic (assign keys in ShareX afterward):

```powershell
powershell.exe -ExecutionPolicy Bypass -File install-zipline.ps1 -ZiplineUrl "http://192.168.1.28:3000" -Token "your-upload-token"
```

With pre-assigned keys:

```powershell
powershell.exe -ExecutionPolicy Bypass -File install-zipline.ps1 -ZiplineUrl "http://192.168.1.28:3000" -Token "your-upload-token" -CaptureHotkey "Z, Shift, Alt" -ClipboardHotkey "X, Shift, Alt"
```

Also save locally:

```powershell
powershell.exe -ExecutionPolicy Bypass -File install-zipline.ps1 -ZiplineUrl "http://192.168.1.28:3000" -Token "your-upload-token" -SaveLocally
```

Get your upload token from Zipline's web UI → Settings → Upload Token.

This adds two more hotkeys:

| Entry | What it does |
|-------|-------------|
| **clip2path: zipline capture** | Capture region → upload to Zipline → URL to clipboard |
| **clip2path: zipline clipboard** | Clipboard image → upload to Zipline → URL to clipboard |

### Manual UI Setup (No Script)

Zipline generates a ShareX config file you can import directly:

1. Open Zipline → Settings → Generate Uploaders → ShareX → Download `.sxcu` file
2. Double-click the `.sxcu` file — ShareX imports it automatically
3. ShareX → Destinations → Custom Uploader Settings → verify it's there
4. Create hotkeys manually: Hotkey Settings → Add → set Job + After Capture Tasks → Upload image to host

### When to Use What

| Want | Use |
|------|-----|
| Local file path for AI tools | `clip2path` hotkeys |
| Private URL for sharing | `zipline` hotkeys |
| Both at once | Run both installers, assign different keys |

## Configuration

Edit `%APPDATA%\clip2path\config.json` (created on first install):

```json
{
  "pathFormat": "wsl",
  "showNotification": true,
  "notificationDurationSeconds": 3
}
```

| Setting | Default | Options |
|---------|---------|---------|
| `pathFormat` | `"wsl"` | `"wsl"` → `/mnt/c/...`, `"windows"` → `C:\...`, `"both"` → both on separate lines |
| `showNotification` | `true` | Show toast after converting |
| `notificationDurationSeconds` | `3` | Balloon tip duration |

### Save Location

Screenshots save to ShareX's configured screenshots folder:
- **Global:** ShareX → Application Settings → Paths → Screenshots folder
- **Per-hotkey:** Hotkey Settings → gear icon → Override screenshots folder

### Better Notifications

Install [BurntToast](https://github.com/Windos/BurntToast) for rich toast notifications with image thumbnails:

```powershell
Install-Module -Name BurntToast
```

Without it, a basic Windows balloon tip is used.

## How It Works

**Capture hotkey:**
```
Hotkey → ShareX captures region → saves file → copies path to clipboard
                                              → runs clip2path.ps1 (WSL conversion)
```

**Clipboard hotkey:**
```
Hotkey → ShareX grabs clipboard image → saves file → copies path to clipboard
                                                    → runs clip2path.ps1 (WSL conversion)
```

The clipboard hotkey uses ShareX's `ClipboardUpload` job with `ProcessImagesDuringClipboardUpload` enabled, which makes it respect after-capture tasks (save, copy path, run actions) instead of uploading.

### Path Conversion

```
C:\Users\You\Documents\ShareX\Screenshots\screenshot.png
                         ↓
/mnt/c/Users/You/Documents/ShareX/Screenshots/screenshot.png
```

Pure string manipulation — no WSL process needed.

## Files & Architecture

ShareX can only call external programs — it can't embed custom logic inline. So the path conversion script needs to live on disk somewhere. The installer copies it to `%APPDATA%\clip2path\` (a stable location that survives repo deletion) and tells ShareX to call it from there.

```
Repository (disposable after install):
├── clip2path.ps1          # Path converter script (source copy)
├── config.example.json    # Default configuration template
├── install.ps1            # Local path hotkeys installer
├── install-zipline.ps1    # Zipline upload hotkeys installer
├── uninstall.ps1          # Removes everything
└── README.md

Installed to %APPDATA%\clip2path\ (permanent):
├── clip2path.ps1          # Path converter script (called by ShareX)
└── config.json            # Your settings (preserved across upgrades)

ShareX configs (modified by installers):
├── HotkeysConfig.json     # Hotkey entries (clip2path + zipline)
└── UploadersConfig.json   # Zipline custom uploader definition
```

You only need the repo again to upgrade (re-run `install.ps1`) or uninstall.

## Manual Setup

If you prefer configuring ShareX yourself instead of running the installer:

**Capture hotkey:**
1. Hotkey Settings → Add → set key combo
2. Gear icon → Job: `Capture region`
3. After Capture Tasks: **Save image to file** + **Copy file path to clipboard** + **Perform actions**
4. Actions → Add:
   - Path: `powershell.exe`
   - Argument: `-NoProfile -ExecutionPolicy Bypass -File "%APPDATA%\clip2path\clip2path.ps1" "$input"`
   - Hidden window: checked

**Clipboard hotkey:**
1. Hotkey Settings → Add → set key combo
2. Gear icon → Job: `Clipboard upload`
3. After Capture Tasks: **Save image to file** + **Copy file path to clipboard** + **Perform actions**
4. Task Settings → Advanced → Enable **ProcessImagesDuringClipboardUpload**
5. Actions → Add (same as capture above)

## No PowerShell? (Corporate / Restricted Environments)

If PowerShell is blocked by policy, you have two options:

### Option A: Windows Path Only (No Scripts Needed)

ShareX can copy the Windows file path natively — no scripts required.

1. Hotkey Settings → Add → set key combo
2. Gear icon → Job: `Capture region` (or `Clipboard upload` for clipboard)
3. After Capture Tasks: check **Save image to file** + **Copy file path to clipboard** only
4. For clipboard hotkey: Task Settings → Advanced → Enable **ProcessImagesDuringClipboardUpload**

You'll get `C:\Users\...` in your clipboard. Convert to WSL manually if needed:
```bash
wslpath "C:\Users\You\Documents\ShareX\Screenshots\screenshot.png"
# → /mnt/c/Users/You/Documents/ShareX/Screenshots/screenshot.png
```

### Option B: Batch File Fallback (WSL Conversion Without PowerShell)

Create `clip2path.bat` anywhere on your machine:

```batch
@echo off
set "p=%~1"
set "p=%p:\=/%"
set "d=%p:~0,1%"
:: Lowercase the drive letter
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    if /i "%d%"=="%%a" set "d=%%a"
)
echo /mnt/%d%%p:~2%| clip
```

Then in ShareX: Actions → Add → Path: `clip2path.bat`, Argument: `"$input"`, Hidden window: checked.

Note: the batch file is uglier than PowerShell because batch has no native regex, but it works without any special permissions.

## Troubleshooting

**Path not in clipboard:**
- Check that after-capture tasks include **Copy file path to clipboard** and **Perform actions**
- For clipboard hotkey: verify **ProcessImagesDuringClipboardUpload** is enabled in Task Settings → Advanced

**Clipboard hotkey does nothing:**
- Make sure you copied an image first (Print Screen, snip, etc.)
- Text clipboard content won't trigger it

**Hotkey conflict:**
- Installer defaults to no keys. Assign your own in ShareX → Hotkey Settings

**Install didn't add entries:**
- ShareX must be fully closed (right-click tray → Exit, check Task Manager)
- Re-run `install.ps1` — it cleans up old entries automatically

**Test the script directly:**
```powershell
powershell.exe -NoProfile -File "%APPDATA%\clip2path\clip2path.ps1" "C:\Users\you\Pictures\test.png"
```

## License

MIT
