SUMMARY = "Tools for taking the MD5 sum of ISO images"
DESCRIPTION = "Tools for taking the MD5 sum of ISO images"

DEPENDS = "popt python openssl curl"
DEPENDS_virtclass-native += "popt-native python-native"

RDEPENDS_${PN} = "openssl curl"
RDEPENDS_${PN}-python = "${PN}-python"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

SRC_URI = "git://github.com/rhinstaller/isomd5sum.git;branch=master \
           file://0001-tweak-install-prefix.patch \
"

S = "${WORKDIR}/git"
inherit python-dir

EXTRA_OEMAKE += "DESTDIR='${D}' PYTHONINCLUDE='-I${STAGING_INCDIR}/${PYTHON_DIR}'"
EXTRA_OEMAKE += "PYTHONSITEPACKAGES='${PYTHON_SITEPACKAGES_DIR}' \
"

PARALLEL_MAKE = ""

do_install () {
    oe_runmake install
}
PACKAGES += "${PN}-python ${PN}-python-dbg"

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/pyisomd5sum.so"
FILES_${PN}-python-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug/pyisomd5sum.so"

SRCREV = "2f0df17f636232178072ec02522e3c3ca6e6dbde"

BBCLASSEXTEND = "native"
    python-requests \
