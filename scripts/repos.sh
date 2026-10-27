#!/usr/bin/env bash
# Programas de terceiros: VS Code, Docker, AnyDesk, Chrome, Discord
set -euo pipefail

sudo install -m 0755 -d /etc/apt/keyrings
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

# VS Code
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

# Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# AnyDesk
sudo curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY -o /etc/apt/keyrings/keys.anydesk.com.asc
echo "deb [signed-by=/etc/apt/keyrings/keys.anydesk.com.asc] https://deb.anydesk.com all main" \
  | sudo tee /etc/apt/sources.list.d/anydesk-stable.list >/dev/null

sudo apt update
sudo apt install -y code anydesk \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"

# Instala um .deb baixado (Chrome e Discord; o Chrome cadastra o próprio repositório)
install_deb() {
  local pkg="$1" url="$2" tmp
  dpkg -s "$pkg" >/dev/null 2>&1 && return
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/$pkg.deb" "$url"
  sudo apt install -y "$tmp/$pkg.deb"
  rm -rf "$tmp"
}
install_deb google-chrome-stable "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
install_deb discord "https://discord.com/api/download?platform=linux&format=deb"
