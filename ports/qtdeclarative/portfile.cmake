set(SCRIPT_PATH "${CURRENT_INSTALLED_DIR}/share/qtbase")
include("${SCRIPT_PATH}/qt_install_submodule.cmake")

vcpkg_buildpath_length_warning(44)

set(${PORT}_PATCHES "")

 set(TOOL_NAMES
        qml
        qmlaotstats
        qmlcachegen
        qmlcontextpropertydump
        qmleasing
        qmlformat
        qmlimportscanner
        qmllint
        qmlplugindump
        qmlpreview
        qmlprofiler
        qmlscene
        qmltestrunner
        qmltime
        qmltyperegistrar
        qmldom
        qmltc
        qmlls
        qmljsrootgen
        svgtoqml
    )

if(VCPKG_TARGET_IS_OSX)
    # Workaround: QQmlThread deadlocks on macOS with Qt 6.10+ static builds.
    # The threaded type loader's cross-thread wakeup mechanism doesn't work with
    # the macOS CFRunLoop-based event dispatcher. Disabling this feature uses a
    # stub that runs QML loading on the main thread instead.
    list(APPEND EXTRA_OPTIONS -DFEATURE_qml_type_loader_thread=OFF)
endif()

qt_install_submodule(PATCHES    ${${PORT}_PATCHES}
                     TOOL_NAMES ${TOOL_NAMES}
                     CONFIGURE_OPTIONS
                      ${EXTRA_OPTIONS}
                      -DCMAKE_DISABLE_FIND_PACKAGE_LTTngUST:BOOL=ON
                      -DFEATURE_quickcontrols2_fusion:BOOL=OFF
                      -DFEATURE_quickcontrols2_imagine:BOOL=OFF
                      -DFEATURE_quickcontrols2_material:BOOL=OFF
                      -DFEATURE_quickcontrols2_universal:BOOL=OFF
                      -DFEATURE_quickcontrols2_fluentwinui3:BOOL=OFF
                      -DFEATURE_quickcontrols2_macos:BOOL=OFF
                      -DFEATURE_quickcontrols2_ios:BOOL=OFF
                      -DFEATURE_quickcontrols2_windows:BOOL=OFF
                     CONFIGURE_OPTIONS_RELEASE
                     CONFIGURE_OPTIONS_DEBUG
                    )

