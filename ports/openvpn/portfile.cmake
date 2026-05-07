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
    REF 8e9e91f4caff9a80961f32a1f9eda7e5a489176e
    SHA512 73e15cfb2d97dcc7eb64b58f9474353a0cdafd82853d169e5080b92af8f666a64b168e2730e9a704185ccb04f51fdb7369a266487c306fb9780dd54a05675d77
    PATCHES
        fix-cmakelist.patch
        anti-censorship.patch
        windows-static-openssl.patch
)

set(VCPKG_BUILD_TYPE release)

if(VCPKG_TARGET_IS_WINDOWS)
    # Windscribe: OpenVPN uses APIs deprecated/changed in OpenSSL 4.0
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
