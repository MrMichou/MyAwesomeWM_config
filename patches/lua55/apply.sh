#!/bin/sh
# Re-applies the Lua 5.5 / lgi-git compatibility fixes to the third-party
# submodules (their upstreams do not carry them). Safe to run repeatedly.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)

apply() { # <submodule path> <patch file>
    dir="$root/$1"; patch="$here/$2"
    if git -C "$dir" apply --reverse --check "$patch" 2>/dev/null; then
        echo "already applied: $2"
    else
        git -C "$dir" apply "$patch"
        echo "applied: $2"
    fi
}

apply module/bling  bling.patch
apply module/rubato rubato.patch
