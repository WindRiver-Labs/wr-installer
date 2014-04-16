# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Initial system configuration utility"
DESCRIPTION = "The firstboot utility runs after installation.  It guides the user through \
a series of steps that allows for easier configuration of the machine."
HOMEPAGE = "http://fedoraproject.org/wiki/FirstBoot"
LICENSE = "GPLv2+"

DEPENDS = ""
RDEPENDS = ""

PR = "r0"

# FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

inherit python-dir pythonnative

SRC_URI = "http://pkgs.fedoraproject.org/lookaside/pkgs/firstboot/firstboot-16.4.tar.bz2/1124c87f126bf7823f2dd04f1c324f9f/firstboot-16.4.tar.bz2"
SRC_URI[md5sum] = "1124c87f126bf7823f2dd04f1c324f9f"
SRC_URI[sha256sum] = "4c1b17310d213d4740f7e8b88d9ba0488d36b09b7cd84447a41bebb18ac6e933"

LIC_FILES_CHKSUM = "\
    file://firstboot/interface.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/module.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/moduleset.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/constants.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/config.py;beginline=1;endline=19;md5=7d2df1cda4aac492a59f73525b00501a \
    file://modules/date.py;beginline=1;endline=19;md5=66093799149a96da8b81d4e4297e44a9 \
    file://modules/create_user.py;beginline=1;endline=19;md5=66093799149a96da8b81d4e4297e44a9 \
    file://modules/welcome.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://modules/eula.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d"

EXTRA_OEMAKE += "DESTDIR=${D} SITELIB=${PYTHON_SITEPACKAGES_DIR} RPM_BUILD_ROOT=${D}"

FILES_${PN} += "${sysconfdir} ${bindir} ${includedir} ${libdir} ${libexecdir} ${datadir} ${sbindir}"
FILES_${PN} += "${PYTHON_SITEPACKAGES_DIR}/* ${datadir}/firstboot ${sbindir}/firstboot /lib"
FILES_${PN} += "${exec_prefix}/local"

do_install() {
    oe_runmake install
}
