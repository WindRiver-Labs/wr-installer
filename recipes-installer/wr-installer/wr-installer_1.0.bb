SUMMARY = "Basic target installer script."
DESCRIPTION = "Adds an installer for installing image onto x86 target system."
SECTION = "extra"
PRINC = "1"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=3f40d7994397109285ec7b81fdeb3b58 \
            file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
LICENSE = "MIT"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "file://S99installer.sh \
           file://installer.conf.example \
"

RDEPENDS_${PN} = "grub parted python-smartpm e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-fsck e2fsprogs-tune2fs e2fsprogs-badblocks module-init-tools"

#To enable grub 0.97 uncomment the following. It may need to be put into local.conf
#PREFERRED_VERSION_grub = "0.97"

do_install () {
    install -d ${D}${sysconfdir}/
	install -m 0644 ${WORKDIR}/installer.conf.example ${D}${sysconfdir}/

    install -d ${D}${sysconfdir}/rcS.d
	install -m 0755 ${WORKDIR}/S99installer.sh ${D}${sysconfdir}/rcS.d/
}
