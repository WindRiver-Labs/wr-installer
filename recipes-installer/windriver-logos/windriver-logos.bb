DESCRIPTION = "Wind River logos for branding"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://syslinux-splash.png \
           file://splash.png \
           file://sidebar-logo.png \
           file://topbar-bg.png \
           file://anaconda-selected-icon.png \
           file://dialog-warning-symbolic.png \
           file://banner_wrlinux_750x120.png \
           file://banner_wrlinux_800x88.png \
           file://COPYING"

S = "${WORKDIR}"

PACKAGE_ARCH = "all"

FILES_${PN} = "${datadir}/anaconda"

do_install() {
    install -d ${D}/${datadir}/anaconda/boot
    install -m 0755 syslinux-splash.png ${D}${datadir}/anaconda/boot
    install -d ${D}/${datadir}/anaconda/pixmaps
    install -m 0755 splash.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 sidebar-logo.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 topbar-bg.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 anaconda-selected-icon.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 dialog-warning-symbolic.png ${D}${datadir}/anaconda/pixmaps
    install -d ${D}/${datadir}/anaconda/pixmaps/rnotes/en
    install -m 0755 banner_*.png ${D}/${datadir}/anaconda/pixmaps/rnotes/en
}
