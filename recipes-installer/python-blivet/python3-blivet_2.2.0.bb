DESCRIPTION = "A python module for system storage configuration"
HOMEPAGE = "http://fedoraproject.org/wiki/blivet"
LICENSE = "LGPLv2+"
SECTION = "devel/python"

LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "b70da73d701831c29830904c16b9eb6187b9c13e"
PV = "2.2+git${SRCPV}"
SRC_URI = "git://github.com/rhinstaller/blivet;branch=2.2-release \
           file://0001-use-oe-variable-to-replace-hardcoded-dir.patch \
"

inherit setuptools3 python3native

RDEPENDS_${PN} = "pykickstart python3-pyudev \
                  parted python3-pyparted device-mapper-multipath \
                  lsof cryptsetup \
"

FILES_${PN} += " \
    ${datadir}/dbus-1/system-services \
"

inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "blivet.service"
