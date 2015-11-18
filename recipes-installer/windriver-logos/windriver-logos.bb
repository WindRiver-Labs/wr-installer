DESCRIPTION = "Wind River logos for branding"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://syslinux-splash.png \
           file://splash.png \
           file://anaconda_header.png \
           file://progress_first.png \
           file://COPYING"

S = "${WORKDIR}"

PACKAGE_ARCH = "all"

FILES_${PN} = "${datadir}/anaconda"

do_install() {
    install -d ${D}/${datadir}/anaconda/boot
    install -m 0755 syslinux-splash.png ${D}${datadir}/anaconda/boot
    install -d ${D}/${datadir}/anaconda/pixmaps
    install -m 0755 splash.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 anaconda_header.png ${D}${datadir}/anaconda/pixmaps
    install -m 0755 progress_first.png ${D}${datadir}/anaconda/pixmaps
}
