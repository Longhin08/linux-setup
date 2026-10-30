#!/usr/bin/env bash
# Visual de macOS no Cinnamon: tema WhiteSur escuro (apps, bordas e Cinnamon), ícones Papirus com pastas
# azuis, fonte Inter, cursor Bibata, wallpapers escuros do macOS, barra em cima transparente, dock
# Plank Reloaded, widgets com vidro desfocado, busca Ulauncher (Super+Espaço), gestos e atalhos de print
set -euo pipefail

if [ "${XDG_CURRENT_DESKTOP:-}" != "X-Cinnamon" ]; then
  echo "Não está no Cinnamon, pulando."
  exit 0
fi

M="$ROOT/dotfiles/macos"
SPICES=https://cinnamon-spices.linuxmint.com/files
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Pacotes: Plank Reloaded (repo do autor) e Ulauncher (.deb do GitHub)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://zquestz.github.io/ppa/ubuntu/KEY.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/zquestz.gpg
echo "deb [signed-by=/etc/apt/keyrings/zquestz.gpg] https://zquestz.github.io/ppa/ubuntu ./" \
  | sudo tee /etc/apt/sources.list.d/zquestz.list >/dev/null
sudo apt update
sudo apt remove -y plank libplank-common libplank1 2>/dev/null || true
sudo apt install -y fonts-inter papirus-icon-theme mint-cursor-themes gir1.2-gtop-2.0 plank-reloaded
if ! command -v ulauncher >/dev/null; then
  curl -fsSL -o "$tmp/ulauncher.deb" \
    https://github.com/Ulauncher/Ulauncher/releases/download/5.16.2/ulauncher_5.16.2_all.deb
  sudo apt install -y "$tmp/ulauncher.deb"
fi

# Tema WhiteSur escuro (versão pronta do repositório, sem rodar o install.sh deles)
mkdir -p "$HOME/.themes"
curl -fsSL https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/release/WhiteSur-Dark.tar.xz \
  | tar -xJ -C "$HOME/.themes"
# Tema do Cinnamon = WhiteSur + estilo dos widgets
mkdir -p "$HOME/.themes/WhiteSur-Dark-Widgets/cinnamon"
sed "s|@HOME@|$HOME|g" "$M/cinnamon-theme.css" > "$HOME/.themes/WhiteSur-Dark-Widgets/cinnamon/cinnamon.css"

# Ícones: Papirus-Dark com pastas azuis
mkdir -p "$HOME/.local/bin"
install -m 0755 "$ROOT/dotfiles/bin/papirus-folder-color" "$HOME/.local/bin/papirus-folder-color"
"$HOME/.local/bin/papirus-folder-color" blue

# Wallpapers escuros do macOS (512pixels.net); usa o Golden Gate
WALLS="$HOME/.local/share/backgrounds/macos-dark"
mkdir -p "$WALLS"
for f in 27-Golden-Gate-Dark.png 26-Tahoe-Dark-6K.png 15-Sequoia-Dark-6K.jpg 14-Sonoma-Dark.jpg \
         13-Ventura-Dark.jpg 12-Monterey-Dark.jpg 11-Big-Sur-Night-6k.jpg 10-15-Night-6k.jpg 10-14-Night-6k.jpg; do
  [ -f "$WALLS/$f" ] || curl -fsSL -o "$WALLS/$f" "https://media.512pixels.net/downloads/macos-wallpapers-6k/$f"
done
mkdir -p "$HOME/.cinnamon/backgrounds"
touch "$HOME/.cinnamon/backgrounds/user-folders.lst"
grep -qx "$WALLS" "$HOME/.cinnamon/backgrounds/user-folders.lst" || echo "$WALLS" >> "$HOME/.cinnamon/backgrounds/user-folders.lst"

# Extensões: barra transparente (Spices) e vidro desfocado nos widgets (deste repo)
EXT="$HOME/.local/share/cinnamon/extensions"
mkdir -p "$EXT" "$HOME/.local/share/widget-blur"
curl -fsSL -o "$tmp/tp.zip" "$SPICES/extensions/transparent-panels@germanfr.zip"
unzip -oq "$tmp/tp.zip" -d "$EXT"
cp -r "$M/widget-blur@local" "$EXT/"
cp "$M/make-blur.py" "$HOME/.local/share/widget-blur/make-blur.py"

# Widgets: relógio (nativo), calendário e monitor do sistema (Spices)
DESK="$HOME/.local/share/cinnamon/desklets"
mkdir -p "$DESK"
for d in calendar@deeppradhan simple-system-monitor@ariel; do
  curl -fsSL -o "$tmp/$d.zip" "$SPICES/desklets/$d.zip"
  unzip -oq "$tmp/$d.zip" -d "$DESK"
  mkdir -p "$HOME/.config/cinnamon/spices/$d"
  sed "s|@HOME@|$HOME|g" "$M/desklets/$d.json" > "$HOME/.config/cinnamon/spices/$d/$d.json"
done
# Calendário com os mesmos cantos dos outros widgets (a moldura vem da extensão widget-blur)
sed -i 's|"; border-radius: " + (this.fontSize / 3 \* 2) + "pt; color: "|"; border-radius: 24px; color: "|' \
  "$DESK/calendar@deeppradhan/desklet.js"
# Temperatura: o monitor procura um arquivo "temp"; aponta para o sensor da CPU (AMD k10temp ou Intel coretemp)
for h in /sys/class/hwmon/hwmon*; do
  case "$(cat "$h/name" 2>/dev/null)" in
    k10temp|coretemp)
      mkdir -p "$HOME/.local/share/cpu-temp"
      ln -sf "$(readlink -f "$h")/temp1_input" "$HOME/.local/share/cpu-temp/temp"
      break ;;
  esac
done

# Dock Plank Reloaded: tema com pontinhos discretos, apps fixados, abre com o sistema
mkdir -p "$HOME/.local/share/plank/themes/Mac-Dots" "$HOME/.config/plank/dock1/launchers" "$HOME/.config/autostart"
cp "$M/plank-theme/dock.theme" "$HOME/.local/share/plank/themes/Mac-Dots/dock.theme"
rm -f "$HOME/.config/plank/dock1/launchers/nemo.dockitem"
for a in org.gnome.Terminal google-chrome; do
  printf '[PlankDockItemPreferences]\nLauncher=file:///usr/share/applications/%s.desktop\n' "$a" \
    > "$HOME/.config/plank/dock1/launchers/$a.dockitem"
done
# Orca (o .desktop vem da etapa dev)
printf '[PlankDockItemPreferences]\nLauncher=file://%s/.local/share/applications/orca-ide.desktop\n' "$HOME" \
  > "$HOME/.config/plank/dock1/launchers/orca-ide.dockitem"
printf '[Desktop Entry]\nType=Application\nName=Plank\nExec=plank\nX-GNOME-Autostart-enabled=true\n' \
  > "$HOME/.config/autostart/plank.desktop"

# Ulauncher: tema escuro, abre com o sistema (o atalho Super+Espaço é do Cinnamon, no dconf)
mkdir -p "$HOME/.config/ulauncher"
cp "$M/ulauncher-settings.json" "$HOME/.config/ulauncher/settings.json"
printf '[Desktop Entry]\nType=Application\nName=Ulauncher\nExec=ulauncher --hide-window\nX-GNOME-Autostart-enabled=true\n' \
  > "$HOME/.config/autostart/ulauncher.desktop"

dconf load / < "$M/macos.dconf"
gsettings set org.cinnamon.desktop.background picture-uri "file://$WALLS/27-Golden-Gate-Dark.png"
