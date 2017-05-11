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
           file://0001-comment-out-selinux.patch \
           file://0002-run_program-support-timeout.patch\
           file://0003-support-infinit-timeout.patch \
           file://0004-Mount-var-volatile-during-install.patch \
           file://0005-update-fstab-by-appending.patch \
           file://0006-fix-new.roots-object-is-not-iterable.patch \
           file://0007-fix-incorrect-timeout-while-system-time-changed.patch \
           file://0008-tweak-btrfs-packages.patch \
           file://0009-invoking-mount-with-infinite-timeout.patch \
           file://0010-use-oe-variable-to-replace-hardcoded-dir.patch \
"

inherit setuptools3 python3native

RDEPENDS_${PN} = "pykickstart python3-pyudev \
                  parted python3-pyparted device-mapper-multipath \
                  lsof cryptsetup libblockdev \
                  libbytesize util-linux-pylibmount \
"

FILES_${PN} += " \
    ${datadir}/dbus-1/system-services \
"

inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "blivet.service"
