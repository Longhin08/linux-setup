#!/usr/bin/env bash
# Base do Cinnamon: gestos do touchpad, teclado, sons desligados, monitores na taxa máxima
set -euo pipefail

if [ "${XDG_CURRENT_DESKTOP:-}" != "X-Cinnamon" ]; then
  echo "Não está no Cinnamon, pulando."
  exit 0
fi
dconf load /org/cinnamon/ < "$ROOT/dotfiles/cinnamon/cinnamon.dconf"

# Monitores sempre na taxa de atualização máxima (no login e ao plugar um monitor)
mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"
install -m 0755 "$ROOT/dotfiles/bin/max-refresh" "$HOME/.local/bin/max-refresh"
printf '[Desktop Entry]\nType=Application\nName=Taxa de atualização máxima\nExec=%s --watch\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\n' \
  "$HOME/.local/bin/max-refresh" > "$HOME/.config/autostart/max-refresh.desktop"
