#!/usr/bin/env bash
# Visual de macOS no Cinnamon: tema WhiteSur (GTK + Cinnamon), ícones, cursor, wallpaper,
# fonte Inter, botões das janelas à esquerda, painel em cima e dock Plank embaixo
set -euo pipefail

if [ "${XDG_CURRENT_DESKTOP:-}" != "X-Cinnamon" ]; then
  echo "Não está no Cinnamon, pulando."
  exit 0
fi

sudo apt install -y plank fonts-inter sassc libglib2.0-dev-bin

# Temas WhiteSur (instalam em ~/.themes e ~/.local/share/icons)
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for repo in WhiteSur-gtk-theme WhiteSur-icon-theme WhiteSur-cursors; do
  git clone --depth=1 "https://github.com/vinceliuice/$repo.git" "$tmp/$repo"
done
(cd "$tmp/WhiteSur-gtk-theme" && ./install.sh -c dark)
(cd "$tmp/WhiteSur-icon-theme" && ./install.sh -t default)
(cd "$tmp/WhiteSur-cursors" && ./install.sh)

# Wallpaper
WALL="$HOME/.local/share/backgrounds/WhiteSur-dark.jpg"
mkdir -p "$(dirname "$WALL")"
[ -f "$WALL" ] || curl -fsSL -o "$WALL" \
  https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/WhiteSur-dark.jpg

dconf load /org/cinnamon/ < "$ROOT/dotfiles/macos/cinnamon.dconf"
gsettings set org.cinnamon.desktop.background picture-uri "file://$WALL"

# Plank: config e início automático
dconf load /net/launchpad/plank/docks/ < "$ROOT/dotfiles/macos/plank.dconf"
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
DESKTOP
pgrep -x plank >/dev/null || (setsid plank >/dev/null 2>&1 &)
