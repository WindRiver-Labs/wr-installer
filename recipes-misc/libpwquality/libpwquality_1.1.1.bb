DESCRIPTION = "The libpwquality package contains a library used for password \
quality checking and generation of random passwords that pass the checks."

SUMMARY = "passwd check library"

LICENSE = "GPLv2 & BSD"
LIC_FILES_CHKSUM = "file://COPYING;md5=c02b9192315ff7850081a20ca2393154"

SRC_URI = "https://fedorahosted.org/releases/l/i/libpwquality/libpwquality-1.1.1.tar.bz2"

SRC_URI[md5sum] = "8fe4ef35f29e5dcd0db004455ea9e8b4"
SRC_URI[sha256sum] = "d11c71e88963feba1b06a594def201f2b4235680a8ac72ec6bbfc998e0acdf4e"

inherit autotools gettext pythonnative python-dir

do_configure_prepend() {
    # Use our python to build the python lib, we need a '\' in the end
    # of the Makefile, so use '\\\'.
    sed -i 's#python setup.py build#STAGING_INCDIR=${STAGING_INCDIR} \\\
         STAGING_LIBDIR=${STAGING_LIBDIR} \\\
         BUILD_SYS=${BUILD_SYS} HOST_SYS=${HOST_SYS} \\\
         ${STAGING_BINDIR_NATIVE}/python-native/python \\\
         setup.py build#' python/Makefile.am
}

FILES_${PN} += " \
    ${libdir}/security/pam_pwquality.so \
    ${libdir}/security/pam_pwquality.la \
    ${PYTHON_SITEPACKAGES_DIR}/pwquality.so \
"

FILES_${PN}-dbg += " \
    ${libdir}/security/.debug/pam_pwquality.so \
    ${PYTHON_SITEPACKAGES_DIR}/.debug/pwquality.so \
"

FILES_${PN}-staticdev += "${libdir}/security/pam_pwquality.a"
