# Windows installs include/openvpn-msg.h for the helper's --msg-channel ABI. Other
# platforms still ship only the daemon binary.
if(NOT VCPKG_TARGET_IS_WINDOWS)
    set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
endif()

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
    REF 85f07f7b784009adf90129b3854c5b742ca3cef9
    SHA512 edbce6149c6429f6c33a8e5ad9c376b45dac884f7a9a8393a949a1baebeb827f4c2bc39ff450b2fa47fe971bc637c04a21017d2ad78d70e38f0591871f9e02b3
    PATCHES
        fix-cmakelist.patch
        anti-censorship.patch
        0002-Anti-censorship-add-support-for-Amnezia-s-Jc-Jmin-Jm.patch
        0003-Anti-censorship-introduce-junk-first-option-Jc-befor.patch
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
    # Helper speaks OpenVPN's --msg-channel protocol; ship the matching ABI header.
    file(INSTALL "${SOURCE_PATH}/include/openvpn-msg.h"
         DESTINATION "${CURRENT_PACKAGES_DIR}/include")
endif()

file(
  INSTALL "${SOURCE_PATH}/COPYRIGHT.GPL"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright)
