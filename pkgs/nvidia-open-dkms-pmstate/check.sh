#!/bin/bash
set -euo pipefail
PKG_FILE="$1"

# Compile the DKMS source this package ships, as dkms.conf's MAKE line would,
# against the newest installed linux-headers, and confirm the patch's procfs
# lines made it into nvidia.ko. The package is not installed: its pacman
# hook would run dkms against whatever kernels the build host has.
echo "Testing nvidia-open-dkms-pmstate..."

if ! compgen -G "/usr/lib/modules/*/build/Makefile" > /dev/null; then
    sudo pacman -S --noconfirm --needed linux-headers
fi
kbuild=$(printf '%s\n' /usr/lib/modules/*/build/Makefile | sort -V | tail -n1)
kbuild=${kbuild%/Makefile}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
bsdtar -xf "$PKG_FILE" -C "$work" usr/src
src=$(printf '%s\n' "$work"/usr/src/nvidia-*)

grep -q '^BUILT_MODULE_LOCATION\[0\]="kernel-open"$' "$src/dkms.conf" || {
    echo "Error: dkms.conf missing or not filled in"
    exit 1
}

echo "==> Building against $kbuild"
make -C "$src" -j"$(nproc)" modules SYSSRC="$kbuild" \
    IGNORE_PREEMPT_RT_PRESENCE=1 NV_EXCLUDE_BUILD_MODULES='' > "$work/build.log" 2>&1 || {
    tail -n 50 "$work/build.log"
    echo "Error: module build failed"
    exit 1
}

for line in 'Dynamic Power Management:' ' Last Idle Check:           %s, %llu ms ago'; do
    if grep -qaF -- "$line" "$src/kernel-open/nvidia.ko"; then
        echo "nvidia.ko has: $line"
    else
        echo "Error: nvidia.ko lacks '$line' (patch not applied?)"
        exit 1
    fi
done

# kthread-init-fs-sysfs-config.patch compiles in only where the kernel exports
# userspace_init_fs (Linux 7.3+). Where it does, nvidia.ko imports the symbol;
# its absence there means the conftest missed it and runtime D3 stays broken.
if grep -q '\buserspace_init_fs\b' "$kbuild/Module.symvers"; then
    if grep -qaF -- 'userspace_init_fs' "$src/kernel-open/nvidia.ko"; then
        echo "nvidia.ko imports userspace_init_fs (7.3 sysfs-config fix compiled in)"
    else
        echo "Error: $kbuild exports userspace_init_fs but nvidia.ko does not use it"
        exit 1
    fi
else
    echo "Skipping the 7.3 sysfs-config check: $kbuild predates userspace_init_fs"
fi
