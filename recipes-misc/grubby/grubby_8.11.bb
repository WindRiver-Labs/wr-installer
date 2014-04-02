
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=892f569a555ba9c07a568a7c0c4fa63a"

DEPENDS = "popt util-linux"

PR = "r0"

SRC_URI = "http://git.fedorahosted.org/cgit/grubby.git/snapshot/${PN}-${PV}-1.tar.bz2"

SRC_URI[md5sum] = "b3241a14901d27a520b50ebc7398948c"
SRC_URI[sha256sum] = "2c3b9bd302edbaa2e24492511435054d7ed731d6417e3654592449aa82e1db9c"

S = "${WORKDIR}/${PN}-${PV}-1"

inherit autotools

EXTRA_OEMAKE = "'CC=${CC}'"
