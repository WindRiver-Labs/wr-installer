# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Python module for GNU parted"
DESCRIPTION = "Python module for the parted library.  It is used for manipulating \
partition tables. \
"
HOMEPAGE = "http://fedorahosted.org/pyparted"
LICENSE = "GPLv2+"

DEPENDS = "parted"
RDEPENDS_${PN} = "parted python"

inherit pythonnative pkgconfig distutils

DEPENDS += "parted"

PR = "r1"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

SRC_URI = "https://fedorahosted.org/releases/p/y/pyparted/pyparted-${PV}.tar.gz"
SRC_URI[md5sum] = "e9cd0c94c71ac17755f71a8e1561eac2"
SRC_URI[sha256sum] = "c9978380e18fe284dd5b74a5043d259ef8512323fa3c85d08c7a5f3bb9563326"
