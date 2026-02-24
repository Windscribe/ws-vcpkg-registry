@echo off
setlocal EnableDelayedExpansion

REM This script installs vcpkg to the home directory if that directory does not already exist.

if "%~1"=="" (
    echo The path parameter VCPKG_PATH is not set.
    echo "Usage: vcpkg_install.bat <VCPKG_PATH> [--configure-git]"
    EXIT /B 1
)

if "%~2"=="--configure-git" (
    echo Configure git config for vcpkg
    REM remove previous insteadof sections for the git@gitlab.int.windscribe.com address
    for /f delims^=^ eol^= %%i  in ('git config --list ^| findstr /i "insteadof=git@gitlab.int.windscribe.com"') do (
        for /f "tokens=1 delims==" %%a in ("%%i") do (
            set result=%%a
            git config --global --remove-section !result:~0,-10!
        )
    )
    git config --global url."https://gitlab-ci-token:%CI_JOB_TOKEN%@gitlab.int.windscribe.com/".insteadOf "git@gitlab.int.windscribe.com:"
)

set VCPKG_ROOT=%~1
set /p VCPKG_COMMIT=<"%~dp0vcpkg_commit.txt"

mkdir c:\vcpkg_cache

set PATCHES_DIR=%~dp0patches
set NEEDS_INSTALL=0
if exist "%VCPKG_ROOT%\vcpkg.exe" (
    for /f %%i in ('git -C "%VCPKG_ROOT%" rev-parse HEAD 2^>nul') do set CURRENT_COMMIT=%%i
    if "!CURRENT_COMMIT!"=="%VCPKG_COMMIT%" (
        echo vcpkg is installed and up to date
        "%VCPKG_ROOT%\vcpkg" version
    ) else (
        echo vcpkg commit mismatch: expected %VCPKG_COMMIT%, got !CURRENT_COMMIT!
        set NEEDS_INSTALL=1
    )
) else (
    echo vcpkg is not installed
    set NEEDS_INSTALL=1
)

if !NEEDS_INSTALL!==1 (
    echo Installing vcpkg at commit %VCPKG_COMMIT%
    if exist "%VCPKG_ROOT%\" rmdir /s/q "%VCPKG_ROOT%"
    mkdir "%VCPKG_ROOT%"
    PUSHD .
    cd "%VCPKG_ROOT%"
    git clone https://github.com/Microsoft/vcpkg.git .
    git checkout %VCPKG_COMMIT%
    POPD
    echo Applying custom patches to vcpkg...
    git -C "%VCPKG_ROOT%" apply "%PATCHES_DIR%\vcpkg_configure_cmake.patch"
    git -C "%VCPKG_ROOT%" apply "%PATCHES_DIR%\ios_toolchain.patch"
    PUSHD .
    cd "%VCPKG_ROOT%"
    bootstrap-vcpkg.bat -disableMetrics
    POPD
)

set TRIPLETS_SRC=%~dp0..\triplets
set TRIPLETS_DST=%VCPKG_ROOT%\triplets
echo Copying custom triplets to "%TRIPLETS_DST%"...
xcopy /Y /Q "%TRIPLETS_SRC%\*.cmake" "%TRIPLETS_DST%\"
