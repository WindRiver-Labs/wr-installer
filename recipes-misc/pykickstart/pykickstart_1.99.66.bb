DESCRIPTION = "A python library for manipulating kickstart files"
HOMEPAGE = "http://fedoraproject.org/wiki/pykickstart"
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS = "python3"
RDEPENDS_${PN} = "python3"

S = "${WORKDIR}/git"
SRC_URI = "git://github.com/rhinstaller/pykickstart.git;protocol=https;branch=rhel7-branch \
           file://0001-parser.py-retry-to-invoke-urlread-with-timeout.patch \
           file://0002-support-authentication-for-kickstart.patch \
           file://0003-tweak-native-language-support.patch \
           file://0004-pykickstart-parser.py-add-lock-for-readKickstart-and.patch \
           file://0005-add-comments-of-shutdown-for-user.patch \
           "
SRCREV = "1dafd3f3daca0d446f09d431634ff20d0a8d73c7"

inherit setuptools3

