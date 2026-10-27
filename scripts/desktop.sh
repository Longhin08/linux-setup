#!/usr/bin/env bash
# Visual do Cinnamon: tema Mint-Y-Dark-Blue, ícones Mint-Y-Yaru, cursor Bibata, painel, gestos, teclado
set -euo pipefail

if [ "${XDG_CURRENT_DESKTOP:-}" != "X-Cinnamon" ]; then
  echo "Não está no Cinnamon, pulando."
  exit 0
fi
dconf load /org/cinnamon/ < "$ROOT/dotfiles/cinnamon/cinnamon.dconf"
