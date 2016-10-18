DESCRIPTION = "A graphical interface for modifying the keyboard."
HOMEPAGE = "https://fedorahosted.org/system-config-keyboard/"
LICENSE = "GPLv2+"

LIC_FILES_CHKSUM = "file://COPYING;md5=fc6dce656150c601a734bcc41dd47bed"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

RDEPENDS_${PN} = "python"

DEPENDS += "intltool-native gettext-native"

SRC_URI = "https://fedorahosted.org/releases/s/y/system-config-keyboard/system-config-keyboard-${PV}.tar.gz"
SRC_URI[md5sum] = "012b1aec6d237f853bea6824e71d19ed"
SRC_URI[sha256sum] = "ba446a871fa4db096930825cbc656541cac5e0302e955e3656289532967159ed"


SRC_URI += "file://use-datadir.patch"

PACKAGES += "${PN}-base"

FILES_${PN} = " \
${sbindir}/system-config-keyboard \
${bindir}/system-config-keyboard \
${datadir}/system-config-keyboard \
${datadir}/firstboot/modules/* \
${datadir}/applications/system-config-keyboard.desktop \
${sysconfdir}/security/console.apps/system-config-keyboard \
${sysconfdir}/pam.d/system-config-keyboard \
${datadir}/icons/hicolor/48x48/apps/system-config-keyboard.png \
"

inherit python-dir 

export STAGING_INCDIR
export STAGING_LIBDIR
export BUILD_SYS
export HOST_SYS
export PYTHON_SITEPACKAGES_DIR

FILES_${PN}-base = "/usr/lib/python* ${PYTHON_SITEPACKAGES_DIR}"

do_install() {
    # STAGING_INCDIR=${STAGING_INCDIR} \
    # STAGING_LIBDIR=${STAGING_LIBDIR} \
    # BUILD_SYS=${BUILD_SYS} HOST_SYS=${HOST_SYS} \
    # PYTHON_SITEPACKAGES_DIR=${PYTHON_SITEPACKAGES_DIR} \
    oe_runmake INSTROOT="${D}" PREFIX=${prefix} SYSCONFDIR=${sysconfdir} \
        DATADIR=${datadir} BINDIR=${bindir} SBINDIR=${sbindir} \
        MANDIR=${mandir} install
}
