#!/usr/bin/env bash
# Driver proprietário da NVIDIA (com o nouveau as animações do Cinnamon travam); só roda se tiver placa NVIDIA.
# Em notebook híbrido, deixa a NVIDIA desenhando a tela (prime-select nvidia). Precisa reiniciar depois.
set -euo pipefail

if ! lspci | grep -Eqi '(vga|3d).*nvidia'; then
  echo "Sem placa NVIDIA, pulando."
  exit 0
fi

# Driver recomendado pelo ubuntu-drivers (o mesmo que o Gerenciador de Drivers do Mint escolhe)
if ! dpkg -l 'nvidia-driver-*' 2>/dev/null | grep -q '^ii'; then
  sudo apt install -y ubuntu-drivers-common
  sudo ubuntu-drivers install
fi

if command -v prime-select >/dev/null && [ "$(prime-select query)" != "nvidia" ]; then
  sudo prime-select nvidia
fi

echo "Reinicie para carregar o driver da NVIDIA (com Secure Boot, confirme a chave MOK na tela azul do boot)."
