DESCRIPTION = "Default GTK Theme for Wind River Linux"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://gtkrc \
           file://index.theme \
           file://COPYING"

S = "${WORKDIR}"

PACKAGE_ARCH = "all"

FILES_${PN} = "${sysconfdir}/gtk-2.0/gtkrc ${datadir}/themes/WindRiver/index.theme"

do_install() {
    install -d ${D}/${sysconfdir}
    install -d ${D}/${sysconfdir}/gtk-2.0
    install -m 0755 gtkrc ${D}${sysconfdir}/gtk-2.0/gtkrc
    install -d ${D}/${datadir}/themes/WindRiver
    install -m 0755 index.theme ${D}${datadir}/themes/WindRiver
}
