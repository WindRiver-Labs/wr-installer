# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "This package provides Python bindings for Network Security Services \
(NSS) and the Netscape Portable Runtime (NSPR). \
\
NSS is a set of libraries supporting security-enabled client and \
server applications. Applications built with NSS can support SSL v2 \
and v3, TLS, PKCS #5, PKCS #7, PKCS #11, PKCS #12, S/MIME, X.509 v3 \
certificates, and other security standards. Specific NSS \
implementations have been FIPS-140 certified."
SUMMARY="Python bindings for Network Security Services (NSS)"
HOMEPAGE = "http://www.mozilla.org/projects/security/pki/python-nss/"
LICENSE = "MPLv1.1 | GPLv2+ | LGPLv2+"

DEPENDS = "python-native nspr nss"
RDEPENDS_${PN} = "python nspr"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LIC_FILES_CHKSUM = "file://LICENSE.gpl;md5=751419260aa954499f7abaabaa882bbe \  
file://LICENSE.lgpl;md5=243b725d71bb5df4a1e5920b344b86ad \ 
file://LICENSE.mpl;md5=4d06cb6baf2fcfbe08cd1165e2a1413a"

inherit distutils

CFLAGS += "-fno-strict-aliasing"

SRC_URI = "https://ftp.mozilla.org/pub/security/python-nss/releases/PYNSS_RELEASE_0_12_0/src/${BP}.tar.bz2 \
           file://fix-include-dirs.patch \
           file://fix-pynss.patch"
SRC_URI[md5sum] = "f47ca0cad3504740ba3c8fde11715b29"
SRC_URI[sha256sum] = "e1084fef686f5b2f74f47fa46a7403d8b747ad14be7d9b3685b1bb105a4283cb"
