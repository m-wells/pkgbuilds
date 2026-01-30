#!/bin/bash

check_keeper_commander() {
    local pkg_name="keeper-commander"
    local pypi_name="keepercommander"
    echo "Checking $pkg_name via PyPI..."

    # Get latest version from PyPI JSON API
    local latest_ver=$(curl -s "https://pypi.org/pypi/${pypi_name}/json" | jq -r .info.version)

    if [ -n "$latest_ver" ] && [ "$latest_ver" != "null" ]; then
        perform_update "$pkg_name" "$latest_ver"
    else
        echo "Failed to check version for $pkg_name"
    fi
}

check_keeper_commander
