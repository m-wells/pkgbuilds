# Provenance & Checksum Policy

How this repository decides which upstream bytes it trusts — for every
package it builds into the `markwells-dev` pacman repository (the personal
channel consumed by the homelab machines).

This is the personal sibling of
[TwoWells/pkgbuilds](https://github.com/TwoWells/pkgbuilds)' PROVENANCE.md
— same principles, same machinery, different audience. Where that repo
distributes TwoWells products to the world, this one serves exactly the
maintainer's own machines.

## Principles

1. **Checksums are normative, not descriptive.** A pin states what the
   artifact _must_ be. When a downloaded artifact disagrees, the build
   fails (`scripts/lint.sh`) — a mismatch is a security signal to
   investigate, never something to re-hash. There is no auto-repair.
2. **Pins are written at bump time, from the most authoritative source
   available.** The update watcher writes the new version _and_ its
   checksum in the same commit, copying a published claim wherever one
   exists.
3. **No AUR reads in CI.** Every dependency this repo's builds need comes
   from the official repos, this repo itself, or a vendored package —
   python-pyngrok is vendored here for exactly that reason.

## Package inventory

Every package is Class 1 (published claim) or Class 1b (content-addressed)
— this repo carries no TOFU pins.

| Package                     | Upstream artifact       | Trust anchor                                                                    |
| --------------------------- | ----------------------- | -------------------------------------------------------------------------------- |
| keeper-commander            | PyPI sdist              | Class 1 — PyPI's published digest (+ tag-pinned LICENSE, static)                |
| keeper-secrets-manager-core | PyPI sdist              | Class 1 — PyPI's published digest                                               |
| nvidia-proprietary-dkms     | NVIDIA `.run` installer | Class 1 — sha512 claim from Arch's `nvidia-utils` packaging recipe (`.SRCINFO`) |
| perl-config-inifiles        | CPAN dist tarball       | Class 1 — MetaCPAN `checksum_sha256` (legacy sha512 pin converts at next bump)  |
| python-pyngrok              | PyPI sdist              | Class 1 — PyPI's published digest (+ tag-pinned LICENSE, static)                |
| sanoid                      | git repository          | Class 1b — commit pin resolved from the release tag                             |

Static LICENSE pins change only when the license text does; verification
then hard-fails until a human re-pins deliberately.

## Machinery map

- **Pinning** — `scripts/lib/common.sh`: `check_pypi` / `check_cpan`
  (registry digests), `check_github_release_pinned` (commit pins), and the
  Arch-recipe read in `scripts/packages/nvidia-proprietary-dkms.sh`. All
  pin paths verify their rewrite landed.
- **Verification** — `scripts/lint.sh` runs `makepkg --verifysource` for
  every package on every build; any mismatch fails the run.
- **Hygiene** — `.pre-commit-config.yaml`: `forbid-checksum-skip` rejects
  `SKIP` sums except for the excluded commit-pinned packages (sanoid).

## Adding a package

Same anchor ladder as the TwoWells repo: registry digest, then another
distro's reviewed pin, then a commit pin, then TOFU only with a documented
path out. Every new package gets an inventory row — and keeps this repo's
"no AUR reads in CI" property: if it needs an AUR-only dependency, vendor
that dependency here first.
