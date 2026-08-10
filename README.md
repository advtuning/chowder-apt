# Chowder APT repository

Static, signed Ubuntu/Debian package repository for ChowderAV by Clarity Soft.

The currently published `0.1.2-test` packages are evaluation builds, not signed production
releases. The public landing page is generated from `index.html`.

The published repository is suitable for GitHub Pages or any HTTPS static host. It exposes
the public signing key at `chowder-archive-keyring.gpg` and package metadata beneath `dists/stable`.
The repository signing private key is never committed.

## Publish an update

1. Put the x64 and ARM64 `.deb` files in `incoming/`.
2. Export `CHOWDER_APT_GPG_HOME` pointing to a private GnuPG home containing the repository key.
3. Run `bash scripts/build-repository.sh` in Linux.
4. Run `bash scripts/verify-repository.sh`.
5. Commit the generated `pool/`, `dists/`, and `chowder-archive-keyring.gpg` files.

The included GitHub Pages workflow publishes the static repository after verification. Configure
the repository's Pages source as **GitHub Actions**.

## Ubuntu installation

When this repository is published as `advtuning/chowder-apt` with GitHub Pages enabled:

```bash
curl -fsSL https://advtuning.github.io/chowder-apt/install.sh | bash
```

The equivalent manual commands are:

```bash
curl -fsSL https://advtuning.github.io/chowder-apt/chowder-archive-keyring.gpg \
  | sudo tee /usr/share/keyrings/chowder-archive-keyring.gpg >/dev/null

echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/chowder-archive-keyring.gpg] https://advtuning.github.io/chowder-apt stable main" \
  | sudo tee /etc/apt/sources.list.d/chowder.list

sudo apt update
sudo apt install chowder
```

The Chowder package explicitly installs both `clamav` and `clamav-freshclam`, enables the ClamAV
signature updater, and performs a best-effort initial definition update. `clamav-daemon` is a
recommended dependency for faster daemon-backed scans, while `clamscan` remains the safe fallback.
