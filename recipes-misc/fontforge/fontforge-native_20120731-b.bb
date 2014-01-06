# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "An outline font editor that lets you create your own postscript, truetype, opentype, cid-keyed, multi-master, cff, svg and bitmap (bdf, FON, NFNT) fonts, or edit existing ones. Also lets you convert one format to another. FontForge has support for many macintosh font formats."
HOMEPAGE = "http://fontforge.org"
LICENSE = "BSD"
SECTION = ""
DEPENDS = "freetype-native giflib-native tiff-native libuninameslist-native libxml2-native libpng-native"
PR = "r0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=720ee0a73f821888ee48f5d239cf6d73"

SRC_URI = "http://downloads.sourceforge.net/project/${BPN}/${BPN}-source/${BPN}_full-${PV}.tar.bz2"
SRC_URI[md5sum] = "a8a90473a97da87e45f66d11007b6e7c"
SRC_URI[sha256sum] = "1b6184caff211e315783a029256f56cf05f1d4fd3cbcb41820d21c7745040fb6"

SRC_URI += "file://autoheader_fixes.patch \
            file://libpng_update.patch"

S = "${WORKDIR}/${BPN}-${PV}"

EXTRA_OECONF += "--with-freetype-bytecode=no --with-regular-link --enable-pyextension --without-x"

inherit autotools native pythonnative
