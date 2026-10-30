#!/usr/bin/env bash
# Leva um PC instalado com uma versão anterior deste repo ao estado atual:
# pacotes de rede, visual macOS + Batman reaplicado (terminal, barra, dock, widgets)
# e só o painel de cima no Cinnamon (sem o dock antigo feito com um segundo painel).
# Temporário: depois de rodar no outro PC, este script sai do repo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
  echo "Rode como usuário normal (o script chama sudo quando precisa)." >&2
  exit 1
fi

# Pacotes novos
sudo apt install -y arp-scan whois dnsutils

# Visual: as etapas sobrescrevem tema, terminal, prompt, dock e widgets
"$ROOT/install.sh" macos terminal batman

# Barra: só o painel de cima, 24 px, sem restos do painel 2
dconf write /org/cinnamon/panels-enabled "['1:0:top']"
dconf write /org/cinnamon/panels-height "['1:24']"
dconf write /org/cinnamon/panels-autohide "['1:false']"
dconf write /org/cinnamon/panels-show-delay "['1:0']"
dconf write /org/cinnamon/panels-hide-delay "['1:0']"
dconf write /org/cinnamon/panel-zone-icon-sizes '"[{\"panelId\":1,\"left\":16,\"center\":0,\"right\":16}]"'
dconf write /org/cinnamon/panel-zone-symbolic-icon-sizes '"[{\"panelId\":1,\"left\":16,\"center\":16,\"right\":16}]"'
dconf write /org/cinnamon/panel-zone-text-sizes '"[{\"panelId\":1,\"left\":0,\"center\":0,\"right\":0}]"'
dconf write /org/cinnamon/enabled-applets "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:1:xapp-status@cinnamon.org:4', 'panel1:right:2:notifications@cinnamon.org:5', 'panel1:right:3:printers@cinnamon.org:6', 'panel1:right:4:removable-drives@cinnamon.org:7', 'panel1:right:5:keyboard@cinnamon.org:8', 'panel1:right:7:network@cinnamon.org:10', 'panel1:right:8:sound@cinnamon.org:11', 'panel1:right:9:power@cinnamon.org:12', 'panel1:right:10:calendar@cinnamon.org:13']"
dconf write /org/cinnamon/enabled-extensions "['transparent-panels@germanfr', 'widget-blur@local']"

# Terminal: o perfil Batman precisa ser o padrão
PROFILE="$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")"
dconf load "/org/gnome/terminal/legacy/profiles:/:$PROFILE/" < "$ROOT/dotfiles/batman/gnome-terminal.dconf"
grep -q 'starship init bash' "$HOME/.bashrc" || printf '\n# prompt\neval "$(starship init bash)"\n' >> "$HOME/.bashrc"

# Dock: reinicia o Plank com os apps novos
pkill -x plank || true
setsid plank >/dev/null 2>&1 &

echo -e "\n\033[1;32mPronto!\033[0m Faça logout/login para a barra e o tema recarregarem."
