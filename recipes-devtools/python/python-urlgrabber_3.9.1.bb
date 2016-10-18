DESCRIPTION = "urlgrabber is a pure python package that drastically simplifies the fetching of files."
HOMEPAGE = "http://linux.duke.edu/projects/urlgrabber/"
SECTION = "devel/python"
PRIORITY = "optional"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=68ad62c64cc6c620126241fd429e68fe"
PR = "r0"

SRC_URI = "http://urlgrabber.baseurl.org/download/urlgrabber-${PV}.tar.gz"
SRC_URI += "file://urlgrabber-HEAD.patch"

S = "${WORKDIR}/urlgrabber-${PV}"

DEPENDS = "python-pycurl-native"
RDEPENDS_${PN} = "python-pycurl"

FILESEXTRAPATHS_prepend := "${THISDIR}/python-urlgrabber:"

inherit distutils

SRC_URI[md5sum] = "00c8359bf71062d0946bacea521f80b4"
SRC_URI[sha256sum] = "4437076c8708e5754ea04540e46c7f4f233734ee3590bb8a96389264fb0650d0"
