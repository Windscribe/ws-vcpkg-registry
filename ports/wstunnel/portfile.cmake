set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Windscribe/wstunnel
    REF e6c325eed099e746ee98f80de7b827e942416d20 # v1.0.7
    SHA512 9ea2b55595e478ef83072a06e66bb9aff39ec4970428a6ee109fa55e2120aa316f1cb0aa9d0fe97390cdf1b31a2c30c97704de7338ae6127ca3a146a34f136b1
)

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
# Install the binary exactly as Go links it. vcpkg's rpath rewriting leaves dynamic Go binaries segfaulting on Linux
# and would add an rpath to the macOS binary.
set(VCPKG_FIXUP_ELF_RPATH OFF)
set(VCPKG_FIXUP_MACHO_RPATH OFF)

set(OUT_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")
file(REMOVE_RECURSE "${OUT_DIR}")

if(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(GOARCH amd64)
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(GOARCH arm64)
    else()
        message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
    endif()

    set(ENV{GOOS} windows)
    set(ENV{GOARCH} ${GOARCH})
    vcpkg_execute_build_process(
        COMMAND "${GO}" build -trimpath "-gcflags=all=-l" "-ldflags=-w -s" -o "${OUT_DIR}/wstunnel.exe"
        WORKING_DIRECTORY "${SOURCE_PATH}"
        LOGNAME "build-${TARGET_TRIPLET}"
    )
    file(INSTALL "${OUT_DIR}/wstunnel.exe" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
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
            COMMAND "${GO}" build -trimpath "-gcflags=all=-l" "-ldflags=-w -s" -o "${OUT_DIR}/${GOARCH}/wstunnel"
            WORKING_DIRECTORY "${SOURCE_PATH}"
            LOGNAME "build-${TARGET_TRIPLET}-${GOARCH}"
        )
        list(APPEND ARCH_BINARIES "${OUT_DIR}/${GOARCH}/wstunnel")
    endforeach()

    set(BINARY "${OUT_DIR}/wstunnel")
    if(VCPKG_TARGET_IS_OSX)
        vcpkg_execute_build_process(
            COMMAND lipo -create ${ARCH_BINARIES} -output "${BINARY}"
            WORKING_DIRECTORY "${OUT_DIR}"
            LOGNAME "lipo-${TARGET_TRIPLET}"
        )
    else()
        file(COPY_FILE "${ARCH_BINARIES}" "${BINARY}")
    endif()

    file(INSTALL "${BINARY}" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
         FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endif()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
