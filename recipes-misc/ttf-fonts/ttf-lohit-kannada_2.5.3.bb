DESCRIPTION = "Lohit TrueType font for Kannada Language"
HOMEPAGE = "https://fedorahosted.org/lohit/"
LICENSE = "OFL-1.1"
DEPENDS = "fontforge-native"
PR = "r0"

FONTNAME="lohit-kannada"
FONTCONF="66-${FONTNAME}.conf"

LIC_FILES_CHKSUM="file://COPYRIGHT;md5=ce967831f2feec5293f4038a8cf449e2 \
                  file://OFL.txt;md5=e56537d157e0ee370c0d8468da33e245"
SRC_URI = "https://fedorahosted.org/releases/l/o/lohit/${FONTNAME}-${PV}.tar.gz"
SRC_URI[md5sum] = "2a58bff5e1b0c7da56bd6eb58eea5896"
SRC_URI[sha256sum] = "c1be2e1b1cb203a6cb93f2495a48cc01f46bf321e2e24863c0835b8ba4750a0c"

S = "${WORKDIR}/${FONTNAME}-${PV}"

do_install() {
    install -m 0755 -d ${D}${datadir}/fonts/${FONTNAME}
    install -m 0644 -p ${S}/*.ttf ${D}${datadir}/fonts/${FONTNAME}

    install -m 0755 -d ${D}${datadir}/fontconfig/conf.avail \
                       ${D}${sysconfdir}/fonts/confd.d

    install -m 0644 -p ${S}/${FONTCONF} \
            ${D}${datadir}/fontconfig/conf.avail/${FONTCONF}
    ln -s ${datadir}/fontconfig/conf.avail/${FONTCONF} \
          ${D}${sysconfdir}/fonts/confd.d/${FONTCONF}
}

FILES_${PN} += "${datadir}"
