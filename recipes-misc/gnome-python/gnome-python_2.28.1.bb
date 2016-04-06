# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "PyGNOME Python extension module"
DESCRIPTION = "The gnome-python package contains the source packages for the Python \
bindings for GNOME called PyGNOME."
HOMEPAGE = "http://download.gnome.org/sources/gnome-python/"
LICENSE = "LGPLv2+"
DEPENDS = "libgnome libgnomecanvas python-pygobject"
PR = "r0"

S = "${WORKDIR}/gnome-python-2.28.0"

inherit pkgconfig python-dir pythonnative autotools

LIC_FILES_CHKSUM = "file://COPYING;md5=55ca817ccb7d5b5b66355690e9abc605"

SRC_URI = "http://ftp.gnome.org/mirror/gnome.org/bindings/2.28/2.28.1/sources/python/gnome-python-2.28.0.tar.gz"
SRC_URI[md5sum] = "68ce9bd801092e9c26081bca475816de"
SRC_URI[sha256sum] = "52db4490fba4c6240ec99cfa3eb00ffbc3fe82bcb57cf45e84e8be29845002f7"

# EXTRA_OEMAKE = "SUBDIRS='gnomecanvas'"
EXTRA_OECONF += "--enable-gnomecanvas"

export HOST_SYS
export BUILD_SYS
export STAGING_LIBDIR
export STAGING_INCDIR

FILES_${PN}-dbg += "${libdir}/gnome-vfs-2.0/modules/.debug \
                    ${PYTHON_SITEPACKAGES_DIR}/pygtk-2.0/.debug \
                    ${PYTHON_SITEPACKAGES_DIR}/gtk-2.0/.debug \
                    ${PYTHON_SITEPACKAGES_DIR}/gtk-2.0/gnome/.debug \
                    ${PYTHON_SITEPACKAGES_DIR}/gtk-2.0/gnomevfs/.debug"
FILES_${PN} += "${libdir}/gnome-vfs-2.0 ${PYTHON_SITEPACKAGES_DIR} ${datadir}/pygtk"
