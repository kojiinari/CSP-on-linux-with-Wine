# Clip Studio Paint 4.1.0 — Linux Setup (Wine + Winetricks)

A script to install **Clip Studio Paint 4.1.0** on Linux using plain Wine and Winetricks, no Bottles required.

---

## Requirements

- Wine 10.0 or later
- Winetricks
- A 64-bit Linux system
- Vulkan-capable GPU (for DXVK)

Install on your distro:

| Distro | Command |
|---|---|
| Arch / Manjaro | `sudo pacman -S wine winetricks` |
| Ubuntu / Debian | `sudo apt install wine winetricks` |
| Fedora | `sudo dnf install wine winetricks` |

---

## Step 1 — Download the installers

Download all three files and place them in the **same folder as `setup-csp-wine.sh`**:

| File | Version | Link |
|---|---|---|
| `MicrosoftEdgeSetup.exe` | any | https://www.microsoft.com/en-us/edge/download |
| `MicrosoftEdgeWebView2RuntimeInstallerX64.exe` | **135.0.3179.85** | https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/2885f0d8-0c6e-4ea5-ad6c-d9f636c58619/MicrosoftEdgeWebView2RuntimeInstallerX64.exe |
| `CSP_410w_setup.exe` | **4.1.0** | https://vd.clipstudio.net/clipstudio/csp/win/CSP_410w_setup.exe |

> **Why these specific versions?**
> WebView2 **135.0.3179.85** combined with Windows 7 compatibility mode is what fixes the launcher's asset store. Other versions may cause a black loading screen that never resolves.

---

## Step 2 — Run the setup script

```bash
chmod +x setup-csp-wine.sh
./setup-csp-wine.sh
```

The script will:

1. Create a Wine prefix at `~/.wine-csp` (win64)
2. Install corefonts, vcrun2022, dotnet48, and DXVK
3. Set global Windows version to **Windows 10**
4. Add a `concrt140` DLL override (native) for crash stability
5. Install Microsoft Edge *(expected to crash after opening — this is fine)*
6. Install WebView2 and set it to **Windows 7** compatibility *(fixes asset store)*
7. Install Clip Studio Paint and set it to **Windows 8.1** compatibility
8. Create a `.desktop` shortcut in your app launcher

---

## Step 3 — First launch

Launch CSP from your app launcher, or run manually:

```bash
WINEPREFIX="$HOME/.wine-csp" WINEESYNC=1 WINEFSYNC=1 wine \
  "$HOME/.wine-csp/drive_c/Program Files/CELSYS/CLIP STUDIO 1.5/CLIP STUDIO PAINT/CLIPStudioPaint.exe"
```

On first launch, allow the app to download all necessary materials. The launcher home screen may show a black loading screen briefly — this is normal.

---

## Tablet Pen Pressure

To enable pen pressure for your drawing tablet:

> File → **Preferences** → Tablet → **Use mouse mode in tablet driver settings**

---

## UI Scaling (HiDPI / Fractional Scaling)

If everything looks tiny, Wine doesn't detect fractional display scaling automatically. Fix it by setting the DPI manually in the Wine registry:

```bash
WINEPREFIX="$HOME/.wine-csp" winecfg
```

Go to **Graphics** tab and set the DPI to match your display (use an app like [Dippi](https://flathub.org/apps/de.haeckerfelix.Dippi) to calculate it from your screen size and resolution).

Then force-restart Wine:

```bash
WINEPREFIX="$HOME/.wine-csp" wineserver -k
```

---

## Esync / Fsync

This fixes issues with the menus and panels taking forever to open.
Enabled by default in the desktop shortcut created by the script (`WINEESYNC=1`).
Raise your file descriptor limit by adding this to `/etc/security/limits.conf`:

```
yourusername hard nofile 524288
yourusername soft nofile 524288
```

Log out and back in for it to take effect.

---

## Known Issues

Menus will appear as a seperate window, and you need to switch to them from the taskbar to be able to see them. 
This is only tested to work with CSP 4.1. YMMV on other versions.

---

## Uninstall

To remove the Wine prefix entirely:

```bash
rm -rf ~/.wine-csp
rm ~/.local/share/applications/clipstudiopaint.desktop
```
