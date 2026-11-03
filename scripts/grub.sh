#!/usr/bin/env bash
# Dual boot: o menu do GRUB espera a escolha, sem iniciar nada sozinho
set -euo pipefail

if [ -z "$(sudo os-prober 2>/dev/null || true)" ]; then
  echo "Nenhum outro sistema encontrado, pulando."
  exit 0
fi

sudo install -m 0644 "$ROOT/dotfiles/grub/99-menu-sem-timeout.cfg" /etc/default/grub.d/99-menu-sem-timeout.cfg
sudo update-grub
