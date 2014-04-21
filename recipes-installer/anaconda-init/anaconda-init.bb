DESCRIPTION = "Simple Init Script for Anaconda"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://anaconda-init \
           file://Xusername \
           file://COPYING"

S = "${WORKDIR}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# For nm-online
#RDEPENDS_${PN} = "networkmanager-tests"

# For mount -oloop=/dev/loopX, busybox's mount doesn't support this.
RDEPENDS_${PN} = "util-linux"

do_install() {
    install -d ${D}/${sysconfdir}
    install -d ${D}/${sysconfdir}/init.d
    install -m 0755 anaconda-init ${D}${sysconfdir}/init.d/anaconda-init
    if [ "${ROOTLESS_X}" = "1" ] ; then
        install -d ${D}/etc/X11
        install Xusername ${D}/etc/X11
    fi
}

inherit update-rc.d useradd

INITSCRIPT_NAME = "anaconda-init"
INITSCRIPT_PARAMS = "start 30 2 3 4 5 . stop 20 0 1 6 ."

# Use fixed Xusername of xuser for now, this will need to be
# fixed if the Xusername changes from xuser
USERADD_PACKAGES = "${PN}"
USERADD_PARAM_${PN} = "--create-home \
                       --groups video,tty,audio \
                       --user-group xuser"

