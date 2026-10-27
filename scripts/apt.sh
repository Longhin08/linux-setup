#!/usr/bin/env bash
# Pacotes dos repositórios oficiais
set -euo pipefail

sudo apt update
sudo apt upgrade -y
grep -vE '^\s*(#|$)' "$ROOT/packages.txt" | xargs sudo apt install -y
