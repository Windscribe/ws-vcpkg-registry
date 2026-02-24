# vcpkg Custom Registry

Custom [vcpkg](https://github.com/microsoft/vcpkg) ports, triplets, and installation scripts for Windscribe.

## Ports

Overrides and additions to the official vcpkg registry. 

## Triplets

Custom triplets in the `triplets/` directory. All build **release-only** to reduce build times.

Includes triplets for: iOS, tvOS (device + simulator), macOS universal (`arm64+x86_64`), Linux and Windows static.

### How triplets are distributed

The installation scripts (`vcpkg_install.sh` / `vcpkg_install.bat`) automatically copy all `.cmake` files from `triplets/` into `<VCPKG_PATH>/custom_triplets/` every time they run. No manual copying is needed.

To use them in a project, set `VCPKG_OVERLAY_TRIPLETS` to the `custom_triplets` folder inside your vcpkg installation:

```cmake
set(VCPKG_OVERLAY_TRIPLETS "$ENV{VCPKG_ROOT}/custom_triplets")
```

Or via CMake preset:

```json
"VCPKG_OVERLAY_TRIPLETS": "$env{VCPKG_ROOT}/custom_triplets"
```

### After adding or updating a triplet

1. Commit and push the changes to this repository.
2. Re-run the installation script, it will copy the updated triplets to `<VCPKG_PATH>/custom_triplets/` automatically:

```bash
# Linux / macOS
./install-vcpkg/vcpkg_install.sh <VCPKG_PATH>

# Windows
install-vcpkg\vcpkg_install.bat <VCPKG_PATH>
```

## Installation Scripts

Scripts in `install-vcpkg/` install a pinned version of vcpkg. They skip reinstallation if the correct commit is already present.

### Quick start

Сlone the registry and run locally:

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

```bash
# Linux / macOS
./install-vcpkg/vcpkg_install.sh <VCPKG_PATH>

# Windows
install-vcpkg\vcpkg_install.bat <VCPKG_PATH>
```
