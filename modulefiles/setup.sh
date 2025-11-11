#!/usr/bin/env bash
set -e -u -o pipefail

SETUP_SCRIPT_DIR=$(dirname $(readlink -f $BASH_SOURCE))
CACHE_DIR="${HOME}/Downloads"

PACKAGE_PREFIX_DIR="${HOME}/.local"

#####################################################################################################
###  CHECKS
#####################################################################################################

SETUP_VERSION="5.6.0"
mkdir -p ${CACHE_DIR}

MODULEFILES_FOLDER=modules-${SETUP_VERSION}
MODULEFILES_ARCHIVE=${MODULEFILES_FOLDER}.tar.bz2
MODULEFILES_URL=https://github.com/cea-hpc/modules/releases/download/v${SETUP_VERSION}/${MODULEFILES_FOLDER}.tar.bz2
MODULEFILES_CACHE=${CACHE_DIR}/${MODULEFILES_ARCHIVE}

TCL_VERSION=8.6.13
TCL_DIR=tcl${TCL_VERSION}
TCL_ARCHIVE=${TCL_DIR}-src.tar.gz
TCL_URL=https://sourceforge.net/projects/tcl/files/Tcl/${TCL_VERSION}/${TCL_DIR}-src.tar.gz
TCL_CACHE=${CACHE_DIR}/${TCL_ARCHIVE}

#####
## Download & extract
#####
mkdir -p "${CACHE_DIR}"
[ ! -f "${TCL_CACHE}" ] && echo "## -- Download to ${TCL_CACHE}" && curl -L -o "${TCL_CACHE}" "${TCL_URL}"
[ ! -f "${MODULEFILES_CACHE}" ] && echo "## -- Download to ${MODULEFILES_CACHE}" && curl -L -o "${MODULEFILES_CACHE}" "${MODULEFILES_URL}"

[ ! -d "${SETUP_SCRIPT_DIR}/${TCL_DIR}" ] && tar xf "${TCL_CACHE}" -C "${SETUP_SCRIPT_DIR}"
[ ! -d "${SETUP_SCRIPT_DIR}/${MODULEFILES_FOLDER}" ] &&  tar xf "${MODULEFILES_CACHE}" -C "${SETUP_SCRIPT_DIR}"

#####################################################################################################
###  Build & Install
#####################################################################################################

MODULEFILES_EXTRA_CONF_ARGS=""
(
    if [ ! -f ${PACKAGE_PREFIX_DIR}/lib/libtcl.so ]; then
        cd ${SETUP_SCRIPT_DIR}/${TCL_DIR}/unix
        [ ! -f Makefile ] && ./configure \
            --prefix=${PACKAGE_PREFIX_DIR} \
            --libdir=${PACKAGE_PREFIX_DIR}/lib \
            --enable-threads \
            --enable-64bit
        make -j 8
        make install
    else
        echo ">> Skip tclsh"
    fi
    if [ ! -h ${PACKAGE_PREFIX_DIR}/bin/tclsh ]; then
        ln -s ${PACKAGE_PREFIX_DIR}/bin/tclsh${TCL_VERSION%.*} ${PACKAGE_PREFIX_DIR}/bin/tclsh
    fi
    if [ ! -h ${PACKAGE_PREFIX_DIR}/lib/libtcl.so ]; then
        ln -s ${PACKAGE_PREFIX_DIR}/lib/libtcl${TCL_VERSION%.*}.so ${PACKAGE_PREFIX_DIR}/lib/libtcl.so
    fi
)
MODULEFILES_EXTRA_CONF_ARGS+=" \
        --with-tcl=${PACKAGE_PREFIX_DIR}/lib \
        --with-bin-search-path=\"$(printf %q \"$PATH\"):${PACKAGE_PREFIX_DIR}/bin\" \
    "

if [ ! -f ${PACKAGE_PREFIX_DIR}/init/profile.sh ]; then
    cd ${SETUP_SCRIPT_DIR}/${MODULEFILES_FOLDER}
    set -x
    TARGET="$(LANG=C ${CC:-gcc} -v |& grep Target | cut -d' ' -f2)"
    ./configure \
        --target=${TARGET} \
        --build=${TARGET} \
        --host=${TARGET} \
        ${MODULEFILES_EXTRA_CONF_ARGS:-} \
        --prefix=${PACKAGE_PREFIX_DIR}

    make -j 8
    make install
else 
    echo ">> Skip modulefiles"
fi

echo "Install Modulefile Done"
exit 0
