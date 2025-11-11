#!/usr/bin/env bash
set -eu -o pipefail

# inspired from https://gitlab.winehq.org/wine/wine/-/wikis/Building-Wine

################################################################################################################
## General settings
################################################################################################################
BUILD_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))
CACHE_DIR="${HOME}/Downloads"

WINE_VERSION=10.18
WINETRICKS_VERSION=20250102

PACKAGE_PREFIX_DIR="${HOME}/.local"

################################################################################################################
## General settings
################################################################################################################

case $WINE_VERSION in
    *.0) WINE_URL="https://dl.winehq.org/wine/source/${WINE_VERSION%.*}.0/wine-${WINE_VERSION}.tar.xz" ;;
    *)   WINE_URL="https://dl.winehq.org/wine/source/${WINE_VERSION%.*}.x/wine-${WINE_VERSION}.tar.xz" ;;
esac
WINE_ARCHIVE="$(basename ${WINE_URL})"
WINE_FOLDER="$(basename ${WINE_URL} .tar.xz)"
WINE_CACHE="${CACHE_DIR}/${WINE_ARCHIVE}"


WINETRICKS_URL="https://github.com/Winetricks/winetricks/archive/refs/tags/${WINETRICKS_VERSION}.tar.gz"
WINETRICKS_ARCHIVE="winetricks-${WINETRICKS_VERSION}.tar.gz"
WINETRICKS_FOLDER="$(basename ${WINETRICKS_ARCHIVE} .tar.gz)"
WINETRICKS_CACHE="${CACHE_DIR}/${WINETRICKS_ARCHIVE}"

SOURCE_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}"
BUILD_64_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}_build-64"
BUILD_32_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}_build-32"

################################################################################################################
## Logic
################################################################################################################
echo "## -- Start"

#####
## Download & extract
#####
mkdir -p "${CACHE_DIR}"
[ ! -f "${WINE_CACHE}" ] && echo "## -- Download to ${WINE_CACHE}" && curl -L -o "${WINE_CACHE}" "${WINE_URL}"
[ ! -d "${SOURCE_DIR}" ] && echo "## -- Extract to ${SOURCE_DIR}" &&  tar xf "${WINE_CACHE}" -C "${BUILD_SCRIPT_DIR}"

[ ! -f "${WINETRICKS_CACHE}" ] && echo "## -- Download to ${WINETRICKS_CACHE}" && curl -L -o "${WINETRICKS_CACHE}" "${WINETRICKS_URL}"
[ ! -d "${BUILD_SCRIPT_DIR}/${WINETRICKS_FOLDER}" ] && echo "## -- Extract to ${BUILD_SCRIPT_DIR}/${WINETRICKS_FOLDER}" &&  tar xf "${WINETRICKS_CACHE}" -C "${BUILD_SCRIPT_DIR}"

# use gcc 14 too build wine (mingw is 14.2.1 already !)
source /opt/rh/gcc-toolset-14/enable
export CFLAGS="-O3 -pipe -march=native -mtune=native -ftree-vectorize -funroll-loops"
export i386_CFLAGS="${CFLAGS}"
export CROSSCFLAGS="${CFLAGS}"
BUILD_PROC=20

#####
## Build 64
#####
date_start_64=$(date)
(
    mkdir -p "${BUILD_64_DIR}"
    cd "${BUILD_64_DIR}"

    [ ! -f Makefile ] && "${SOURCE_DIR}/configure" \
        --prefix=${PACKAGE_PREFIX_DIR} \
        --libdir=${PACKAGE_PREFIX_DIR}/lib \
        --disable-tests \
        --enable-archs=i386,x86_64 \
        --enable-win64 \
        CFLAGS="${CFLAGS}" CROSSCFLAGS="${CFLAGS}" i386_CFLAGS="${CFLAGS}"
    make -j ${BUILD_PROC}
)

date_start_32=$(date)
(
    mkdir -p "${BUILD_32_DIR}"
    cd "${BUILD_32_DIR}"

    [ ! -f Makefile ] && "${SOURCE_DIR}/configure" \
        --prefix=${PACKAGE_PREFIX_DIR} \
        --libdir=${PACKAGE_PREFIX_DIR}/lib \
        --disable-tests \
        --enable-archs=i386,x86_64 \
        --with-wine64="${BUILD_64_DIR}" \
        CFLAGS="${CFLAGS}" CROSSCFLAGS="${CFLAGS}" i386_CFLAGS="${CFLAGS}"
    make -j ${BUILD_PROC}
)

date_start_install=$(date)
(
    cd "${BUILD_32_DIR}"
    make install -j ${BUILD_PROC}
    cd "${BUILD_64_DIR}"
    make install -j ${BUILD_PROC}

    echo "install winetricks"
    cp "${BUILD_SCRIPT_DIR}/${WINETRICKS_FOLDER}/src/winetricks" "${PACKAGE_PREFIX_DIR}/bin/winetricks"
    chmod +x "${PACKAGE_PREFIX_DIR}/bin/winetricks"
)

export WINEPREFIX="${HOME}/.wine"
rm -rf "${WINEPREFIX}"
"${PACKAGE_PREFIX_DIR}/bin/winecfg" /v win11

# Install 7zip first and create link
"${PACKAGE_PREFIX_DIR}/bin/winetricks" --force --unattended 7zip
[ ! -h "${WINEPREFIX}"/'drive_c/Program Files (x86)/7-Zip' ] && ln -s "${WINEPREFIX}"/'drive_c/Program Files/7-Zip' "${WINEPREFIX}"/'drive_c/Program Files (x86)/7-Zip'

"${PACKAGE_PREFIX_DIR}/bin/winetricks" --force --unattended \
    comctl32ocx comdlg32ocx \
    dotnet35sp1 dotnet48 \
    vcrun2005 vb6run vcrun2010 vcrun2012 vcrun2013 vcrun2015 \
    corefonts \
    directx9 dxvk d3dx9 d3dx9_36 d3dx9_43 faudio gdiplus d3dcompiler_43 d3dcompiler_47 \
    msxml3

# "${PACKAGE_PREFIX_DIR}/bin/winetricks" --force --unattended allfonts # unnecessary

# make sure to set win11 at the end
"${PACKAGE_PREFIX_DIR}/bin/winecfg" /v win11


################################################################################################################
## Exit
################################################################################################################
echo "## -- Done"
echo "start 64      : $date_start_64"
echo "start 32      : $date_start_32"
echo "start install : $date_start_install"
echo "end           : $(date)"
exit 0
