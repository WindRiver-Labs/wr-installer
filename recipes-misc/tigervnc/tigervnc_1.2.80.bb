# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "TigerVNC remote display system"
HOMEPAGE = "http://www.tigervnc.com/"
LICENSE = "GPLv2+"
SECTION = "x11/utils"
# DEPENDS = "virtual/libx11 libxext"
DEPENDS = "xserver-xorg"
RDEPENDS_${PN} = "chkconfig coreutils hicolor-icon-theme"

LIC_FILES_CHKSUM = "file://LICENCE.TXT;md5=75b02c2872421380bbd47781d2bd75d3"

S = "${WORKDIR}/tigervnc-1.2.80-20130314svn5065"

PR = "r0"

inherit autotools cmake

SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/tigervnc/tigervnc-1.2.80-20130314svn5065.tar.bz2/4522c6f107dbe778f197b2294c0eb867/tigervnc-1.2.80-20130314svn5065.tar.bz2 \
           file://disable_vncviewer.patch \
           file://remove_includedir.patch \
           file://add-fPIC-option-to-COMPILE_FLAGS.patch \
"

SRC_URI[md5sum] = "4522c6f107dbe778f197b2294c0eb867"
SRC_URI[sha256sum] = "bdb1b4ded129ca45e0ad9b9616851ae6f86ffed83e961991dc04bfef767a3b68"

EXTRA_OECONF = "--disable-xorg --disable-xnest --disable-xvfb --disable-dmx \
        --disable-xwin --disable-xephyr --disable-kdrive --with-pic \
        --disable-static --disable-xinerama \
        --with-fontdir=${datadir}/X11/fonts \
        --with-xkb-output=${localstatedir}/lib/xkb \
        --enable-install-libxf86config \
        --enable-glx --disable-dri --enable-dri2 \
        --disable-config-dbus \
        --disable-config-hal \
        --disable-config-udev \
        --with-dri-driver-path=${libdir}/dri \
        --without-dtrace \
        --disable-unit-tests \
        --disable-devel-docs \
        --disable-selective-werror"
#        --with-default-font-path="catalogue:%{_sysconfdir}/X11/fontpath.d,built-ins"

do_configure_append () {
    cp -r ${STAGING_DATADIR}/xserver-xorg-source/* unix/xserver

    pushd unix/xserver
    for all in `find . -type f -perm -001`; do
        chmod -x "$all"
    done

    PACKAGE_VERSION_MAJOR=$(grep 'PACKAGE_VERSION_MAJOR' ${STAGING_DATADIR}/xserver-xorg-source/include/do-not-use-config.h | cut -d\  -f3)
    PACKAGE_VERSION_MINOR=$(grep 'PACKAGE_VERSION_MINOR' ${STAGING_DATADIR}/xserver-xorg-source/include/do-not-use-config.h | cut -d\  -f3)

    patch -p1 -b --suffix .vnc < ../xserver$PACKAGE_VERSION_MAJOR$PACKAGE_VERSION_MINOR.patch

    rm -rf aclocal-copy/
    rm -f aclocal.m4

    export ACLOCALDIR="${S}/unix/xserver/aclocal-copy"
    autotools_copy_aclocal
    ACLOCAL="aclocal --system-acdir=${ACLOCALDIR}/" autoreconf -Wcross --verbose --install --force ${EXTRA_AUTORECONF} $acpaths || bbfatal "autoreconf execution failed."
    chmod +x ./configure
    ${CACHED_CONFIGUREVARS} ./configure ${CONFIGUREOPTS} ${EXTRA_OECONF}
    popd
}

do_compile_append () {
    pushd unix/xserver

    oe_runmake

    popd
}

do_install_append() {
    pushd unix/xserver/hw/vnc

    oe_runmake 'DESTDIR=${D}' install

    popd
}

FILES_${PN} += "${libdir}/xorg/modules/extensions"

FILES_${PN}-dbg += "${libdir}/xorg/modules/extensions/.debug"
