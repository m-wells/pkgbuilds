#!/bin/bash

check_python_click_repl() {
    local pkg_name="python-click-repl"
    local pypi_name="click-repl"
    echo "Checking $pkg_name via PyPI..."

    local latest_ver=$(curl -s "https://pypi.org/pypi/${pypi_name}/json" | jq -r .info.version)

    if [ -n "$latest_ver" ] && [ "$latest_ver" != "null" ]; then
        perform_update "$pkg_name" "$latest_ver"
    else
        echo "Failed to check version for $pkg_name"
    fi
}

check_python_click_repl
