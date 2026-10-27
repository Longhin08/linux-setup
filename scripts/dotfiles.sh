#!/usr/bin/env bash
# .bashrc, git e configs do Claude Code
set -euo pipefail

# .bashrc (adiciona o bloco uma vez só)
if ! grep -q '>>> linux-setup >>>' "$HOME/.bashrc"; then
  cat "$ROOT/dotfiles/bashrc.append" >> "$HOME/.bashrc"
fi

# git
git config --global user.name "João Victor"
git config --global user.email "107821914+Longhin08@users.noreply.github.com"
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  gh auth setup-git
fi

# Claude Code: statusline + atalhos
mkdir -p "$HOME/.claude"
install -m 0755 "$ROOT/dotfiles/claude/statusline.sh" "$HOME/.claude/statusline.sh"
cp "$ROOT/dotfiles/claude/keybindings.json" "$HOME/.claude/keybindings.json"
settings="$HOME/.claude/settings.json"
[ -f "$settings" ] || echo '{}' > "$settings"
tmp="$(mktemp)"
jq '.statusLine = {"type":"command","command":"bash \"$HOME/.claude/statusline.sh\"","padding":0}
    | .enabledPlugins["frontend-design@claude-plugins-official"] = true' "$settings" > "$tmp"
mv "$tmp" "$settings"
