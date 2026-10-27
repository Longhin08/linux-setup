#!/usr/bin/env bash
# Reinstala o ambiente: ./install.sh            (tudo)
#                       ./install.sh apt dev   (só as etapas escolhidas)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROOT

STEPS=(apt repos dev vscode desktop dotfiles)
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
  bash "$script"
done

echo -e "\n\033[1;32mPronto!\033[0m Faça logout/login para aplicar o grupo docker e o tema."
echo "Depois: gh auth login  e  claude  (para logar)."
