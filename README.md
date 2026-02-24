# vcpkg Custom Registry

Custom [vcpkg](https://github.com/microsoft/vcpkg) ports, triplets, and installation scripts for Windscribe.

## Ports

Overrides and additions to the official vcpkg registry. 

## Triplets

Custom triplets in the `triplets/` directory. All build **release-only** to reduce build times.

Includes triplets for: iOS, tvOS (device + simulator), macOS universal (`arm64+x86_64`), Linux and Windows static.

All triplet names are prefixed with `ws-` (e.g. `ws-arm64-osx`, `ws-x64-linux`) to avoid shadowing vcpkg's built-in triplets.

### How triplets are distributed

The installation scripts (`vcpkg_install.sh` / `vcpkg_install.bat`) automatically copy all `.cmake` files from `triplets/` into `<VCPKG_PATH>/triplets/` every time they run. No manual copying or `VCPKG_OVERLAY_TRIPLETS` configuration is needed.

### After adding or updating a triplet

1. Commit and push the changes to this repository.
2. Re-run the installation script, it will copy the updated triplets to `<VCPKG_PATH>/triplets/` automatically:

```bash
# Linux / macOS
./install-vcpkg/vcpkg_install.sh <VCPKG_PATH>

# Windows
install-vcpkg\vcpkg_install.bat <VCPKG_PATH>
```

## Installation Scripts

Scripts in `install-vcpkg/` install a pinned version of vcpkg. They skip reinstallation if the correct commit is already present.

### Quick start

Clone the registry and run locally:

```bash
git clone https://github.com/Windscribe/ws-vcpkg-registry.git
# Linux / macOS
./ws-vcpkg-registry/install-vcpkg/vcpkg_install.sh <VCPKG_PATH>
# Windows
ws-vcpkg-registry\install-vcpkg\vcpkg_install.bat <VCPKG_PATH>
```

After cloning, the following patches from `install-vcpkg/patches/` are automatically applied to vcpkg:

- **`vcpkg_configure_cmake.patch`** — passes correct `CMAKE_SYSTEM_NAME=tvOS` when building for `appletvos`/`appletvsimulator` sysroot
- **`ios_toolchain.patch`** — extends the iOS toolchain to set `CMAKE_SYSTEM_NAME=tvOS` for tvOS targets instead of `iOS`

### Updating the pinned vcpkg version

The pinned commit hash is stored in `install-vcpkg/vcpkg_commit.txt`. To update vcpkg to a newer version:

1. Pick a commit from [microsoft/vcpkg](https://github.com/microsoft/vcpkg) (e.g. the latest `main`):

```bash
git ls-remote https://github.com/microsoft/vcpkg refs/heads/master
```

2. Replace the hash in `install-vcpkg/vcpkg_commit.txt` with the new commit SHA.

3. **Verify the patches still apply cleanly.** The two patches in `install-vcpkg/patches/` are applied on top of the vcpkg source after cloning. If vcpkg changed the patched files, the patches may need to be rebased:

```bash
# Clone the new vcpkg commit manually and test
git clone https://github.com/microsoft/vcpkg.git /tmp/vcpkg-test
cd /tmp/vcpkg-test
git checkout <NEW_COMMIT>
git apply /path/to/ws-vcpkg-registry/install-vcpkg/patches/vcpkg_configure_cmake.patch
git apply /path/to/ws-vcpkg-registry/install-vcpkg/patches/ios_toolchain.patch
```

4. If a patch fails, update it to match the new vcpkg source, then commit both the new hash and the updated patch together.

5. Commit and push the changes. CI and local developers will automatically get the new vcpkg version the next time they run the installation script — the script detects the commit mismatch, removes the old installation, and reinstalls from scratch.
