# linux-setup

Recria meu ambiente **Linux Mint 22.3 (Cinnamon)** numa instalação nova, com visual de macOS.

## Uso

```bash
sudo apt install -y git
git clone https://github.com/Longhin08/linux-setup.git
cd linux-setup
./install.sh
```

Depois: logout/login (grupo `docker` + tema), `gh auth login` e `claude` para logar.

Dá pra rodar só algumas etapas:

```bash
./install.sh apt dev
```

Os scripts podem ser rodados de novo sem problema; o que já está instalado é pulado.

## Etapas

| Etapa      | O que faz |
|------------|-----------|
| `apt`      | `apt upgrade` + pacotes de [`packages.txt`](packages.txt): git, gh, jq, tmux, zsh, build-essential, Python (pip/venv/dev), codecs |
| `repos`    | VS Code, Docker (+ compose/buildx, usuário no grupo `docker`), AnyDesk, Google Chrome, Discord |
| `dev`      | nvm + Node 24, Claude Code, OpenCode, Orca (AppImage + atalho no menu) |
| `vscode`   | Extensões de [`vscode-extensions.txt`](vscode-extensions.txt) |
| `desktop`  | Base do Cinnamon: gestos do touchpad, teclado `br+thinkpad`, sons desligados |
| `macos`    | Visual de macOS: tema [WhiteSur](https://github.com/vinceliuice/WhiteSur-gtk-theme) escuro (apps, bordas com botões 🟡🟢🔴 à direita e Cinnamon), ícones Papirus com pastas azuis, cursor Bibata, fonte Inter, wallpapers escuros do macOS, barra em cima fina e transparente, dock [Plank Reloaded](https://github.com/zquestz/plank-reloaded) com prévia das janelas, widgets (relógio, calendário, monitor) com vidro desfocado, busca [Ulauncher](https://ulauncher.io) no Super+Espaço, gestos de 3/4 dedos, prints Super+Shift+3/4/5 e luz noturna |
| `terminal` | gnome-terminal com as cores da Apple no modo escuro, fonte MesloLGS Nerd Font e prompt [Starship](https://starship.rs) |
| `dotfiles` | `.bashrc` (PATH, nvm, opencode), git (nome/e-mail + credencial do gh), statusline e atalhos do Claude Code |

## Atualizar o repo com o estado atual da máquina

```bash
dconf dump /org/cinnamon/ > dotfiles/cinnamon/cinnamon.dconf   # base (etapa desktop)
code --list-extensions > vscode-extensions.txt
cp ~/.claude/statusline.sh ~/.claude/keybindings.json dotfiles/claude/
```

O visual de macOS fica em [`dotfiles/macos/macos.dconf`](dotfiles/macos/macos.dconf) (só as chaves que ele muda); ajustar à mão.

Pacotes apt novos: adicionar em `packages.txt`.

## Visual de macOS: detalhes

- **Cor das pastas**: `papirus-folder-color orange` (ou `red`, `green`...) e escolher `Papirus-Dark-<Cor>` em Temas → Ícones.
- **Widgets**: a extensão `widget-blur@local` usa como fundo um pedaço borrado do wallpaper; acompanha quando o widget é arrastado ou o wallpaper muda.
- **Dock**: Ctrl + clique direito no dock abre as preferências do Plank.

## Voltar ao visual padrão do Mint

```bash
dconf load /org/cinnamon/ < dotfiles/cinnamon/cinnamon.dconf
gsettings set org.cinnamon.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.cinnamon panels-enabled "['1:0:bottom']"
pkill plank; rm ~/.config/autostart/plank.desktop
```
