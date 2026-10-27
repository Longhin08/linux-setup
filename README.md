# linux-setup

Recria meu ambiente **Linux Mint 22.3 (Cinnamon)** numa instalação nova.

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
| `desktop`  | Cinnamon: tema Mint-Y-Dark-Blue, ícones Mint-Y-Yaru, cursor Bibata, wallpaper, painel, gestos, teclado `br+thinkpad` |
| `dotfiles` | `.bashrc` (PATH, nvm, opencode), git (nome/e-mail + credencial do gh), statusline e atalhos do Claude Code |

## Atualizar o repo com o estado atual da máquina

```bash
dconf dump /org/cinnamon/ > dotfiles/cinnamon/cinnamon.dconf
code --list-extensions > vscode-extensions.txt
cp ~/.claude/statusline.sh ~/.claude/keybindings.json dotfiles/claude/
```

Pacotes apt novos: adicionar em `packages.txt`.
