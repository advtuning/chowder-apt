#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == "Linux" ]] || { echo "Chowder for Linux must be installed on Linux." >&2; exit 1; }
case "$(dpkg --print-architecture 2>/dev/null || true)" in
  amd64|arm64) ;;
  *) echo "This installer supports Debian/Ubuntu amd64 and arm64." >&2; exit 1 ;;
esac

repo="https://advtuning.github.io/chowder-apt"
keyring="/usr/share/keyrings/chowder-archive-keyring.gpg"
source_list="/etc/apt/sources.list.d/chowder.list"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsSL "$repo/chowder-archive-keyring.gpg" -o "$work/chowder-archive-keyring.gpg"
sudo install -m 0644 "$work/chowder-archive-keyring.gpg" "$keyring"
printf '%s\n' "deb [arch=amd64,arm64 signed-by=$keyring] $repo stable main" > "$work/chowder.list"
sudo install -m 0644 "$work/chowder.list" "$source_list"

sudo apt-get update
sudo apt-get install -y chowder clamav clamav-freshclam

command -v chowder >/dev/null
command -v clamscan >/dev/null
command -v freshclam >/dev/null
echo "Chowder and ClamAV installed successfully. Launch Chowder from the application menu."
