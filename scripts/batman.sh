#!/usr/bin/env bash
# Cores do Batman por cima do visual de macOS: WhiteSur com destaque amarelo, pastas Papirus amarelas,
# dock e widgets pretos com amarelo, terminal e prompt nas mesmas cores, wallpapers do Batman e do Homem de Ferro
# (Precisa das etapas macos e terminal antes; para voltar: ./install.sh macos terminal)
set -euo pipefail

if [ "${XDG_CURRENT_DESKTOP:-}" != "X-Cinnamon" ]; then
  echo "Não está no Cinnamon, pulando."
  exit 0
fi

B="$ROOT/dotfiles/batman"
sudo apt install -y python3-pil

# Tema: cópia do WhiteSur-Dark com o azul trocado por amarelo + widgets pretos
python3 "$B/recolor-theme.py" "$HOME/.themes/WhiteSur-Dark" "$HOME/.themes/WhiteSur-Dark-Batman" WhiteSur-Dark-Batman
cat "$B/widgets.css" >> "$HOME/.themes/WhiteSur-Dark-Batman/cinnamon/cinnamon.css"

# Pastas amarelas
"$HOME/.local/bin/papirus-folder-color" yellow

# Dock
mkdir -p "$HOME/.local/share/plank/themes/Batman"
cp "$B/dock.theme" "$HOME/.local/share/plank/themes/Batman/dock.theme"

# Terminal e prompt
PROFILE="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
PROFILE="${PROFILE:-b1dcc9dd-5262-4d8d-a863-c897e6d979b9}"
dconf load "/org/gnome/terminal/legacy/profiles:/:$PROFILE/" < "$B/gnome-terminal.dconf"
cp "$B/starship.toml" "$HOME/.config/starship.toml"

# Wallpapers do Batman e do Homem de Ferro (wallhaven.cc); usa o Batman no telhado de Gotham
WALLS="$HOME/.local/share/backgrounds/batman"
mkdir -p "$WALLS"
for f in g7/wallhaven-g7leed.png m9/wallhaven-m96d8m.jpg 8o/wallhaven-8o6pjy.jpg o3/wallhaven-o3dx2l.jpg \
         p2/wallhaven-p21383.jpg 4d/wallhaven-4d681o.jpg d8/wallhaven-d88wjg.jpg q6/wallhaven-q67oel.jpg; do
  [ -f "$WALLS/${f#*/}" ] || curl -fsSL -o "$WALLS/${f#*/}" "https://w.wallhaven.cc/full/$f"
done
grep -qx "$WALLS" "$HOME/.cinnamon/backgrounds/user-folders.lst" || echo "$WALLS" >> "$HOME/.cinnamon/backgrounds/user-folders.lst"

dconf load / < "$B/batman.dconf"
gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLS/wallhaven-g7leed.png"
