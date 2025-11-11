#!/usr/bin/env bash
set -eu -o pipefail

# inspired from https://gitlab.winehq.org/wine/wine/-/wikis/Building-Wine

################################################################################################################
## General settings
################################################################################################################
BUILD_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))
CACHE_DIR="${HOME}/Downloads"

WINE_VERSION=10.18

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

export CFLAGS="-O2 -march=native -mtune=native"
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
        CFLAGS="${CFLAGS}"
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
        CFLAGS="${CFLAGS}"
    make -j ${BUILD_PROC}
)

date_start_install=$(date)
(
    cd "${BUILD_32_DIR}"
    make install -j ${BUILD_PROC}
    cd "${BUILD_64_DIR}"
    make install -j ${BUILD_PROC}
)

################################################################################################################
## Exit
################################################################################################################
echo "## -- Done"
echo "start 64      : $date_start_64"
echo "start 32      : $date_start_32"
echo "start install : $date_start_install"
echo "end           : $(date)"
exit 0
