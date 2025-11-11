#!/usr/bin/env bash
set -eu -o pipefail

# inspired from https://gitlab.winehq.org/wine/wine/-/wikis/Building-Wine

################################################################################################################
## General settings
################################################################################################################
BUILD_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))
CACHE_DIR="${HOME}/Downloads"

PACKAGE_PREFIX_DIR="${HOME}/.local"

################################################################################################################
## General settings
################################################################################################################
WINE_VERSION=10.18
case $WINE_VERSION in
    *.0) WINE_URL="https://dl.winehq.org/wine/source/${WINE_VERSION%.*}.0/wine-${WINE_VERSION}.tar.xz" ;;
    *)   WINE_URL="https://dl.winehq.org/wine/source/${WINE_VERSION%.*}.x/wine-${WINE_VERSION}.tar.xz" ;;
esac
WINE_ARCHIVE="$(basename ${WINE_URL})"
WINE_FOLDER="$(basename ${WINE_URL} .tar.xz)"
WINE_CACHE="${CACHE_DIR}/wine-${WINE_VERSION}.tar.xz"

SOURCE_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}"
BUILD_64_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}_build-64"
BUILD_32_DIR="${BUILD_SCRIPT_DIR}/${WINE_FOLDER}_build-32"

################################################################################################################
## Logic
################################################################################################################
echo "## -- Start"

# force clean
# rm -rf "${SOURCE_DIR}" "${BUILD_64_DIR}" "${BUILD_32_DIR}"

#####
## Check system
#####
# sudo dnf install -y \
#     libstdc++-devel.i686 glibc-devel.i686 libgcc.i686 \
#     flex bison \
#     xorg-x11-server-devel.i686 xorg-x11-server-Xwayland-devel.i686 xine-ui.x86_64 \
#     mingw32-gcc mingw64-gcc \
#     alsa-lib-devel \
#     alsa-lib-devel.i686 \
#     pulseaudio-libs-devel \
#     pulseaudio-libs-devel.i686 \
#     dbus-libs \
#     fontconfig-devel freetype-devel freetype \
#     fontconfig-devel.i686 freetype-devel.i686 freetype.i686 \
#     gnutls-devel \
#     libunwind-devel \
#     mesa-libGL-devel libXcomposite-devel libXcursor-devel libXfixes-devel libXi-devel libXrandr-devel libXrender-devel libXext-devel wayland-devel libglvnd-devel \
#     mesa-libGL-devel.i686 libXcomposite-devel.i686 libXcursor-devel.i686 libXfixes-devel.i686 libXi-devel.i686 libXrandr-devel.i686 libXrender-devel.i686 libXext-devel.i686 wayland-devel.i686 libglvnd-devel.i686 \
#     libxkbcommon-devel \
#     libxkbcommon-devel.i686 \
#     gstreamer1-devel gstreamer1-plugins-base-devel \
#     gstreamer1-devel.i686 gstreamer1-plugins-base-devel.i686 \
#     mesa*devel mesa*devel.i686 \
#     SDL2-devel \
#     SDL2-devel.i686 \
#     systemd-devel \
#     systemd-devel.i686 \
#     vulkan-headers vulkan-loader vulkan-volk-devel \
#     vulkan-loader.i686 vulkan-volk-devel.i686 \
#     libgphoto2-devel sane-backends-devel krb5-devel samba-devel ocl-icd-devel libpcap-devel libusbx-devel \
#     libgphoto2-devel.i686 sane-backends-devel.i686 krb5-devel.i686 samba-devel.i686 ocl-icd-devel.i686 libpcap-devel.i686 libusbx-devel.i686 \
#     libnetapi-devel libnetapi-devel.i686


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
    
    set +e
    make -j ${BUILD_PROC}
    res=$?
    set -e
    [ $res != 0 ] && make -j 1 V=1 VERBOSE=1 && exit 1
    true
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
    
    set +e
    make -j ${BUILD_PROC}
    res=$?
    set -e
    [ $res != 0 ] && make -j 1 V=1 VERBOSE=1 && exit 1
    true
)

date_start_install=$(date)
(
    cd "${BUILD_32_DIR}"
    make install -j ${BUILD_PROC}
    cd "${BUILD_64_DIR}"
    make install -j ${BUILD_PROC}
)




echo "start 64      : $date_start_64"
echo "start 32      : $date_start_32"
echo "start install : $date_start_install"
echo "end           : $(date)"

################################################################################################################
## Exit
################################################################################################################
echo "## -- Done"
exit 0
