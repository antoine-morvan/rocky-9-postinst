#!/usr/bin/env bash
set -eu -o pipefail

SETUP_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))

(
    sudo dnf update -y
    sudo dnf install dnf-plugins-core
    sudo dnf config-manager --enable crb
    sudo dnf install epel-release
    sudo dnf groupinstall "Development Tools" -y
    sudo dnf install kernel-devel-matched kernel-headers -y

    # basic tools + btop/bashrc dependencies
    sudo dnf install -y \
        gcc gcc-c++ automake autoconf libtool pkgconfig \
        cmake vim htop rsync geany git terminator firefox chromium byobu \
        curl wget epel-release tree \
        ninja-build lowdown \
        gcc-toolset-14

    # Nvidia driver setup ; when applicable
    distro=rhel9
    arch=x86_64
    sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
    sudo dnf update -y
    sudo dnf install -y nvidia-driver nvidia-xconfig nvidia-settings \
        nvidia-driver-cuda-libs nvidia-driver-libs libnvidia-ml libnvidia-fbc \
        nvidia-driver-cuda-libs.i686 nvidia-driver-libs.i686 libnvidia-ml.i686 libnvidia-fbc.i686

    sudo dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm
    sudo dnf install -y --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
    sudo dnf makecache
    sudo dnf install -y ffmpeg ffmpeg-devel vlc --allowerasing

    # wine dependencies
    sudo dnf install -y \
        libstdc++-devel.i686 glibc-devel.i686 libgcc.i686 \
        flex bison \
        xorg-x11-server-devel.i686 xorg-x11-server-Xwayland-devel.i686 xine-ui.x86_64 \
        mingw32-gcc mingw64-gcc \
        alsa-lib-devel \
        alsa-lib-devel.i686 \
        pulseaudio-libs-devel \
        pulseaudio-libs-devel.i686 \
        dbus-libs \
        fontconfig-devel freetype-devel freetype \
        fontconfig-devel.i686 freetype-devel.i686 freetype.i686 \
        gnutls-devel \
        libunwind-devel \
        mesa-libGL-devel libXcomposite-devel libXcursor-devel libXfixes-devel libXi-devel libXrandr-devel libXrender-devel libXext-devel wayland-devel libglvnd-devel \
        mesa-libGL-devel.i686 libXcomposite-devel.i686 libXcursor-devel.i686 libXfixes-devel.i686 libXi-devel.i686 libXrandr-devel.i686 libXrender-devel.i686 libXext-devel.i686 wayland-devel.i686 libglvnd-devel.i686 \
        libxkbcommon-devel \
        libxkbcommon-devel.i686 \
        gstreamer1-devel gstreamer1-plugins-base-devel \
        gstreamer1-devel.i686 gstreamer1-plugins-base-devel.i686 \
        mesa*devel mesa*devel.i686 \
        SDL2-devel \
        SDL2-devel.i686 \
        systemd-devel \
        systemd-devel.i686 \
        libgphoto2-devel sane-backends-devel krb5-devel samba-devel ocl-icd-devel libpcap-devel libusbx-devel \
        libgphoto2-devel.i686 sane-backends-devel.i686 krb5-devel.i686 samba-devel.i686 ocl-icd-devel.i686 libpcap-devel.i686 libusbx-devel.i686 \
        libnetapi-devel libnetapi-devel.i686 \
        libXxf86vm-devel libXxf86vm-devel.i686 \
        libXinerama-devel libXinerama-devel.i686 \
        dbus-devel dbus-devel.i686 \
        mesa-vulkan-drivers.x86_64 \
        mesa-vulkan-drivers.i686 \
        mingw32-vulkan-headers.noarch \
        mingw32-vulkan-loader.noarch \
        mingw32-vulkan-tools.noarch \
        mingw32-vulkan-validation-layers.noarch \
        mingw64-vulkan-headers.noarch \
        mingw64-vulkan-loader.noarch \
        mingw64-vulkan-tools.noarch \
        mingw64-vulkan-validation-layers.noarch \
        vulkan-headers.noarch \
        vulkan-loader \
        vulkan-loader.i686 \
        vulkan-loader-devel \
        vulkan-loader-devel.i686 \
        vulkan-tools \
        vulkan-utility-libraries-devel \
        vulkan-utility-libraries-devel.i686 \
        vulkan-validation-layers \
        vulkan-volk-devel \
        vulkan-volk-devel.i686 \
        libvkd3d

    # make sure to remove packages that will be manually installed
    sudo dnf remove -y wine btop
    sudo dnf autoremove -y
)

${SETUP_SCRIPT_DIR}/modulefiles/setup.sh
${SETUP_SCRIPT_DIR}/bashrc/setup.sh
${SETUP_SCRIPT_DIR}/btop/setup.sh
${SETUP_SCRIPT_DIR}/brave/setup.sh
${SETUP_SCRIPT_DIR}/vscode/setup.sh

exit 0
