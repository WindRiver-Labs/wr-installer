DESCRIPTION = "Setup virtual encryption devices under dm-crypt Linux"
HOMEPAGE = "http://code.google.com/p/cryptsetup/"
SECTION = "console"
LICENSE = "GPLv2"
DEPENDS = "lvm2 libgcrypt popt"
RRECOMMENDS_${PN} = "kernel-module-aes \
                     kernel-module-dm-crypt \
                     kernel-module-md5 \
                     kernel-module-cbc \
                     kernel-module-sha256 \
                    "
PR = "r0"

LIC_FILES_CHKSUM = "file://COPYING;md5=c4f6f1882b70e702dcc722cde4e1ab84"

SRC_URI = "http://cryptsetup.googlecode.com/files/cryptsetup-${PV}.tar.bz2"
SRC_URI[md5sum] = "1f5b5a9d538e8a3c191fb7dd85b9b013"
SRC_URI[sha256sum] = "7ceb18a0c91fa1546077b41b93463dd2ec9d7f83e6fd93757fb84cc608206a6a"

inherit autotools gettext
