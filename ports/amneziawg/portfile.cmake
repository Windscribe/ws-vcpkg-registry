set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

# Windows and POSIX are released separately, so each platform pins its own upstream tag.
if(VCPKG_TARGET_IS_WINDOWS)
    # v3.1.20260814
    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO amnezia-vpn/amneziawg-windows
        REF e90531d15802cb976773f3b63443bc281f738ca3
        SHA512 eec0cca99b87182dac1c719f8eb5de68069d1690e0ef64c9afea1db6602d15bd83b77a4a9a879f87bcb879e1d17fd02e0de34e76fea8e9e5ec8e87a623ab23b1
        PATCHES
            # The DLL is built from the repo root, a trimmed fork that neither applies the config's DNS nor binds
            # the tunnel socket to the physical default route (which loops handshakes into the tunnel when
            # AllowedIPs is 0.0.0.0/0). The full implementations live in the tunnel/ package.
            0001-use-full-tunnel-sources.patch
            # The ring log location must not depend on the product name baked into the DLL, so the caller passes it.
            0002-preset-root-directory.patch
    )
else()
    # v3.1.20260828
    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO amnezia-vpn/amneziawg-go
        REF b5928efb6ca19f0153958460c3d141f04abc5c2e
        SHA512 99cbfaa81d84aeeff658295112adfe500d00f5154a04944658754c6c83bb29896c9c0cdafc18921174fae015475005e68c2878afd78627f7885c7003b101a8fa
    )
    # Upstream Makefile derives this from `git describe`, which a source tarball cannot provide.
    file(WRITE "${SOURCE_PATH}/version.go" "package main\n\nconst Version = \"v3.1.20260828\"\n")
endif()

vcpkg_find_acquire_program(GO)
cmake_path(GET GO PARENT_PATH GO_BIN_DIR)
vcpkg_add_to_path(PREPEND "${GO_BIN_DIR}")

set(GO_WORK_DIR "${CURRENT_BUILDTREES_DIR}/go")
set(ENV{GOPATH} "${GO_WORK_DIR}/path")
set(ENV{GOMODCACHE} "${GO_WORK_DIR}/modcache")
set(ENV{GOCACHE} "${GO_WORK_DIR}/cache")
set(ENV{GOTOOLCHAIN} local)
# -modcacherw keeps the module cache deletable when vcpkg cleans buildtrees.
# -buildvcs=false because buildtrees sit inside the vcpkg git checkout.
set(ENV{GOFLAGS} "-mod=readonly -modcacherw -buildvcs=false")

set(OUT_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")
file(REMOVE_RECURSE "${OUT_DIR}")

if(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(GOARCH amd64)
        set(MINGW_TRIPLE x86_64-w64-mingw32)
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(GOARCH arm64)
        set(MINGW_TRIPLE aarch64-w64-mingw32)
    else()
        message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
    endif()

    vcpkg_download_distfile(LLVM_MINGW_ARCHIVE
        URLS "https://github.com/mstorsjo/llvm-mingw/releases/download/20260127/llvm-mingw-20260127-msvcrt-x86_64.zip"
        FILENAME "llvm-mingw-20260127-msvcrt-x86_64.zip"
        SHA512 fa0cced3fd702759ddde6f5ea0332567677a579777541c4462265310d2f1fdda51786e393257076c929ab52ca17856a506e0a87b891dcd45329cdee1cf086ede
    )
    vcpkg_extract_source_archive(LLVM_MINGW_ROOT ARCHIVE "${LLVM_MINGW_ARCHIVE}")
    vcpkg_add_to_path(PREPEND "${LLVM_MINGW_ROOT}/bin")

    set(ENV{GOOS} windows)
    set(ENV{GOARCH} ${GOARCH})
    set(ENV{CGO_ENABLED} 1)
    set(ENV{CC} ${MINGW_TRIPLE}-gcc)
    set(ENV{CGO_CFLAGS} "-O3 -Wall -Wno-unused-function -Wno-switch -std=gnu11 -DWINVER=0x0601")
    set(ENV{CGO_LDFLAGS} "-Wl,--dynamicbase -Wl,--nxcompat -Wl,--export-all-symbols -Wl,--high-entropy-va")

    vcpkg_execute_build_process(
        COMMAND "${GO}" build -buildmode c-shared -trimpath "-ldflags=-w -s" -o "${OUT_DIR}/amneziawgtunnel.dll"
        WORKING_DIRECTORY "${SOURCE_PATH}"
        LOGNAME "build-${TARGET_TRIPLET}"
    )
    file(INSTALL "${OUT_DIR}/amneziawgtunnel.dll" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    # amneziawg-windows has no LICENSE file; the MIT text lives in its README.
    vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/README.md")
else()
    if(VCPKG_TARGET_IS_OSX)
        set(ENV{GOOS} darwin)
    else()
        set(ENV{GOOS} linux)
    endif()

    # ws-universal-osx lists several architectures; each is built separately and merged with lipo.
    set(ARCH_BINARIES "")
    foreach(arch IN LISTS VCPKG_TARGET_ARCHITECTURE)
        if(arch MATCHES "^(x64|x86_64)$")
            set(GOARCH amd64)
        elseif(arch STREQUAL "arm64")
            set(GOARCH arm64)
        else()
            message(FATAL_ERROR "Unsupported architecture: ${arch}")
        endif()
        set(ENV{GOARCH} ${GOARCH})
        vcpkg_execute_build_process(
            COMMAND "${GO}" build -trimpath "-ldflags=-w -s" -o "${OUT_DIR}/${GOARCH}/amneziawg-go"
            WORKING_DIRECTORY "${SOURCE_PATH}"
            LOGNAME "build-${TARGET_TRIPLET}-${GOARCH}"
        )
        list(APPEND ARCH_BINARIES "${OUT_DIR}/${GOARCH}/amneziawg-go")
    endforeach()

    set(BINARY "${OUT_DIR}/amneziawg-go")
    if(VCPKG_TARGET_IS_OSX)
        vcpkg_execute_build_process(
            COMMAND lipo -create ${ARCH_BINARIES} -output "${BINARY}"
            WORKING_DIRECTORY "${OUT_DIR}"
            LOGNAME "lipo-${TARGET_TRIPLET}"
        )
        set(STRIP_FLAGS -ur)
    else()
        file(COPY_FILE "${ARCH_BINARIES}" "${BINARY}")
        set(STRIP_FLAGS --strip-all)
    endif()
    vcpkg_execute_build_process(
        COMMAND strip ${STRIP_FLAGS} "${BINARY}"
        WORKING_DIRECTORY "${OUT_DIR}"
        LOGNAME "strip-${TARGET_TRIPLET}"
    )

    file(INSTALL "${BINARY}" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
         FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
endif()
