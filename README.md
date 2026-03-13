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
cd sharex-clip2path

# Close ShareX first (right-click tray icon > Exit)

# Run installer
powershell.exe -ExecutionPolicy Bypass -File install.ps1

# Open ShareX > Hotkey Settings > assign keys to the new entries
```

Optionally pre-assign keys:
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1 -CaptureHotkey "S, Shift, Alt" -ClipboardHotkey "V, Shift, Alt"
```

Scripts are copied to `%APPDATA%\clip2path\` — you can delete the repo folder after install.

### Upgrading

Re-run `install.ps1`. Your `config.json` is preserved.

### Uninstall

```powershell
# Close ShareX first
powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1
```

Removes ShareX hotkey entries and installed scripts from `%APPDATA%\clip2path\`.

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

## Files

```
Repository:
├── clip2path.ps1          # Path converter (ShareX action)
├── config.example.json    # Default configuration
├── install.ps1            # Installer
├── uninstall.ps1          # Uninstaller
└── README.md

Installed to %APPDATA%\clip2path\:
├── clip2path.ps1
└── config.json
```

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
