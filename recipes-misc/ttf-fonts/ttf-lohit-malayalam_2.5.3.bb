DESCRIPTION = "Lohit TrueType font for Malayalam Language"
HOMEPAGE = "https://fedorahosted.org/lohit/"
LICENSE = "OFL-1.1"
DEPENDS = "fontforge-native"
PR = "r0"

FONTNAME="lohit-malayalam"
FONTCONF="67-${FONTNAME}.conf"

LIC_FILES_CHKSUM="file://COPYRIGHT;md5=ce967831f2feec5293f4038a8cf449e2 \
                  file://OFL.txt;md5=e56537d157e0ee370c0d8468da33e245"
SRC_URI = "https://fedorahosted.org/releases/l/o/lohit/${FONTNAME}-${PV}.tar.gz"
SRC_URI[md5sum] = "7ef7c1dad5ae0792111edbf3776ee78c"
SRC_URI[sha256sum] = "dbee494f0ef7aa6be5ed2a208c61d1fd56025e4c7cf3c09071b51a342b678b23"

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
