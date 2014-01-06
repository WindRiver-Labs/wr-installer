SECTION = "libs"
DESCRIPTION = "ISO language, territory, currency, script codes and their translations"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://LICENSE;md5=fbc093901857fcd118f065f900982c24"
SECTION = "libs"
PACKAGE_ARCH = "all"

SRC_URI = "ftp://pkg-isocodes.alioth.debian.org/pub/pkg-isocodes/iso-codes-${PV}.tar.gz"
SRC_URI[md5sum] = "59ed8129236dd9d394a0c541084f3d6c"
SRC_URI[sha256sum] = "b8a40b811636b6c5febbb6714350a269aa234cb197102f9cd68ef1d4f640e9c4"

inherit autotools

FILES_${PN}-dev="${datadir}/pkgconfig/iso-codes.pc"
FILES_${PN}="${datadir}/xml/iso-codes/ \
             ${datadir}/iso-codes/"
