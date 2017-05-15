DESCRIPTION = "A python library for manipulating kickstart files"
HOMEPAGE = "http://fedoraproject.org/wiki/pykickstart"
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS = "python3"
RDEPENDS_${PN} = "python3 \
                  python3-requests \
                  python3-six \
"

S = "${WORKDIR}/git"
SRC_URI = "git://github.com/rhinstaller/pykickstart.git;protocol=https;branch=pykickstart-2 \
           "
SRCREV = "c278e56e7a951596f91aa0f0d204979667d7b5ab"

inherit setuptools3

