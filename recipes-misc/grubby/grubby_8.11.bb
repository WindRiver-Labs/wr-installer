
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=892f569a555ba9c07a568a7c0c4fa63a"

DEPENDS = "popt util-linux"

PR = "r0"

SRC_URI = "http://git.fedorahosted.org/cgit/grubby.git/snapshot/${PN}-${PV}-1.tar.bz2"

SRC_URI[md5sum] = "b8de5e2b6e057d6023ad9d52236af28f"
SRC_URI[sha256sum] = "280eba4216ac36f687e388278a76af3ba2faf2188b5900a69bc4ce18e89b7818"

S = "${WORKDIR}/${PN}-${PV}-1"

inherit autotools

EXTRA_OEMAKE = "'CC=${CC}'"
