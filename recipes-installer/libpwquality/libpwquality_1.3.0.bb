DESCRIPTION = "Library for password quality checking and generating random passwords"
HOMEPAGE = "https://github.com/libpwquality/libpwquality"
SECTION = "devel/python"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bd2f1386df813a459a0c34fde676fc2"

SRCNAME = "libpwquality"
SRC_URI = "https://github.com/${SRCNAME}/${SRCNAME}/releases/download/${SRCNAME}-${PV}/${SRCNAME}-${PV}.tar.bz2 \
           file://add-missing-python-include-dir-for-cross.patch \
"
SRC_URI[md5sum] = "2a3d4ba1d11b52b4f6a7f39622ebf736"
SRC_URI[sha256sum] = "74d2ea90e103323c1f2d6a6cc9617cdae6877573eddb31aaf31a40f354cc2d2a"

S = "${WORKDIR}/${SRCNAME}-${PV}"

DEPENDS = "cracklib virtual/gettext python3"
RDEPENDS_${PN} = "libpam"
RDEPENDS_${PN}-python3 = "${PN}"

inherit autotools python3native

B = "${S}"

export PYTHON_DIR
export BUILD_SYS
export HOST_SYS
export STAGING_LIBDIR
export STAGING_INCDIR

EXTRA_OECONF += "--with-python-rev=${PYTHON_BASEVERSION} \
                 --with-python-binary=${STAGING_BINDIR_NATIVE}/${PYTHON_PN}-native/${PYTHON_PN} \
                 --with-pythonsitedir=${PYTHON_SITEPACKAGES_DIR} \
                 --libdir=${libdir} \
"

PACKAGES += "${PN}-python3 ${PN}-python3-dbg"
FILES_${PN} += "${libdir}/security/pam_pwquality.so"
FILES_${PN}-dbg += "${libdir}/security/.debug"
FILES_${PN}-staticdev += "${libdir}/security/pam_pwquality.a"
FILES_${PN}-dev += "${libdir}/security/pam_pwquality.la"
FILES_${PN}-python3 = "${PYTHON_SITEPACKAGES_DIR}/*"
FILES_${PN}-python3-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug"
