#!/bin/bash

# Track Arch's nvidia-open-dkms, and copy the source tarball's sha512 from
# Arch's recipe for it (pkgbase nvidia-utils), as nvidia-proprietary-dkms.sh
# does for the .run. Only the first checksum (the tarball) is rewritten: the
# second pins this repo's own patch and stays. A bump whose source the patch
# no longer applies to fails the build (--fuzz=0), and the published package
# keeps its nvidia-utils pin until a human refreshes the patch.
echo "Checking nvidia-open-dkms-pmstate via Arch repos (nvidia-open-dkms)..."

_json=$(curl -s "https://archlinux.org/packages/extra/x86_64/nvidia-open-dkms/json/")
latest_ver=$(printf '%s' "$_json" | jq -r .pkgver)
latest_rel=$(printf '%s' "$_json" | jq -r .pkgrel)
_base=$(printf '%s' "$_json" | jq -r .pkgbase)

if [ -z "$latest_ver" ] || [ "$latest_ver" == "null" ] || [ -z "$_base" ] || [ "$_base" == "null" ]; then
    echo "Failed to check version for nvidia-open-dkms-pmstate"
else
    _clone=$(mktemp -d)
    if git clone --quiet --depth 1 --branch "${latest_ver}-${latest_rel}" \
        "https://gitlab.archlinux.org/archlinux/packaging/packages/${_base}.git" \
        "$_clone" 2> /dev/null; then
        # .SRCINFO lists the pkgbase's sources and their sums in the same
        # order; take the sum at the tarball's position.
        sum=$(awk -v want="/NVIDIA-kernel-module-source-${latest_ver}.tar.xz" '
            /^\tsource = /     { src[++n] = $3 }
            /^\tsha512sums = / { sha[++m] = $3 }
            END {
                for (i = 1; i <= n; i++)
                    if (substr(src[i], length(src[i]) - length(want) + 1) == want)
                        print sha[i]
            }' "$_clone/.SRCINFO")
        if [[ "$sum" =~ ^[0-9a-f]{128}$ ]]; then
            UPDATE_PIN_SUMS="$(pin_first_checksum "$REPO_ROOT/pkgs/nvidia-open-dkms-pmstate/PKGBUILD" "$sum")" \
                perform_update "nvidia-open-dkms-pmstate" "$latest_ver"
        else
            echo "::error::Arch .SRCINFO for ${_base} ${latest_ver}-${latest_rel} did not yield one sha512 for the kernel-module source tarball — skipping bump"
        fi
    else
        echo "::error::Failed to clone Arch packaging repo ${_base} at tag ${latest_ver}-${latest_rel} — skipping bump"
    fi
    rm -rf "$_clone"
fi
