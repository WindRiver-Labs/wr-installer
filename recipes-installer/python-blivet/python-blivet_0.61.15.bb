DESCRIPTION = "A python module for system storage configuration"
HOMEPAGE = "http://fedoraproject.org/wiki/blivet"
LICENSE = "LGPLv2+"
SECTION = "devel/python"

LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "de40764141a7624e95ea9b109466bfe464cbfcdc"
PV = "0.61.15.41+git${SRCPV}"
SRC_URI = "git://github.com/rhinstaller/blivet;branch=rhel7-branch \
"

inherit setuptools pythonnative

RDEPENDS_${PN} = "pykickstart python-pyudev \
                  parted python-pyparted device-mapper-multipath \
                  device-mapper device-mapper-multipath \
"
