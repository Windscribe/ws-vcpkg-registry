set(VCPKG_TARGET_ARCHITECTURE "arm64;x86_64")
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES "arm64;x86_64")
set(VCPKG_BUILD_TYPE release)
set(VCPKG_OSX_DEPLOYMENT_TARGET 13.0)

# CMake 4 no longer sets CMAKE_OSX_SYSROOT on its own, so ports built with makefiles (e.g. OpenSSL)
# lose -isysroot and cannot find the SDK headers. Point them at the SDK of the selected Xcode.
execute_process(COMMAND xcrun --sdk macosx --show-sdk-path
    OUTPUT_VARIABLE WS_MACOS_SDK_PATH OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE WS_XCRUN_RESULT ERROR_QUIET)
if(WS_XCRUN_RESULT EQUAL 0 AND IS_DIRECTORY "${WS_MACOS_SDK_PATH}")
    set(VCPKG_OSX_SYSROOT "${WS_MACOS_SDK_PATH}")
endif()
