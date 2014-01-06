DESCRIPTION = "A live image init script"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
RDEPENDS_${PN} = "udev"
DEPENDS = "virtual/kernel"
SRC_URI = "file://init-live.sh"

RDEPENDS_${PN} = "udev udev-extraconf lvm2 \
                  util-linux util-linux-blkid util-linux-losetup \
                  util-linux-mount util-linux-umount"

do_compile() {
        :
}

do_install() {
        install -m 0755 ${WORKDIR}/init-live.sh ${D}/init
}

FILES_${PN} += " /init "

# Due to kernel depdendency
PACKAGE_ARCH = "${MACHINE_ARCH}"
