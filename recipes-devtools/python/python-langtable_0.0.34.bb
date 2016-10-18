DESCRIPTION = "langtable is used to guess reasonable defaults for locale,\
keyboard, territory"
HOMEPAGE = "https://github.com/mike-fabian/langtable/"
LICENSE = "GPLv3+"
SECTION = "devel/python"

LIC_FILES_CHKSUM = "file://COPYING;md5=d32239bcb673463ab874e80d47fae504"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "e3accfea3a7a1a0dcdca0593e19118a838623f59"
PV = "0.0.34+git${SRCPV}"
SRC_URI = "git://github.com/mike-fabian/langtable.git;branch=master \
"

inherit setuptools pythonnative

DISTUTILS_INSTALL_ARGS = "--root=${D} \
    --prefix=${prefix} \
    --install-lib=${PYTHON_SITEPACKAGES_DIR} \
    --install-data=${datadir}/langtable"

FILES_${PN} += "${datadir}/*"
