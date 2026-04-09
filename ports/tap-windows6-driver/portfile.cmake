set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/OpenVPN/tap-windows6/releases/download/${VERSION}/dist.win10.zip"
    FILENAME "tap-windows6-${VERSION}-dist.win10.zip"
    SKIP_SHA512
)

vcpkg_extract_source_archive(SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
)

if(VCPKG_TARGET_ARCHITECTURE MATCHES "x64")
    set(DRIVER_ARCH "amd64")
elseif(VCPKG_TARGET_ARCHITECTURE MATCHES "arm64")
    set(DRIVER_ARCH "arm64")
else()
    message(FATAL_ERROR "Unsupported architecture for tap-windows6 driver.")
endif()

file(INSTALL
    "${SOURCE_PATH}/${DRIVER_ARCH}/tap0901.sys"
    "${SOURCE_PATH}/${DRIVER_ARCH}/OemVista.inf"
    "${SOURCE_PATH}/${DRIVER_ARCH}/tap0901.cat"
    DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
)

vcpkg_download_distfile(LICENSE_PATH
    URLS "https://raw.githubusercontent.com/OpenVPN/tap-windows6/master/COPYRIGHT.GPL"
    FILENAME "tap-windows6-COPYRIGHT.GPL"
    SKIP_SHA512
)

file(INSTALL "${LICENSE_PATH}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
