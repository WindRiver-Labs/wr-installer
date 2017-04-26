# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Initial system configuration utility"
DESCRIPTION = "The firstboot utility runs after installation.  It guides the user through \
a series of steps that allows for easier configuration of the machine."
HOMEPAGE = "http://fedoraproject.org/wiki/FirstBoot"
LICENSE = "GPLv2+"

inherit setuptools3 systemd

SRC_URI = "http://pkgs.fedoraproject.org/lookaside/pkgs/firstboot/firstboot-19.2.tar.gz/69b57cb059834f57945bae873b26795e/firstboot-19.2.tar.gz \
           file://0001-tweak-systemd-unit-dir-from-usr-lib-to-lib.patch \
"
SRC_URI[md5sum] = "69b57cb059834f57945bae873b26795e"
SRC_URI[sha256sum] = "60765c81a73f1a55ff84381b3a96d23bdc2c60c529aff0442f6d450a3a7c0543"

LIC_FILES_CHKSUM = "\
    file://firstboot/interface.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/module.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/moduleset.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/constants.py;beginline=1;endline=19;md5=f57896624904451f9e6e2883686ffe6d \
    file://firstboot/config.py;beginline=1;endline=19;md5=7d2df1cda4aac492a59f73525b00501a \
"

FILES_${PN} += "${systemd_unitdir}/system/*"
