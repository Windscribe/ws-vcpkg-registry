if(NOT VCPKG_TARGET_IS_LINUX)
    message(FATAL_ERROR "strongswan: this port is Linux-only")
endif()

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
set(VCPKG_BUILD_TYPE release)

vcpkg_download_distfile(ARCHIVE
    URLS "https://download.strongswan.org/strongswan-${VERSION}.tar.bz2"
    FILENAME "strongswan-${VERSION}.tar.bz2"
    SHA512 01cea929cea2535751b5ef23eddc780a3c32ffafee640a6d5cea9a52798d0ec7030107463e8ddcc73fd0924b378a8676942297a42d79319207ecf7716badcb5f
)

vcpkg_extract_source_archive(SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        pid-file-option.patch
)

set(UNUSED_DIR "/dev/null/strongswan")

vcpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        "--with-piddir=${UNUSED_DIR}/run"
        "--with-strongswan-conf=${UNUSED_DIR}/etc/strongswan.conf"
        "--sysconfdir=${UNUSED_DIR}/etc"
        "--libexecdir=${UNUSED_DIR}/lib"
        "--with-ipsecdir=${UNUSED_DIR}/lib"
        "--with-ipseclibdir=${UNUSED_DIR}/lib"
        "--with-plugindir=${UNUSED_DIR}/lib/plugins"
        "--with-imcvdir=${UNUSED_DIR}/lib/imcvs"
        "--with-random-device=/dev/random"
        "--with-urandom-device=/dev/urandom"
        --with-capabilities=native
        --enable-monolithic
        --disable-defaults
        --enable-charon
        --enable-ikev2
        --enable-openssl
        --enable-random
        --enable-nonce
        --enable-x509
        --enable-constraints
        --enable-pem
        --enable-pkcs1
        --enable-kernel-netlink
        --enable-socket-default
        --enable-vici
        --enable-updown
        --enable-eap-identity
        --enable-eap-mschapv2
        --enable-md4
        --enable-des
        --disable-integrity-test
        --disable-load-warning
)

vcpkg_build_make()

set(BUILD_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
file(INSTALL "${BUILD_DIR}/src/charon/charon"
     DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
     FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

file(STRINGS "${CURRENT_PACKAGES_DIR}/tools/${PORT}/charon" LEAKED_PATHS
     REGEX "${CURRENT_BUILDTREES_DIR}|${CURRENT_PACKAGES_DIR}|${CURRENT_INSTALLED_DIR}|${SOURCE_PATH}")
if(LEAKED_PATHS)
    list(JOIN LEAKED_PATHS "\n  " LEAKED_PATHS_TEXT)
    message(FATAL_ERROR "strongswan: charon contains build paths:\n  ${LEAKED_PATHS_TEXT}")
endif()

file(STRINGS "${CURRENT_PACKAGES_DIR}/tools/${PORT}/charon" BRANDED_STRINGS REGEX "[Ww][Ii][Nn][Dd][Ss][Cc][Rr][Ii][Bb][Ee]")
if(BRANDED_STRINGS)
    list(JOIN BRANDED_STRINGS "\n  " BRANDED_STRINGS_TEXT)
    message(FATAL_ERROR "strongswan: charon contains product-specific strings:\n  ${BRANDED_STRINGS_TEXT}")
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE" "${SOURCE_PATH}/COPYING")
