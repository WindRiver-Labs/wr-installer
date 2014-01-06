DESCRIPTION = "Lohit TrueType font for Punjabi Language"
HOMEPAGE = "https://fedorahosted.org/lohit/"
LICENSE = "OFL-1.1"
DEPENDS = "fontforge-native"
PR = "r0"

FONTNAME="lohit-punjabi"
FONTCONF="65-0-${FONTNAME}.conf"

LIC_FILES_CHKSUM="file://COPYRIGHT;md5=ce967831f2feec5293f4038a8cf449e2 \
                  file://OFL.txt;md5=e56537d157e0ee370c0d8468da33e245"
SRC_URI = "https://fedorahosted.org/releases/l/o/lohit/${FONTNAME}-${PV}.tar.gz"
SRC_URI[md5sum] = "ce74dcc10d671bc4e40595e9c29eb7de"
SRC_URI[sha256sum] = "a6af1444c6c93a5c3eda0c09bfe93a75d7d5e055720d5c90e4c006e43cac47cb"

S = "${WORKDIR}/${FONTNAME}-${PV}"

do_install() {
    install -m 0755 -d ${D}${datadir}/fonts/${FONTNAME}
    install -m 0644 -p ${S}/*.ttf ${D}${datadir}/fonts/${FONTNAME}

    install -m 0755 -d ${D}${datadir}/fontconfig/conf.avail \
                       ${D}${sysconfdir}/fonts/confd.d

    install -m 0644 -p ${S}/66-${FONTNAME}.conf \
            ${D}${datadir}/fontconfig/conf.avail/${FONTCONF}
    ln -s ${datadir}/fontconfig/conf.avail/${FONTCONF} \
          ${D}${sysconfdir}/fonts/confd.d/${FONTCONF}
}

FILES_${PN} += "${datadir}"
