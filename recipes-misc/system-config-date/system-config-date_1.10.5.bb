# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "A graphical interface for modifying system date and time"
HOMEPAGE = "http://fedorahosted.org/system-config-date"
LICENSE = "GPLv2+"

DEPENDS = "python intltool-native"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

PR = "r0"

inherit autotools gettext python-dir pythonnative

SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/system-config-date/system-config-date-1.10.5.tar.bz2/2b9c05684952a9ffb1ce927f12560202/system-config-date-1.10.5.tar.bz2 \
	   file://Install-to-usr-instead-of-usr-local.patch \
	   file://fix-bashism.patch \
"
SRC_URI[md5sum] = "2b9c05684952a9ffb1ce927f12560202"
SRC_URI[sha256sum] = "17765ad5f4283537c93bb68134bd22da02eee40a55fec21caeb57213e37a8b17"

FILES_${PN} += "/usr/lib/${PYTHON_DIR}/site-packages/scdate* ${datadir}/icons ${datadir}/polkit-1"

PARALLEL_MAKE = ""

do_install() {
    oe_runmake DESTDIR=${D} install
}
