#!/usr/bin/env bash
# Swap comprimido na RAM (zram, zstd, metade da RAM) com prioridade sobre o swap em disco:
# com pouca memória, voltar para uma janela que foi pro swap não trava lendo o disco
set -euo pipefail

sudo apt install -y systemd-zram-generator
printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 100\n' \
  | sudo tee /etc/systemd/zram-generator.conf >/dev/null
printf 'vm.swappiness = 180\nvm.page-cluster = 0\n' | sudo tee /etc/sysctl.d/99-zram.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
sudo sysctl -q -p /etc/sysctl.d/99-zram.conf
swapon --show
