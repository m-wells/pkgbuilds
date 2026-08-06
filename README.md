# pkgbuilds (personal)

[![Build packages](https://github.com/m-wells/pkgbuilds/actions/workflows/build.yml/badge.svg)](https://github.com/m-wells/pkgbuilds/actions/workflows/build.yml)
[![Check for Updates](https://github.com/m-wells/pkgbuilds/actions/workflows/watch.yml/badge.svg)](https://github.com/m-wells/pkgbuilds/actions/workflows/watch.yml)

Personal Arch Linux packages with automated builds and version tracking,
published as the `[markwells-dev]` pacman repository. These packages exist
to serve my own machines (see the homelab ansible roles that consume them);
they are not published to the AUR.

TwoWells **product** packages (catenary, lattice, themis) live in
[TwoWells/pkgbuilds](https://github.com/TwoWells/pkgbuilds), which publishes
the `[twowells]` repository and the AUR packages. The two repos split in
2026-08; this one inherited the `markwells-dev` name.

## Usage

```bash
# Import the maintainer's signing key
sudo pacman-key --keyserver keys.openpgp.org --recv-keys ED9FEE0BB96D6A5E
sudo pacman-key --lsign-key ED9FEE0BB96D6A5E

# Add to /etc/pacman.conf (before [core] for priority over official packages)
[markwells-dev]
SigLevel = Required DatabaseOptional
Server = https://github.com/m-wells/pkgbuilds/releases/latest/download

# Sync and install
sudo pacman -Sy
sudo pacman -S <package-name>
```

## Trust policy

See [PROVENANCE.md](PROVENANCE.md) — every checksum is pinned from a
published claim (or a git commit), a mismatch hard-fails the build, and CI
never reads from the AUR.

## Local workflow

A `Makefile` wraps the common flows (`make help` for the list):

```bash
make build PKG=sanoid       # makepkg -sf
make test PKG=sanoid        # build, then run check.sh smoke test
make checksums PKG=sanoid   # updpkgsums (local/dev only — see PROVENANCE.md)
make srcinfo PKG=sanoid     # regenerate .SRCINFO
```

Each package directory carries a `.local` marker (build + publish to the
pacman repo) and optionally a `check.sh` smoke test.
