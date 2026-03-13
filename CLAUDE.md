# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A custom [vcpkg](https://github.com/microsoft/vcpkg) registry for Windscribe. It contains:
- **`ports/`** — Port overrides and additions to the official vcpkg registry (16 ports)
- **`triplets/`** — Custom build triplets, all prefixed `ws-`, all release-only
- **`install-vcpkg/`** — Scripts that pin, patch, and install a specific vcpkg commit
- **`versions/`** — vcpkg versioning database (baseline + per-port version history)

## Installation

```bash
# Linux / macOS
./install-vcpkg/vcpkg_install.sh <VCPKG_PATH>

# Windows
install-vcpkg\vcpkg_install.bat <VCPKG_PATH>
```

The scripts detect the current vcpkg commit via `install-vcpkg/vcpkg_commit.txt`, reinstall if there's a mismatch, apply two patches from `install-vcpkg/patches/`, and copy all triplets into `<VCPKG_PATH>/triplets/`.

## Port Structure

Each port under `ports/<name>/` contains:
- `vcpkg.json` — Metadata: name, version, port-version, description, dependencies, features
- `portfile.cmake` — Build instructions: download, configure, install
- `usage` (optional) — CMake usage example for consumers
- `*.patch` / `*.diff` — Patches applied during build
- `unix/`, `windows/` directories — Platform-specific files when needed

## Versioning

When updating a port's version:

1. Update `ports/<name>/vcpkg.json` with the new `version` (and reset or increment `port-version`)
2. Update `versions/baseline.json` to reflect the new baseline version
3. Update `versions/<first-letter>-/<portname>.json` with a new entry including the `git-tree` hash

The `git-tree` hash is the SHA of the `ports/<name>/` directory tree object in git:
```bash
git rev-parse HEAD:ports/<name>
```

Increment `port-version` (without changing `version`) when the port behavior changes but the upstream version does not (e.g., patch changes, portfile fixes).

## Triplets

All custom triplets are named `ws-<arch>-<platform>[.cmake]` and live in `triplets/`. Key properties:
- All set `VCPKG_BUILD_TYPE release` (release-only builds)
- All set `VCPKG_LIBRARY_LINKAGE static`
- Android triplets use `VCPKG_CMAKE_CONFIGURE_OPTIONS` for ABI selection
- `ws-universal-osx.cmake` sets `VCPKG_TARGET_ARCHITECTURE "arm64;x86_64"` for fat binaries

After adding or modifying a triplet, re-run the install script to copy it into vcpkg.

## Updating the Pinned vcpkg Version

1. Update the commit SHA in `install-vcpkg/vcpkg_commit.txt`
2. Verify both patches in `install-vcpkg/patches/` still apply cleanly against the new commit
3. If a patch fails, rebase it against the new vcpkg source and commit the updated patch alongside the new hash

## Patches Applied to vcpkg

- **`vcpkg_configure_cmake.patch`** — Passes `CMAKE_SYSTEM_NAME=tvOS` when building for `appletvos`/`appletvsimulator`
- **`ios_toolchain.patch`** — Extends the iOS toolchain to set `CMAKE_SYSTEM_NAME=tvOS` for tvOS targets
