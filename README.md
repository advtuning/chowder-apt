# Chowder APT repository

Static, signed Ubuntu/Debian package repository for the ChowderAV desktop GUI by Clarity Soft.

The prepared `0.1.4-test` packages are evaluation builds, not production
releases. The public landing page is generated from `index.html`.

The live repository is published through GitHub Pages. It exposes
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

Install Chowder `0.1.4-test` on supported Debian/Ubuntu amd64 or arm64 systems:

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

Published package SHA-256 values:

```text
045f945675ba496a1ac153c29da7a77f9894ac2fee522f9b78fa9a09e7d64832  chowder_0.1.4-test_amd64.deb
6cc0efcb133f2fcf2c0c9b3e2225014e5018a2f89cec02991a3f279f82b81376  chowder_0.1.4-test_arm64.deb
```

These are test packages. Repository metadata is signed, but the builds are not production releases.
Publication does not claim completion of every native desktop or physical arm64 release gate.
