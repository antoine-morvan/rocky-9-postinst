#!/usr/bin/env bash
set -eu -o pipefail

SETUP_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))

(
    sudo dnf update -y
    sudo dnf config-manager --enable crb
    sudo dnf groupinstall "Development Tools" -y
    sudo dnf install kernel-devel-matched kernel-headers -y

    # Nvidia driver setup ; when applicable
    distro=rhel9
    arch=x86_64
    sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
    sudo dnf update -y
    sudo dnf install -y nvidia-driver nvidia-xconfig nvidia-settings \
        nvidia-driver-cuda-libs nvidia-driver-libs libnvidia-ml libnvidia-fbc \
        nvidia-driver-cuda-libs.i686 nvidia-driver-libs.i686 libnvidia-ml.i686 libnvidia-fbc.i686

    sudo dnf install -y \
        gcc gcc-c++ automake autoconf libtool pkgconfig \
        cmake vim htop btop rsync geany git terminator firefox chromium byobu \
        curl wget epel-release \
        ninja-build lowdown \
        gcc-toolset-14
)

${SETUP_SCRIPT_DIR}/modulefiles/setup.sh
${SETUP_SCRIPT_DIR}/bashrc/setup.sh
${SETUP_SCRIPT_DIR}/btop/setup.sh


exit 0
