DESCRIPTION = "Unicode Sinhyala font by Lanka Linux User Group"
HOMEPAGE = "http://sinhala.sourceforge.net/"
LICENSE = "GPLv2"
DEPENDS = "fontforge-native"
PR = "r0"

FONTNAME="sinhala-lklug"
FONTCONF="65-${FONTNAME}.conf"

LIC_FILES_CHKSUM="file://COPYING;md5=751419260aa954499f7abaabaa882bbe"
SRC_URI = "http://ftp.de.debian.org/debian/pool/main/t/ttf-sinhala-lklug/${PN}_${PV}.orig.tar.gz \
           file://65-sinhala-lklug.conf \
           file://fix_convert_ff.patch"

SRC_URI[md5sum] = "0dfdacf09cd1a1f67f95b8628f276890"
SRC_URI[sha256sum] = "0fbfd393ff01ec66afdbb7c7f485fcc6026c7db8c61b2c5f834a4588957a7586"


do_install() {
    install -m 0755 -d ${D}${datadir}/fonts/${FONTNAME}
    install -m 0644 -p ${S}/*.ttf ${D}${datadir}/fonts/${FONTNAME}

    install -m 0755 -d ${D}${datadir}/fontconfig/conf.avail \
                       ${D}${sysconfdir}/fonts/confd.d

    install -m 0644 -p ${WORKDIR}/${FONTCONF} \
            ${D}${datadir}/fontconfig/conf.avail/${FONTCONF}
    ln -s ${datadir}/fontconfig/conf.avail/${FONTCONF} \
          ${D}${sysconfdir}/fonts/confd.d/${FONTCONF}
}

FILES_${PN} += "${datadir}"
