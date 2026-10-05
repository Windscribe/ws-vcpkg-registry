set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_download_distfile(SOURCE_ARCHIVE
    URLS "https://git.zx2c4.com/wireguard-windows/snapshot/wireguard-windows-${VERSION}.zip"
    FILENAME "wireguard-windows-${VERSION}.zip"
    SHA512 f567b6fe5e8087d484bed675d4ebe1f3990b5c0d52f373b63ed01bccee90ac401882e02428e702e275712eed630fe6207b9e8e85f5781048fe5558f0f1ad862a
)
vcpkg_extract_source_archive(SOURCE_PATH ARCHIVE "${SOURCE_ARCHIVE}")

# The toolchain and wireguard-nt versions are the ones pinned by upstream build.bat.
# Upstream ships its own patched Go build, so vcpkg_find_acquire_program(GO) is not a substitute.
vcpkg_download_distfile(GO_ARCHIVE
    URLS "https://download.wireguard.com/windows-toolchain/distfiles/go1.26.2-windows_amd64_2026-04-20.zip"
    FILENAME "wireguard-go1.26.2-windows_amd64_2026-04-20.zip"
    SHA512 340db4b26bfa74ccf39ae5ad580d5c278c6295ad2c458e77b6ec26185ee2a484cc76daca36ac9daf0f8bac3bb4fd45a6c242eab53da35ccbe9d5de42a854c59c
)
vcpkg_download_distfile(LLVM_MINGW_ARCHIVE
    URLS "https://download.wireguard.com/windows-toolchain/distfiles/llvm-mingw-20260311-ucrt-x86_64.zip"
    FILENAME "llvm-mingw-20260311-ucrt-x86_64.zip"
    SHA512 31446fc3b0f02689ec7925beb8180ee1a698224046c6a90b57ce2c2a4585c084b3db472a8d01e1280d7d1f92b04c17e22ed4db5495fc60c6fc88f05a3f3d98cd
)
vcpkg_download_distfile(WIREGUARD_NT_ARCHIVE
    URLS "https://download.wireguard.com/wireguard-nt/wireguard-nt-1.1.zip"
    FILENAME "wireguard-nt-1.1.zip"
    SHA512 09787dce06d2c905459ec49ac6caa87fa0cf02286f4a6a802c154b32b276dc7b47faa0f28e634c2aa5c3675c37e8c34f3f712fb89ada3dd97f63f19340b83a92
)
vcpkg_extract_source_archive(GO_ROOT ARCHIVE "${GO_ARCHIVE}")
vcpkg_extract_source_archive(LLVM_MINGW_ROOT ARCHIVE "${LLVM_MINGW_ARCHIVE}")
vcpkg_extract_source_archive(WIREGUARD_NT_ROOT ARCHIVE "${WIREGUARD_NT_ARCHIVE}")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(GOARCH amd64)
    set(MINGW_TRIPLE x86_64-w64-mingw32)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(GOARCH arm64)
    set(MINGW_TRIPLE aarch64-w64-mingw32)
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

find_program(GO NAMES go PATHS "${GO_ROOT}/bin" NO_DEFAULT_PATH REQUIRED)
find_program(WINDRES NAMES ${MINGW_TRIPLE}-windres PATHS "${LLVM_MINGW_ROOT}/bin" NO_DEFAULT_PATH REQUIRED)
vcpkg_add_to_path(PREPEND "${LLVM_MINGW_ROOT}/bin")

set(GO_WORK_DIR "${CURRENT_BUILDTREES_DIR}/go")
set(ENV{GOROOT} "${GO_ROOT}")
set(ENV{GOPATH} "${GO_WORK_DIR}/path")
set(ENV{GOMODCACHE} "${GO_WORK_DIR}/modcache")
set(ENV{GOCACHE} "${GO_WORK_DIR}/cache")
set(ENV{GOTOOLCHAIN} local)
# -modcacherw keeps the module cache deletable when vcpkg cleans buildtrees.
# -buildvcs=false because buildtrees sit inside the vcpkg git checkout.
set(ENV{GOFLAGS} "-mod=readonly -modcacherw -buildvcs=false")
set(ENV{GOOS} windows)
set(ENV{GOARCH} ${GOARCH})
set(ENV{CGO_ENABLED} 1)
set(ENV{CC} ${MINGW_TRIPLE}-gcc)
set(ENV{CGO_CFLAGS} "-O3 -Wall -Wno-unused-function -Wno-switch -std=gnu11 -DWINVER=0x0A00")

set(DLL_SERVICE_DIR "${SOURCE_PATH}/embeddable-dll-service")
set(OUT_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")
file(REMOVE_RECURSE "${OUT_DIR}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/version_info.rc" DESTINATION "${DLL_SERVICE_DIR}")

vcpkg_execute_build_process(
    COMMAND "${WINDRES}" -i version_info.rc -O coff -o version_info.syso
    WORKING_DIRECTORY "${DLL_SERVICE_DIR}"
    LOGNAME "windres-${TARGET_TRIPLET}"
)
vcpkg_execute_build_process(
    COMMAND "${GO}" build -buildmode c-shared -trimpath "-ldflags=-w -s" -o "${OUT_DIR}/tunnel.dll"
    WORKING_DIRECTORY "${DLL_SERVICE_DIR}"
    LOGNAME "build-${TARGET_TRIPLET}"
)

file(INSTALL
    "${OUT_DIR}/tunnel.dll"
    "${WIREGUARD_NT_ROOT}/bin/${GOARCH}/wireguard.dll"
    DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING" "${WIREGUARD_NT_ROOT}/LICENSE.txt")
