#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
incoming="$root/incoming"
gpg_home="${CHOWDER_APT_GPG_HOME:?Set CHOWDER_APT_GPG_HOME to the private repository GnuPG home}"
codename="stable"
component="main"

command -v dpkg-scanpackages >/dev/null || { echo "dpkg-scanpackages is required (package: dpkg-dev)." >&2; exit 2; }
command -v gpg >/dev/null || { echo "gpg is required." >&2; exit 2; }
[[ -d "$gpg_home" ]] || { echo "GnuPG home not found: $gpg_home" >&2; exit 2; }
compgen -G "$incoming/*.deb" >/dev/null || { echo "No .deb files found in $incoming" >&2; exit 2; }

rm -rf "$root/pool" "$root/dists"
mkdir -p "$root/pool/$component/c/chowder"
for deb in "$incoming"/*.deb; do
  package="$(dpkg-deb -f "$deb" Package)"
  version="$(dpkg-deb -f "$deb" Version)"
  arch="$(dpkg-deb -f "$deb" Architecture)"
  [[ "$package" == "chowder" ]] || { echo "Unexpected package in incoming: $package" >&2; exit 1; }
  cp "$deb" "$root/pool/$component/c/chowder/${package}_${version}_${arch}.deb"
done

for tuple in "amd64:linux-x64" "arm64:linux-arm64"; do
  arch="${tuple%%:*}"
  marker="${tuple##*:}"
  binary_dir="$root/dists/$codename/$component/binary-$arch"
  mkdir -p "$binary_dir"
  (
    cd "$root"
    dpkg-scanpackages --arch "$arch" "pool/$component/c/chowder" /dev/null > "dists/$codename/$component/binary-$arch/Packages"
  )
  grep -q "Architecture: $arch" "$binary_dir/Packages" || { echo "No $arch package indexed (expected $marker)." >&2; exit 1; }
  gzip -9 -k "$binary_dir/Packages"
done

release_dir="$root/dists/$codename"
release="$release_dir/Release"
{
  echo "Origin: Clarity Soft"
  echo "Label: ChowderAV"
  echo "Suite: $codename"
  echo "Codename: $codename"
  echo "Date: $(LC_ALL=C date -Ru)"
  echo "Architectures: amd64 arm64"
  echo "Components: $component"
  echo "Description: ChowderAV signed package repository"
  echo "SHA256:"
  while IFS= read -r file; do
    relative="${file#"$release_dir/"}"
    printf ' %s %16s %s\n' "$(sha256sum "$file" | cut -d' ' -f1)" "$(stat -c %s "$file")" "$relative"
  done < <(find "$release_dir/$component" -type f -print | LC_ALL=C sort)
} > "$release"

key_fingerprint="$(gpg --homedir "$gpg_home" --batch --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ -n "$key_fingerprint" ]] || { echo "No secret signing key found in $gpg_home" >&2; exit 2; }
gpg --homedir "$gpg_home" --batch --yes --armor --detach-sign --local-user "$key_fingerprint" --output "$release_dir/Release.gpg" "$release"
gpg --homedir "$gpg_home" --batch --yes --clearsign --local-user "$key_fingerprint" --output "$release_dir/InRelease" "$release"
gpg --homedir "$gpg_home" --batch --yes --export "$key_fingerprint" > "$root/chowder-archive-keyring.gpg"

echo "Built signed Chowder APT repository with key $key_fingerprint"
