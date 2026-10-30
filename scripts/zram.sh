#!/usr/bin/env bash
# Swap comprimido na RAM (zram, zstd, metade da RAM) com prioridade sobre o swap em disco:
# com pouca memória, voltar para uma janela que foi pro swap não trava lendo o disco
set -euo pipefail

sudo apt install -y systemd-zram-generator
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 100\n' \
  | sudo tee /etc/systemd/zram-generator.conf >/dev/null
printf 'vm.swappiness = 180\nvm.page-cluster = 0\n' | sudo tee /etc/sysctl.d/99-zram.conf >/dev/null
sudo systemctl daemon-reload
# O apt já pode ter subido o zram0 pela metade ("Device or resource busy"): zera e tenta de novo.
# Se mesmo assim não subir, não trava o resto da instalação: o zram liga sozinho no próximo boot.
sudo systemctl stop dev-zram0.swap systemd-zram-setup@zram0.service 2>/dev/null || true
sudo swapoff /dev/zram0 2>/dev/null || true
sudo zramctl --reset /dev/zram0 2>/dev/null || true
sudo systemctl reset-failed systemd-zram-setup@zram0.service 2>/dev/null || true
sudo systemctl start dev-zram0.swap || echo "zram não subiu agora; vai ativar depois de reiniciar."
sudo sysctl -q -p /etc/sysctl.d/99-zram.conf
swapon --show
