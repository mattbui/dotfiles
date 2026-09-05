#!/usr/bin/env bash

main() {
    local source_dir destination temporary
    source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || return 1
    destination="$HOME/.local/bin"
    mkdir -p "$destination" || return 1
    temporary="$(mktemp -d "${TMPDIR:-/tmp}/center-mouse.XXXXXX")" || return 1

    # Compile before replacing the installed helper, so build failures leave it usable.
    if ! /usr/bin/xcrun swiftc -O "$source_dir/center-mouse.swift" \
        -o "$temporary/center-mouse"; then
        printf 'Failed to compile center-mouse. Check the Xcode Command Line Tools.\n' >&2
        rm -rf "$temporary"
        return 1
    fi
    if ! /usr/bin/install -m 755 "$temporary/center-mouse" "$destination/center-mouse"; then
        rm -rf "$temporary"
        return 1
    fi
    rm -rf "$temporary"
    printf 'Installed %s/center-mouse\n' "$destination"
}

main "$@"
