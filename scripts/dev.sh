#!/usr/bin/env bash
# Ferramentas de dev no $HOME: nvm + Node, Claude Code, OpenCode, Orca
set -euo pipefail

NODE_VERSION=24

# nvm + Node
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

# Claude Code
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

# OpenCode
[ -x "$HOME/.opencode/bin/opencode" ] || curl -fsSL https://opencode.ai/install | bash

# Orca (AppImage, última release)
mkdir -p "$HOME/Applications" "$HOME/.local/bin" "$HOME/.local/share/applications"
if [ ! -f "$HOME/Applications/orca.AppImage" ]; then
  url="$(curl -fsSL https://api.github.com/repos/stablyai/orca/releases/latest \
    | jq -r '.assets[] | select(.name=="orca-linux.AppImage") | .browser_download_url')"
  curl -fL -o "$HOME/Applications/orca.AppImage" "$url"
  chmod +x "$HOME/Applications/orca.AppImage"
fi
ln -sf "$HOME/Applications/orca.AppImage" "$HOME/.local/bin/orca"
cat > "$HOME/.local/share/applications/orca-ide.desktop" <<DESKTOP
[Desktop Entry]
Name=Orca
Exec=$HOME/Applications/orca.AppImage %U
Terminal=false
Type=Application
StartupWMClass=orca
Comment=Next-gen IDE for parallel agentic development
MimeType=text/markdown;text/csv;text/tab-separated-values;x-scheme-handler/orca;
Categories=Utility;
DESKTOP
# AppImage precisa de libfuse2
sudo apt install -y libfuse2t64 || sudo apt install -y libfuse2
