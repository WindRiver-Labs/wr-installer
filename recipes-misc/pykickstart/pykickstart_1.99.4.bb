DESCRIPTION = "A python library for manipulating kickstart files"
HOMEPAGE = "http://fedoraproject.org/wiki/pykickstart"
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS = "python"
RDEPENDS_${PN} = "python"

SRC_URI = "http://mirror.itc.virginia.edu/fedora/releases/16/Everything/source/SRPMS//pykickstart-1.99.4-1.fc16.src.rpm;extract=pykickstart-1.99.4.tar.gz \
           file://pykickstart-read-ks-for-liveimg.patch \
           file://pykickstart-import-liveimg.patch \
           file://parser.py-retry-to-invoke-urlread-with-timeout.patch \
           file://add-status-window-while-retrying-to-fetch-.patch \
           "
SRC_URI[md5sum] = "5d3d07425bc2e6a3e7016d22354a48f8"
SRC_URI[sha256sum] = "96007ad2cf65597dd92868abf48c3be01463fc2c9d381d8aba4a87f6d17c3060"

inherit python-dir pythonnative

export STAGING_INCDIR
export STAGING_LIBDIR
export BUILD_SYS
export HOST_SYS
export PYTHON_VER
export PYTHON_SITEPACKAGES_DIR

FILES_${PN}-doc += "${datadir}/doc/${PN}-${PV}"
FILES_${PN} += "${bindir} ${PYTHON_SITEPACKAGES_DIR}/pykickstart*"

do_compile() {
    oe_runmake -C po
}

do_install() {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}
    STAGING_INCDIR=${STAGING_INCDIR} \
    STAGING_LIBDIR=${STAGING_LIBDIR} \
    PYTHONPATH=${D}${PYTHON_SITEPACKAGES_DIR} \
    BUILD_SYS=${BUILD_SYS} HOST_SYS=${HOST_SYS} \
    ${STAGING_BINDIR_NATIVE}/python-native/python setup.py install --install-lib=${D}${PYTHON_SITEPACKAGES_DIR} ${DISTUTILS_INSTALL_ARGS} || \
    bbfatal "python setup.py install execution failed."
    oe_runmake -C po RPM_BUILD_ROOT="${D}" install
}
 
