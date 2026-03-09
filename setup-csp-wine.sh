#!/usr/bin/env bash
# =============================================================================
# Clip Studio Paint 4.1.0 — Wine Setup Script
# =============================================================================
# This script sets up a Wine prefix for Clip Studio Paint 4.1.0.
# You must download the following files BEFORE running this script:
#
#   1. MicrosoftEdgeSetup.exe
#      https://www.microsoft.com/en-us/edge/download
#
#   2. MicrosoftEdgeWebView2RuntimeInstallerX64.exe  (version 135.0.3179.85)
#      https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/76eb3dc4-7851-45b7-a392-460523b0e2bb/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
#
#   3. CSP_410w_setup.exe  (version 4.1.0)
#      https://vd.clipstudio.net/clipcontent/paint/app/410/CSP_410w_setup.exe
#
# Place all three files in the same directory as this script, then run:
#   chmod +x setup-csp-wine.sh && ./setup-csp-wine.sh
# =============================================================================

set -e

WINEPREFIX="${WINEPREFIX:-$HOME/.wine-csp}"
WINEARCH=win64
CSP_EXE="$WINEPREFIX/drive_c/Program Files/CELSYS/CLIP STUDIO 1.5/CLIP STUDIO PAINT/CLIPStudioPaint.exe"
WEBVIEW2_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application/135.0.3179.85/msedgewebview2.exe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${CYAN}[CSP]${NC} $1"; }
ok()     { echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =============================================================================
# Preflight checks
# =============================================================================

log "Checking dependencies..."
command -v wine      >/dev/null 2>&1 || error "wine is not installed. Install it with your package manager."
command -v winetricks >/dev/null 2>&1 || error "winetricks is not installed. Install it with your package manager."
ok "wine $(wine --version) and winetricks found."

log "Checking for installer files in: $SCRIPT_DIR"
MISSING=0
for f in "MicrosoftEdgeSetup.exe" "MicrosoftEdgeWebView2RuntimeInstallerX64.exe" "CSP_410w_setup.exe"; do
    if [[ ! -f "$SCRIPT_DIR/$f" ]]; then
        warn "Missing: $f"
        MISSING=$((MISSING + 1))
    else
        ok "Found: $f"
    fi
done
[[ $MISSING -gt 0 ]] && error "$MISSING installer(s) missing. See the header of this script for download links."

# =============================================================================
# Create Wine prefix
# =============================================================================

log "Creating Wine prefix at $WINEPREFIX (win64)..."
export WINEPREFIX WINEARCH
WINEDEBUG=-all wineboot --init
ok "Prefix created."

# =============================================================================
# Install dependencies via Winetricks
# =============================================================================

log "Installing corefonts, vcrun2022, dotnet48..."
WINEDEBUG=-all winetricks -q corefonts vcrun2022 dotnet48
ok "Dependencies installed."

log "Installing DXVK..."
WINEDEBUG=-all winetricks -q dxvk
ok "DXVK installed."

# =============================================================================
# Set global Windows version to Windows 10
# =============================================================================

log "Setting global Windows version to Windows 10..."
wine reg add "HKCU\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f >/dev/null 2>&1
ok "Global Windows version set to Windows 10."

# =============================================================================
# Add concrt140 DLL override (native) for stability
# =============================================================================

log "Adding concrt140 DLL override (native,builtin)..."
wine reg add "HKCU\\Software\\Wine\\DllOverrides" /v "concrt140" /t REG_SZ /d "native,builtin" /f
ok "concrt140 override added."

# =============================================================================
# Install Microsoft Edge
# =============================================================================

log "Installing Microsoft Edge... (Edge may crash after opening — this is expected)"
# Disable winemenubuilder to prevent Edge from hijacking system default browser
WINEDEBUG=-all WINEDLLOVERRIDES="winemenubuilder.exe=d" wine "$SCRIPT_DIR/MicrosoftEdgeSetup.exe" &
EDGE_PID=$!
sleep 30
# Kill any leftover Edge processes
WINEDEBUG=-all wineserver -k 2>/dev/null || true
ok "Microsoft Edge installation done."

# =============================================================================
# Install Microsoft Edge WebView2
# =============================================================================

log "Installing Microsoft Edge WebView2 135.0.3179.85... (may crash after — this is expected)"
WINEDEBUG=-all WINEDLLOVERRIDES="winemenubuilder.exe=d" wine "$SCRIPT_DIR/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" &
sleep 20
WINEDEBUG=-all wineserver -k 2>/dev/null || true
ok "WebView2 installation done."

# =============================================================================
# Set WebView2 executable to Windows 7 compatibility
# (fixes the asset store not loading in the launcher)
# =============================================================================

log "Setting msedgewebview2.exe compatibility to Windows 7..."
WEBVIEW2_REG_PATH="HKCU\\Software\\Wine\\AppDefaults\\msedgewebview2.exe"
wine reg add "$WEBVIEW2_REG_PATH" /v Version /t REG_SZ /d "win7" /f >/dev/null 2>&1
ok "WebView2 set to Windows 7."

# =============================================================================
# Install Clip Studio Paint
# =============================================================================

log "Installing Clip Studio Paint 4.1.0... (installer may close on its own after success)"
WINEDEBUG=-all wine "$SCRIPT_DIR/CSP_410w_setup.exe"
ok "Clip Studio Paint installation done."

# =============================================================================
# Set CLIPStudioPaint.exe to Windows 8.1 compatibility
# =============================================================================

log "Setting CLIPStudioPaint.exe compatibility to Windows 8.1..."
wine reg add "HKCU\\Software\\Wine\\AppDefaults\\CLIPStudioPaint.exe" /v Version /t REG_SZ /d "win81" /f >/dev/null 2>&1
ok "CLIPStudioPaint.exe set to Windows 8.1."

# =============================================================================
# Create desktop entry
# =============================================================================

log "Creating desktop shortcut..."
DESKTOP_FILE="$HOME/.local/share/applications/clipstudiopaint.desktop"
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Clip Studio Paint
Exec=env WINEPREFIX="$WINEPREFIX" WINEESYNC=1 WINEFSYNC=1 wine "$CSP_EXE"
Type=Application
Categories=Graphics;
StartupWMClass=clipstudiopaint.exe
EOF

chmod +x "$DESKTOP_FILE"
ok "Desktop shortcut created at $DESKTOP_FILE"

# KDE: also copy to Desktop
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    cp "$DESKTOP_FILE" "$HOME/Desktop/clipstudiopaint.desktop" 2>/dev/null && \
        ok "KDE detected — shortcut also copied to ~/Desktop"
fi

# =============================================================================
# Done
# =============================================================================

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Clip Studio Paint 4.1.0 setup complete!   ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "Launch with:"
echo -e "  ${CYAN}WINEPREFIX=\"$WINEPREFIX\" WINEESYNC=1 WINEFSYNC=1 wine \"$CSP_EXE\"${NC}"
echo ""
echo -e "Or use the desktop shortcut in your app launcher."
echo ""
echo -e "${YELLOW}First launch tip:${NC} Allow CSP to download all materials."
echo -e "  The launcher home screen may show black briefly — this is normal."
echo ""
echo -e "${YELLOW}Tablet pen pressure:${NC}"
echo -e "  File > Preferences > Tablet > Use mouse mode in tablet driver settings"
echo ""
