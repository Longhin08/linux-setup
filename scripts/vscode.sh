#!/usr/bin/env bash
# Extensões do VS Code
set -euo pipefail

grep -vE '^\s*(#|$)' "$ROOT/vscode-extensions.txt" | while read -r ext; do
  code --install-extension "$ext" --force
done
