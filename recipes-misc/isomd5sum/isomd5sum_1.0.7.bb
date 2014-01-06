SUMMARY = "Tools for taking the MD5 sum of ISO images"
DESCRIPTION = "Tools for taking the MD5 sum of ISO images"

DEPENDS = "popt python openssl curl"
DEPENDS_virtclass-native += "popt-native python-native"

RDEPENDS_${PN} = "openssl curl"
RDEPENDS_${PN}-python = "${PN}-python"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

SRC_URI = "http://download.fedoraproject.org/pub/fedora/linux/releases/16/Everything/source/SRPMS/isomd5sum-1.0.7-1.fc16.src.rpm;extract=isomd5sum-1.0.7.tar.bz2 \
           file://python-incdir.patch \
           file://unused_variable.patch \
           file://use-prefix.patch \
           file://Change-linking-order-of-lpopt.patch \
           file://use_ldflags.patch"

inherit python-dir

EXTRA_OEMAKE += "DESTDIR='${D}' PYTHON_DIR='${PYTHON_DIR}' PYTHONINCLUDE='${STAGING_INCDIR}/${PYTHON_DIR}'"
CFLAGS += "-D_GNU_SOURCE=1 -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE=1 -D_LARGEFILE64_SOURCE=1 -fPIC -I${STAGING_INCDIR}/${PYTHON_DIR}"
BUILD_CFLAGS += "-D_GNU_SOURCE=1 -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE=1 -D_LARGEFILE64_SOURCE=1 -fPIC -I${STAGING_INCDIR_NATIVE}/${PYTHON_DIR}"

PARALLEL_MAKE = ""

do_install () {
    oe_runmake install
}
PACKAGES += "${PN}-python ${PN}-python-dbg"

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/pyisomd5sum.so"
FILES_${PN}-python-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug/pyisomd5sum.so"

SRC_URI[md5sum] = "2e571325c7ca4c40bcc924c9956a190b"
SRC_URI[sha256sum] = "b50a57402b0e3ba6127fbc1cb277a0c94132851d1763c6c3a15413a518b6cb7d"

BBCLASSEXTEND = "native"
