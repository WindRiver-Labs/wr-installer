# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "A python module to ease the manipulation with LUKS devices."
SUMMARY="Python bindings for cryptsetup"
HOMEPAGE = "http://code.google.com/p/cryptsetup/"
LICENSE = "GPLv2+"

DEPENDS = "python cryptsetup"
RDEPENDS_${PN} = "cryptsetup"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

PR = "r0"

inherit distutils

SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/python-cryptsetup/python-cryptsetup-0.1.4.tar.gz/9455d264032342e322bbcce7ce5697d9/python-cryptsetup-0.1.4.tar.gz \
           file://Makefile-support-clean.patch \
"
SRC_URI[md5sum] = "9455d264032342e322bbcce7ce5697d9"
SRC_URI[sha256sum] = "b07935f5b06f927b584172382710b47253c445bd1ecb32ff375fa8d2cbdefaa6"
