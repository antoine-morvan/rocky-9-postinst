#!/usr/bin/env bash
set -eu -o pipefail

SETUP_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))

(
    sudo dnf update -y
    sudo dnf install -y \
        gcc automake autoconf libtool pkgconfig \
        cmake vim htop btop rsync geany git terminator firefox chromium byobu \
        curl wget epel-release
)

${SETUP_SCRIPT_DIR}/modulefiles/setup.sh
${SETUP_SCRIPT_DIR}/bashrc/setup.sh


exit 0
