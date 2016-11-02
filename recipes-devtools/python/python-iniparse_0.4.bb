DESCRIPTION = "iniparse is a INI parser for Python"
HOMEPAGE = "http://code.google.com/p/iniparse/"
SECTION = "devel/python"
PRIORITY = "optional"

LICENSE = "MIT & PSF"
LIC_FILES_CHKSUM = "file://LICENSE;md5=52f28065af11d69382693b45b5a8eb54 \
                    file://LICENSE-PSF;md5=1c78a5bb3584b353496d5f6f34edb4b2"

SRCNAME = "iniparse"
SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/${BPN}/${SRCNAME}-${PV}.tar.gz/5e573e9e9733d97623881ce9bbe5eca6/${SRCNAME}-${PV}.tar.gz"
S = "${WORKDIR}/${SRCNAME}-${PV}"

inherit distutils

SRC_URI[md5sum] = "5e573e9e9733d97623881ce9bbe5eca6"
SRC_URI[sha256sum] = "abc1ee12d2cfb2506109072d6c21e40b6c75a3fe90a9c924327d80bc0d99c054"

do_install_append() {
        rm -rf ${D}${datadir}/share
}
