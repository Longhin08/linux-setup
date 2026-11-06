#!/usr/bin/env bash
# Reinstala o ambiente: ./install.sh            (tudo)
#                       ./install.sh apt dev   (só as etapas escolhidas)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT

STEPS=(apt zram grub nvidia repos dev vscode desktop macos terminal batman dotfiles)
[ $# -gt 0 ] && STEPS=("$@")

if [ "$EUID" -eq 0 ]; then
  echo "Rode como usuário normal (o script chama sudo quando precisa)." >&2
  exit 1
fi

sudo -v
for step in "${STEPS[@]}"; do
  script="$ROOT/scripts/$step.sh"
  [ -f "$script" ] || { echo "Etapa desconhecida: $step" >&2; exit 1; }
  echo -e "\n\033[1;36m==> $step\033[0m"
  # login no GitHub antes do dotfiles, que liga o git à credencial do gh
  if [ "$step" = dotfiles ] && command -v gh >/dev/null \
     && ! gh auth status >/dev/null 2>&1 && [ -t 0 ]; then
    gh auth login --git-protocol https --web || echo "gh auth login falhou; rode depois e repita ./install.sh dotfiles" >&2
  fi
  bash "$script"
done

echo -e "\n\033[1;32mPronto!\033[0m Faça logout/login para aplicar o grupo docker e o tema."
echo "Depois: claude  (para logar)  e  sudo tailscale up."
