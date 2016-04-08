# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Python modules for dealing with block devices"
DESCRIPTION = "The pyblock contains Python modules for dealing with block devices."
HOMEPAGE = "http://fedoraproject.org/wiki/Anaconda"
LICENSE = "GPLv2 | GPLv3"

inherit pythonnative pkgconfig gettext

DEPENDS = "lvm2 dmraid python"
RDEPENDS_${PN} = "lvm2 python-pyparted python"

PR = "r0"

S = "${WORKDIR}/pyblock-${PV}"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

inherit pythonnative python-dir

export STAGING_INCDIR
export STAGING_LIBDIR
export HOST_SYS
export BUILD_SYS
export PYTHON_DIR

# CFLAGS += "-I${STAGING_INCDIR}/${PYTHON_DIR} -fPIC -fno-strict-aliasing"
# LDFLAGS += "-lpython${PYTHON_BASEVERSION}"

LIC_FILES_CHKSUM = "file://COPYING;md5=9a30850080b882bcdfa5f32235204505"

SRC_URI = "https://fedorahosted.org/releases/p/y/pyblock/pyblock-${PV}.tar.bz2 \
           file://fix-makefile.patch"
SRC_URI[md5sum] = "f6d33a8362dee358517d0a9e2ebdd044"
SRC_URI[sha256sum] = "f6cef88969300a6564498557eeea1d8da58acceae238077852ff261a2cb1d815"

CFLAGS += "-fPIC -fno-strict-aliasing"

export USESELINUX = '0'

EXTRA_OEMAKE += "-e DESTDIR=${D} SITELIB=${PYTHON_SITEPACKAGES_DIR}"

FILES_${PN} += "${PYTHON_SITEPACKAGES_DIR}/block/*py ${PYTHON_SITEPACKAGES_DIR}/block/dm*so"
FILES_${PN}-dbg += "${PYTHON_SITEPACKAGES_DIR}/block/.debug"

do_install() {
    oe_runmake DESTDIR=${D} SITELIB=${PYTHON_SITEPACKAGES_DIR} install
}
