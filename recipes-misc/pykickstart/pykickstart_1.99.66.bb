DESCRIPTION = "A python library for manipulating kickstart files"
HOMEPAGE = "http://fedoraproject.org/wiki/pykickstart"
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

DEPENDS = "python"
RDEPENDS_${PN} = "python libnewt-python"

S = "${WORKDIR}/git"
SRC_URI = "git://github.com/rhinstaller/pykickstart.git;protocol=https;branch=rhel7-branch \
           file://parser.py-retry-to-invoke-urlread-with-timeout.patch \
           file://support-authentication-for-kickstart.patch \
           file://tweak-native-language-support.patch \
           file://0001-pykickstart-parser.py-add-lock-for-readKickstart-and.patch \
           file://0002-add-comments-of-shutdown-for-user.patch \
           "
SRCREV = "73c9df14d539f2b59a356d8316675a6b7afbf4ac"

inherit pythonnative gettext

export STAGING_INCDIR
export STAGING_LIBDIR
export BUILD_SYS
export HOST_SYS
export PYTHON_VER
export PYTHON_SITEPACKAGES_DIR

FILES_${PN}-doc += "${datadir}/doc/${PN}-${PV}"
FILES_${PN} += "${bindir} ${PYTHON_SITEPACKAGES_DIR}/pykickstart*"

do_compile() {
    oe_runmake po-empty
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
 
