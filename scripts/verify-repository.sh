#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
keyring="$root/chowder-archive-keyring.gpg"
release="$root/dists/stable/Release"

[[ -s "$keyring" ]] || { echo "Missing repository keyring." >&2; exit 1; }
gpgv --keyring "$keyring" "$root/dists/stable/InRelease"
gpgv --keyring "$keyring" "$root/dists/stable/Release.gpg" "$release"

for arch in amd64 arm64; do
  packages="$root/dists/stable/main/binary-$arch/Packages"
  [[ -s "$packages" ]] || { echo "Missing Packages index for $arch." >&2; exit 1; }
  grep -q '^Package: chowder$' "$packages"
  grep -q "^Architecture: $arch$" "$packages"
  gzip -cd "$packages.gz" | cmp -s - "$packages"
done

while read -r digest size relative; do
  file="$root/dists/stable/$relative"
  [[ -f "$file" ]] || { echo "Release references missing file: $relative" >&2; exit 1; }
  [[ "$(stat -c %s "$file")" == "$size" ]] || { echo "Size mismatch: $relative" >&2; exit 1; }
  [[ "$(sha256sum "$file" | cut -d' ' -f1)" == "$digest" ]] || { echo "Digest mismatch: $relative" >&2; exit 1; }
done < <(sed -n '/^SHA256:$/,$p' "$release" | tail -n +2)

echo "Chowder APT repository verification passed."

