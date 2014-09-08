# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "A python library for handling exceptions"
DESCRIPTION = "The python-meh package is a python library for handling, saving, and reporting \
exceptions."
HOMEPAGE = "http://git.fedorahosted.org/git/?p=python-meh.git"
LICENSE = "GPLv2+"
# yum?
DEPENDS = "python dbus python-pygtk libglade rpm openssh libnewt"
PR = "r0"

inherit autotools-brokensep pythonnative

export BUILD_SYS
export HOST_SYS
export STAGING_LIBDIR
export STAGING_INCDIR

SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/python-meh/python-meh-0.11.tar.gz/c2d412c275dd1675d4e3b174696fd8ca/python-meh-0.11.tar.gz \
	   file://Install-to-usr-instead-of-usr-local.patch"
SRC_URI[md5sum] = "c2d412c275dd1675d4e3b174696fd8ca"
SRC_URI[sha256sum] = "99e196828b774445b78362696570da2219c1cd2ac6d41054220ab9763e3d1d6c"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

FILES_${PN} += "/usr/lib/${PYTHON_DIR}/site-packages/python_meh* /usr/lib/${PYTHON_DIR}/site-packages/meh"

do_install() {
    oe_runmake DESTDIR=${D} RPM_BUILD_ROOT=${D} install
}
