# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "TigerVNC remote display system"
HOMEPAGE = "http://www.tigervnc.com/"
LICENSE = "GPLv2+"
SECTION = "x11/utils"
# DEPENDS = "virtual/libx11 libxext"
DEPENDS = "xserver-xorg gnutls jpeg"
RDEPENDS_${PN} = "chkconfig coreutils hicolor-icon-theme"

LIC_FILES_CHKSUM = "file://LICENCE.TXT;md5=75b02c2872421380bbd47781d2bd75d3"

S = "${WORKDIR}/git"

inherit cmake autotools-brokensep

SRCREV = "242fdf0c5a5483910537419a4833c3f725889095"

SRC_URI = "git://github.com/TigerVNC/tigervnc.git \
           file://disable_vncviewer.patch \
           file://remove_includedir.patch \
           file://add-fPIC-option-to-COMPILE_FLAGS.patch \
           file://tigervnc-the-string-I-in-path-name-is-replaced-wrongly.patch \
"

EXTRA_OECONF = "--disable-xorg --disable-xnest --disable-xvfb --disable-dmx \
        --disable-xwin --disable-xephyr --disable-kdrive --with-pic \
        --disable-static --disable-xinerama \
        --with-xkb-output=${localstatedir}/lib/xkb \
        --enable-install-libxf86config \
        --disable-glx --disable-dri --disable-dri2 \
        --disable-config-hal \
        --disable-config-udev \
        --without-dtrace \
        --disable-unit-tests \
        --disable-devel-docs \
        --disable-selective-werror \
        --disable-xshmfence \
        --disable-config-udev \
        --disable-dri3 \
        --disable-libunwind \
        --without-xmlto \
        --enable-systemd-logind=no \
        --disable-xinerama \
" 
do_configure_append () {
    cp -r ${STAGING_DATADIR}/${MLPREFIX}xserver-xorg-source/* unix/xserver
    sed -i "s:malloc(rgnSize)):(pixman_region16_data_t*)malloc(rgnSize)):g" unix/xserver/include/regionstr.h

    olddir=`pwd`
    cd unix/xserver
    for all in `find . -type f -perm -001`; do
        chmod -x "$all"
    done

    PACKAGE_VERSION_MAJOR=$(grep 'PACKAGE_VERSION_MAJOR' ${STAGING_DATADIR}//${MLPREFIX}xserver-xorg-source/include/do-not-use-config.h | cut -d\  -f3)
    PACKAGE_VERSION_MINOR=$(grep 'PACKAGE_VERSION_MINOR' ${STAGING_DATADIR}//${MLPREFIX}xserver-xorg-source/include/do-not-use-config.h | cut -d\  -f3)

    patch -p1 -b --suffix .vnc < ../xserver$PACKAGE_VERSION_MAJOR$PACKAGE_VERSION_MINOR.patch

    rm -rf aclocal-copy/
    rm -f aclocal.m4

    export ACLOCALDIR="${S}/unix/xserver/aclocal-copy"
    mkdir -p ${ACLOCALDIR}/
    if [ -d ${STAGING_DATADIR_NATIVE}/aclocal ]; then
        cp-noerror ${STAGING_DATADIR_NATIVE}/aclocal/ ${ACLOCALDIR}/
    fi
    if [ -d ${STAGING_DATADIR}/aclocal -a "${STAGING_DATADIR_NATIVE}/aclocal" != "${STAGING_DATADIR}/aclocal" ]; then
        cp-noerror ${STAGING_DATADIR}/aclocal/ ${ACLOCALDIR}/
    fi
    ACLOCAL="aclocal --system-acdir=${ACLOCALDIR}/" autoreconf -Wcross --verbose --install --force ${EXTRA_AUTORECONF} $acpaths || bbfatal "autoreconf execution failed."
    chmod +x ./configure
    ${CACHED_CONFIGUREVARS} ./configure ${CONFIGUREOPTS} ${EXTRA_OECONF}
    cd $olddir
}

do_compile_append () {
    olddir=`pwd`
    cd unix/xserver

    oe_runmake

    cd $olddir
}

do_install_append() {
    olddir=`pwd`
    cd unix/xserver/hw/vnc

    oe_runmake 'DESTDIR=${D}' install

    cd $olddir
}

FILES_${PN} += "${libdir}/xorg/modules/extensions"

FILES_${PN}-dbg += "${libdir}/xorg/modules/extensions/.debug"
