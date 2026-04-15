set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

# workaround for universal Mac OS architecture, otherwise configure error
list(LENGTH VCPKG_OSX_ARCHITECTURES osx_archs_num)
if(VCPKG_TARGET_IS_OSX)
    if(HOST_TRIPLET MATCHES "arm64*")
        set(VCPKG_OSX_ARCHITECTURES "arm64")
    else()
        set(VCPKG_OSX_ARCHITECTURES "x86_64")
    endif()
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OpenVPN/openvpn
    REF 5c4e4c08679c6c754928d4f6c31ab6180b3cff3d
    SHA512 7d1006ff8a6d37aa15ff4ce1d625699404e326651b07c58b7fd707c1d69504d2890c319510c08b2e27e2a5f7d62e688602670c0b9a3a60701b36872fc40073a0
    PATCHES
        fix-cmakelist.patch
        anti-censorship.patch
        windows-static-openssl.patch
)

set(VCPKG_BUILD_TYPE release)

if(VCPKG_TARGET_IS_WINDOWS)
    # Windscribe: OpenVPN 2.7.1 uses APIs deprecated/changed in OpenSSL 4.0
    # (X509_cmp_time, non-const X509_NAME returns). Suppress until upstream updates.
    vcpkg_configure_cmake(
      SOURCE_PATH "${SOURCE_PATH}"
      OPTIONS
        -DENABLE_PKCS11=OFF
        -DBUILD_TESTING=OFF
        -DPKG_CONFIG_EXECUTABLE="${CURRENT_HOST_INSTALLED_DIR}/tools/pkgconf/pkgconf"
        "-DCMAKE_C_FLAGS=/wd4996 /wd4090"
    )
        vcpkg_install_cmake()
else()
    set(ENV{CFLAGS} "$ENV{CFLAGS} -I${CURRENT_HOST_INSTALLED_DIR}/include")
    set(ENV{CPPFLAGS} "$ENV{CPPFLAGS} -I${CURRENT_HOST_INSTALLED_DIR}/include")
    if(VCPKG_TARGET_IS_OSX)
        set(ENV{LDFLAGS} "$ENV{LDFLAGS} -headerpad_max_install_names -L${CURRENT_HOST_INSTALLED_DIR}/lib")
    else()
        set(ENV{LDFLAGS} "$ENV{LDFLAGS}")
    endif()

    vcpkg_list(SET CONFIGURE_OPTIONS
        "--with-crypto-library=openssl"
        "OPENSSL_CFLAGS=-I${CURRENT_HOST_INSTALLED_DIR}/include"
        "OPENSSL_LIBS=-L${CURRENT_HOST_INSTALLED_DIR}/lib -lssl -lcrypto"
        "--disable-plugin-auth-pam"
        "--disable-plugin-down-root"
    )

    # Universal OSX architecture
    if(VCPKG_TARGET_IS_OSX AND osx_archs_num GREATER_EQUAL 2)
        vcpkg_list(APPEND CONFIGURE_OPTIONS "CFLAGS=-arch x86_64 -arch arm64 -mmacosx-version-min=10.14")
    endif()

    vcpkg_configure_make(
      SOURCE_PATH "${SOURCE_PATH}"
          AUTOCONFIG
      OPTIONS
        ${CONFIGURE_OPTIONS}
    )
        vcpkg_install_make(INSTALL_TARGET "install-exec")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")

if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_copy_tools(TOOL_NAMES openvpn AUTO_CLEAN)
endif()

file(
  INSTALL "${SOURCE_PATH}/COPYRIGHT.GPL"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright)
