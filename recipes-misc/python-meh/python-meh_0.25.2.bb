SUMMARY = "A python library for handling exceptions"
DESCRIPTION = "The python-meh package is a python library for handling, saving, and reporting \
exceptions."
HOMEPAGE = "http://git.fedorahosted.org/git/?p=python-meh.git"
LICENSE = "GPLv2+"
# yum?
DEPENDS = "python dbus python-pygobject libglade \
           rpm openssh libnewt gettext-native \
"

inherit autotools-brokensep pythonnative

export BUILD_SYS
export HOST_SYS
export STAGING_LIBDIR
export STAGING_INCDIR

S = "${WORKDIR}/git"

SRC_URI = "git://github.com/rhinstaller/python-meh.git;protocol=https;branch=rhel7-branch \
           file://tweak-native-language-support.patch \
"
SRCREV = "92195e3f19489ab55ed5187b77618a759c3256fb"

LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

FILES_${PN} += "${PYTHON_SITEPACKAGES_DIR}/* "

do_compile() {
    oe_runmake po-empty
}

do_install() {
    oe_runmake DESTDIR=${D} \
               RPM_BUILD_ROOT=${D} \
               PYTHON_SITEPACKAGES_DIR=${PYTHON_SITEPACKAGES_DIR} \
               prefix=${prefix} \
               install
}
