DESCRIPTION = "libnl is a library for applications dealing with netlink sockets."
HOMEPAGE = "http://www.infradead.org/~tgr/libnl/"
SECTION = "libs/network"

LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=2b41e13261a330ee784153ecbb6a82bc"

DEPENDS = "flex-native bison-native"
PE = "1"
PR = "r6"
S = "${WORKDIR}/libnl-${PV}"

SRC_URI = "\
    http://www.infradead.org/~tgr/libnl/files/libnl-${PV}.tar.gz \
    file://libnl-1.0-pre5-static.patch \
    file://libnl-1.0-pre5-debuginfo.patch \
    file://libnl-1.0-pre8-use-vasprintf-retval.patch \
    file://libnl-1.0-pre8-more-build-output.patch \
    file://libnl-1.1-include-limits-h.patch \
    file://libnl-1.1-doc-inlinesrc.patch \
    file://libnl-1.1-no-extern-inline.patch \
    file://libnl-1.1-align.patch \
    file://libnl-1.1-disable-static-by-default.patch \
    file://libnl-1.1-fix-portmap-position.patch \
    file://libnl-1.1-threadsafe-port-allocation.patch \
"

SRC_URI[md5sum] = "ae970ccd9144e132b68664f98e7ceeb1"
SRC_URI[sha256sum] = "35cea4cfb6cd8af0cafa0f34fff81def5a1f193b8b8384299b4b21883e22edc3"

inherit autotools-brokensep pkgconfig

PACKAGES =+ "${PN}-route ${PN}-nf ${PN}-genl ${PN}-cli"
FILES_${PN}-route = "${libdir}/libnl-route.so.*"
FILES_${PN}-nf    = "${libdir}/libnl-nf.so.*"
FILES_${PN}-genl  = "${libdir}/libnl-genl.so.*"
FILES_${PN}-cli   = "${libdir}/libnl-cli.so.*"
