DESCRIPTION = "Simple Init Script for Anaconda"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://anaconda-init \
           file://anaconda-init.service \
           file://anaconda-init-screen@.service \
           file://anaconda-init.target \
           file://Xusername \
           file://COPYING"

S = "${WORKDIR}"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# For nm-online
#RDEPENDS_${PN} = "networkmanager-tests"

# For mount -oloop=/dev/loopX, busybox's mount doesn't support this.
RDEPENDS_${PN} = "util-linux"

# While systemd, we need screen to control anaconda-init first boot
RDEPENDS_${PN} += " \
    ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'screen', '', d)} \
"

inherit systemd

SYSTEMD_SERVICE_${PN} = "anaconda-init.service \
                         anaconda-init-screen@.service \
                         anaconda-init.target \
"

CLEANBROKEN = "1"

do_install() {
    install -d ${D}/${sbindir}
    install -m 0755 ${WORKDIR}/anaconda-init ${D}${sbindir}/anaconda-init
    if [ -n "${EULA_DIR}" ]; then
        sed -i "s#@EULA_DIR@#${EULA_DIR}#g" ${D}${sbindir}/anaconda-init
    else
        bbwarn "EULA_DIR is NULL, please set it in a local conf"
        bbwarn "The EULA_DIR helps user to locate End User License Agreement during image installation"
        sed -i "s#@EULA_DIR@##g" ${D}${sbindir}/anaconda-init
    fi
    install -d ${D}/${sysconfdir}
    install -d ${D}/${sysconfdir}/init.d
    ln -sf ${sbindir}/anaconda-init ${D}/${sysconfdir}/init.d/anaconda-init
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/anaconda-init.service \
                    ${WORKDIR}/anaconda-init-screen@.service \
                    ${WORKDIR}/anaconda-init.target \
               ${D}${systemd_unitdir}/system


    sed -i -e 's,@SBINDIR@,${sbindir},g' -e 's,@ROOT_HOME@,${ROOT_HOME},g' ${D}${systemd_unitdir}/system/anaconda-init.service \
                                                                           ${D}${systemd_unitdir}/system/anaconda-init-screen@.service
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

# Location of End User License Agreement
EULA_DIR ??= ""
