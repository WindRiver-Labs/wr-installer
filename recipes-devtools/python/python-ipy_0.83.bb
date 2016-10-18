DESCRIPTION = "class and tools for handling of IPv4 and IPv6 addresses and networks"
HOMEPAGE = "https://github.com/autocracy/python-ipy"
LICENSE = "BSD"
SECTION = "devel/python"

LIC_FILES_CHKSUM = "file://COPYING;md5=848d24919845901b4f48bae5f13252e6"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "463b2be0646c7fb48f826f973aac216632f44e14"
PV = "0.83+git${SRCPV}"
SRC_URI = "git://github.com/autocracy/python-ipy.git;branch=master \
"

inherit setuptools pythonnative
