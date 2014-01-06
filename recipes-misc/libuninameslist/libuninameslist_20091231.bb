DESCRIPTION = "A library providing Unicode character names and annotations"
HOMEPAGE = "http://libuninameslist.sourceforge.net"
LICENSE = "BSD"

LIC_FILES_CHKSUM = "file://COPYING;md5=1483f8a281ad20a0574fb25d37fecd8f \
                    file://LICENSE;md5=45a217c6de1a1fc98283fe7c5acf595c"
PR = "r0"

SRC_URI = "http://downloads.sourceforge.net/${BPN}/${BPN}-${PV}.tar.bz2"
SRC_URI[md5sum] = "14f47d50fb0e05c5029298847437feab"
SRC_URI[sha256sum] = "ea401c625d849a0b554abf9800289ad38eb63817fafc277fe7301e454ab3fec7"

S = "${WORKDIR}/${BPN}"
EXTRA_OECONF += "--disable-static"

inherit autotools

BBCLASSEXTEND = "native"
