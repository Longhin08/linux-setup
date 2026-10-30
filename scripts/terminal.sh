#!/usr/bin/env bash
# Terminal com cara de macOS: cores do sistema da Apple no modo escuro,
# fonte Meslo (derivada da Menlo, com ícones Nerd Font) e prompt Starship
set -euo pipefail

# Fonte
FONT_DIR="$HOME/.local/share/fonts/MesloNerd"
if [ ! -d "$FONT_DIR" ]; then
  mkdir -p "$FONT_DIR"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz \
    | tar -xJ -C "$FONT_DIR"
  fc-cache -f "$FONT_DIR"
fi

# Starship (binário da release oficial)
mkdir -p "$HOME/.local/bin" "$HOME/.config"
if [ ! -x "$HOME/.local/bin/starship" ]; then
  curl -fsSL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz \
    | tar -xz -C "$HOME/.local/bin" starship
fi
cp "$ROOT/dotfiles/terminal/starship.toml" "$HOME/.config/starship.toml"
if ! grep -q 'starship init bash' "$HOME/.bashrc"; then
  printf '\n# prompt\neval "$(starship init bash)"\n' >> "$HOME/.bashrc"
fi

# Perfil padrão do gnome-terminal
PROFILE="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
PROFILE="${PROFILE:-b1dcc9dd-5262-4d8d-a863-c897e6d979b9}"
dconf load "/org/gnome/terminal/legacy/profiles:/:$PROFILE/" < "$ROOT/dotfiles/terminal/gnome-terminal.dconf"

# Selecionar texto já copia (o gnome-terminal não tem essa opção): o autocutsel
# sincroniza a seleção (PRIMARY) com a área de transferência, no terminal e no resto do sistema
sudo apt install -y autocutsel
mkdir -p "$HOME/.config/autostart"
printf '[Desktop Entry]\nType=Application\nName=Copiar ao selecionar\nExec=sh -c "autocutsel -fork; autocutsel -selection PRIMARY -fork"\nX-GNOME-Autostart-enabled=true\nNoDisplay=true\n' \
  > "$HOME/.config/autostart/autocutsel.desktop"
pgrep -x autocutsel >/dev/null || { autocutsel -fork; autocutsel -selection PRIMARY -fork; }
