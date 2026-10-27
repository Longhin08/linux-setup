#!/usr/bin/env bash
# Baixa a ISO do Linux Mint (mesma versão desta máquina), confere assinatura e hash e, se pedir, grava no pendrive.
# Uso: ./iso.sh                (baixa em ~/Downloads)
#      ./iso.sh /dev/sdX       (baixa e grava no pendrive /dev/sdX; APAGA o pendrive)
# Outra versão/edição: MINT_VERSION=22.3 MINT_EDITION=cinnamon ./iso.sh
set -euo pipefail

VER="${MINT_VERSION:-22.3}"
ED="${MINT_EDITION:-cinnamon}"
ISO="linuxmint-$VER-$ED-64bit.iso"
URL="https://mirrors.edge.kernel.org/linuxmint/stable/$VER"
KEY=27DEB15644C6B3CF3BD7D291300F846BA25BAE09   # Linux Mint ISO Signing Key
DIR="$HOME/Downloads"
mkdir -p "$DIR"
cd "$DIR"

echo "==> Baixando $ISO (continua se tiver parado no meio)"
curl -fL -C - -o "$ISO" "$URL/$ISO"
curl -fsSL -o sha256sum.txt "$URL/sha256sum.txt"
curl -fsSL -o sha256sum.txt.gpg "$URL/sha256sum.txt.gpg"

echo "==> Conferindo a assinatura da lista de hashes"
export GNUPGHOME="$(mktemp -d)"
trap 'rm -rf "$GNUPGHOME"' EXIT
gpg -q --keyserver hkps://keyserver.ubuntu.com --recv-keys "$KEY"
gpg -q --verify sha256sum.txt.gpg sha256sum.txt

echo "==> Conferindo o hash da ISO"
grep " \*$ISO\$" sha256sum.txt | sha256sum -c -
echo "ISO ok: $DIR/$ISO"

[ $# -eq 0 ] && exit 0
DEV="$1"
[ -b "$DEV" ] || { echo "$DEV não é um disco." >&2; exit 1; }
[ "$(lsblk -dno TYPE "$DEV")" = disk ] || { echo "Use o disco inteiro (ex.: /dev/sdb), não uma partição." >&2; exit 1; }
[ "$(lsblk -dno RM "$DEV")" = 1 ] || { echo "$DEV não é removível; por segurança, não gravo nele." >&2; exit 1; }
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS "$DEV"
read -rp "Tudo em $DEV será APAGADO. Digite o nome do disco ($DEV) para confirmar: " ok
[ "$ok" = "$DEV" ] || { echo "Cancelado."; exit 1; }
for p in $(lsblk -lno PATH "$DEV" | tail -n +2); do sudo umount "$p" 2>/dev/null || true; done
sudo dd if="$ISO" of="$DEV" bs=4M status=progress conv=fsync
echo "Pronto: pendrive com o Mint $VER $ED."
