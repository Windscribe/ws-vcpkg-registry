#!/bin/bash

# This script installs vcpkg to the home directory if that directory does not already exist.
VCPKG_PATH="$HOME/vcpkg"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
    echo The path parameter VCPKG_PATH is not set.
    echo "Usage: vcpkg_install.sh <VCPKG_PATH> [--configure-git]"
    exit 1
fi

if [ "$2" = "--configure-git" ]; then
    echo "Configure git config for vcpkg"
    #remove previous config if found
    OUTPUT=$(git config --list | grep "insteadof=git@gitlab.int.windscribe.com" | sed "s/.insteadof=git@gitlab.int.windscribe.com.*//")
    while read line
    do
        echo "Remove previous git config for vcpkg: $line"
        git config --global --remove-section "$line"
    done < <(echo "$OUTPUT")
    git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.int.windscribe.com/".insteadOf "git@gitlab.int.windscribe.com:"
fi

VCPKG_COMMIT=$(tr -d '[:space:]' < "$SCRIPT_DIR/vcpkg_commit.txt")

NEEDS_INSTALL=0
if [ -d "$1" ] && [ -f "$1/vcpkg" ]; then
    CURRENT_COMMIT=$(git -C "$1" rev-parse HEAD 2>/dev/null)
    if [ "$CURRENT_COMMIT" = "$VCPKG_COMMIT" ]; then
        echo "vcpkg is installed and up to date"
        "$1"/vcpkg version
    else
        echo "vcpkg commit mismatch: expected $VCPKG_COMMIT, got $CURRENT_COMMIT"
        NEEDS_INSTALL=1
    fi
else
    echo "vcpkg is not installed"
    NEEDS_INSTALL=1
fi

apply_patches() {
    local vcpkg_dir="$1"
    local patches_dir="$SCRIPT_DIR/patches"
    echo "Applying custom patches to vcpkg..."
    git -C "$vcpkg_dir" apply "$patches_dir/vcpkg_configure_cmake.patch"
    git -C "$vcpkg_dir" apply "$patches_dir/ios_toolchain.patch"
}

if [ "$NEEDS_INSTALL" = "1" ]; then
    echo "Installing vcpkg at commit $VCPKG_COMMIT to $1"
    rm -rf "${1}"
    mkdir -p "${1}"
    pushd "${1}" > /dev/null
    git clone https://github.com/Microsoft/vcpkg.git .
    git checkout "$VCPKG_COMMIT"
    popd > /dev/null
    apply_patches "${1}"
    pushd "${1}" > /dev/null
    ./bootstrap-vcpkg.sh --disableMetrics
    popd > /dev/null
fi

TRIPLETS_SRC="$SCRIPT_DIR/../triplets"
TRIPLETS_DST="$1/triplets"
echo "Copying custom triplets to $TRIPLETS_DST..."
cp -f "$TRIPLETS_SRC"/*.cmake "$TRIPLETS_DST/"
