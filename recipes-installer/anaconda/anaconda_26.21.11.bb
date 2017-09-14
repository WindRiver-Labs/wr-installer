SUMMARY = "The anaconda package"
DESCRIPTION = "The anaconda package"
HOMEPAGE = "http://fedoraproject.org/wiki/Anaconda"
LICENSE = "GPLv2"
SECTION = "devel"

LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "e2fsprogs gettext libarchive \
           pango python3 rpm \
           "

DEPENDS += "libxklavier glade libxml2-native \
            gdk-pixbuf-native \
            "

S = "${WORKDIR}/git"

RDEPENDS_${PN} = "e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs \
                   e2fsprogs-tune2fs e2fsprogs-resize2fs \
                   ntfsprogs xfsprogs btrfs-tools nfs-utils-client \
                   parted dosfstools gzip libarchive lvm2 \
                   squashfs-tools openssh python3 python3-misc \
                   python3-modules  python3-dbus python3-pyparted \
                   python3-pykickstart \
                   dmidecode python3-meh python3-libreport localedef \
                   python3-pygobject python3-rpm grub usermode tigervnc \
                   tzdata tzdata-misc tzdata-posix tzdata-right tzdata-africa \
                   tzdata-americas tzdata-antarctica tzdata-arctic tzdata-asia \
                   tzdata-atlantic tzdata-australia tzdata-europe tzdata-pacific \
                   keybinder module-init-tools dnf util-linux efibootmgr \
                   ca-certificates isomd5sum \
                   btrfs-tools ntfs-3g iproute2 mdadm shadow chkconfig \
                   util-linux-swaponoff util-linux-uuidgen python3-blivet \
                   xrandr glibc-charmaps glibc-localedatas \
                   python3-pytz python3-langtable python3-libpwquality \
                   python3-ntplib libgnomekbd libtimezonemap \
                   procps python3-prctl rsync glibc-utils python3-pid \
                   python3-ordered-set python3-wrapt python3-coverage \
                   python3-requests-file python3-requests-ftp \
                   python3-blivetgui librsvg librsvg-gtk bash \
                "

RDEPENDS_${PN} += "networkmanager libnmutil libnmglib libnmglib-vpn \
                   network-manager-applet \
"

SRC_URI = "git://github.com/rhinstaller/anaconda;protocol=https;branch=f26-release \
           file://wrlinux.py \
           file://81-edit-sudoers.ks \
           file://0001-do-not-support-po.patch \
           file://0002-widgets-Makefile.am-do-not-compile-doc.patch \
           file://0003-Revert-Use-system-Python-when-running-Anaconda.patch \
           file://0004-pyanaconda-flags.py-drop-selinux-module.patch \
           file://0005-add-package-site-dir-for-installclass-searching.patch \
           file://0006-do-not-load-the-system-wide-Xresources.patch \
           file://0007-tweak-iso-mount-dir-and-kernel-name.patch \
           file://0008-dnfpayload.py-customize-for-WRLinux.patch \
           file://0009-Remove-unnecessary-noverifyssl-for-http-ftp-protocol.patch \
           file://0010-dynamic-detect-workable-locale.patch \
           file://0011-improve-thread-monitor.patch \
           file://0012-disable-audit.patch \
           file://0013-bootloader.py-Change-grub2-settings-to-match-oe-core.patch \
           file://0014-tweak-detect-kernel-version.patch \
           file://0015-tweak-grub-config-file-for-WRLinux.patch \
           file://0016-Revert-Use-time.tzset-to-apply-timezone-changes-when.patch \
           file://0017-kickstart-Authconfig-Firewall-Firstboot-Timezone.patch \
           file://0018-invisible-help-button.patch \
           file://0019-disable-non-implemented-functions.patch \
           file://0020-disable-geoloc-by-default.patch \
           file://0021-support-UEFI-boot.patch \
           file://0022-do-not-verify-ssl-certification-by-default.patch \
           file://0023-tweak-default-nfs-mount-point.patch \
           file://0024-fix-quoted-empty-string-failed.patch \
           file://0025-do-not-support-ISO-hold-by-hard-drive-partitions.patch \
           file://0026-fix-cannot-stat-usr-share-gettext-gettext.h.patch \
           file://0027-fix-Wind-River-boot-menu-not-work.patch \
           file://0028-tweak-bootloader-fs-type.patch \
           file://0029-support-timezone-setting.patch \
           file://0030-disable-ntp-support.patch \
           file://0031-do-not-support-manually-set-time.patch \
           file://0032-support-user-account-creation.patch \
           file://0033-detect-existence-of-Xorg.patch \
           file://0034-fix-write-network-conf-failed-while-liveinst.patch \
           file://0035-revert-commits-to-support-reboot-for-live-installs.patch \
           file://0036-text-repository-setting-do-not-support-local-ISO-fil.patch \
           file://0037-text-repository-setting-support-http-proxy.patch \
           file://0038-set-keyboard-xlayouts-with-us-by-default.patch \
           file://0039-text-do-not-support-network-setting-for-now.patch \
           file://0040-tweak-boot-storage-sanity-check.patch \
           file://0041-kickstart-do-not-support-network-configuration.patch \
           file://0042-support-to-get-kickstart-from-network.patch \
           file://0043-support-authentication-for-kickstart.patch \
           file://0044-support-downloading-file-from-http-ftp-server-to-tar.patch \
           file://0045-live-install-supports-kickstart.patch \
           file://0046-support-initramfs-boot.patch \
           file://0047-fix-hang-while-installed-system-reboot.patch \
           file://0048-fix-installed-system-boot-from-encrypt-fs-failed.patch \
           file://0049-installation-destination-disable-iSCSI-network-disks.patch \
           file://0050-update-region-while-city-changes.patch \
           file://0051-timezone-fix-set-US-Alaska-failed.patch \
           file://0052-remove-incorrect-prefix-of-addon-repo-url.patch \
           file://0053-fix-write-sysconfig-network-failed.patch \
           file://0054-pyanaconda-ui-gui-utils.py-tweak-mouse-arrow.patch \
           file://0055-tweak-search-location-of-new-kernel-pkg.patch \
           file://0056-always-write-fstab-after-install.patch \
           file://0057-invoke-grub-install-to-generate-efi-filesystem.patch \
           file://0058-do-not-support-closest-mirror.patch \
           file://0059-tweak-MAX_TREEINFO_DOWNLOAD_RETRIES.patch \
           file://0060-tweak-time-setting.patch \
           file://0061-set-CLEARPART_TYPE_ALL-by-default.patch \
           file://0062-Add-dracut-args-for-home-to-bootloader.patch \
           file://0063-do-not-customize-window-theme.patch \
           file://0064-tweak-product-short-name.patch \
           file://0065-disable-dmraid.patch \
           file://0066-tweak-shebang-of-bash.patch \
           file://0067-Tweak-label-name.patch \
           file://0068-livepayload.py-copy-grub-from-host-os.patch \
          "

SRCREV = "3007d202469f90ef9bb7580ff4068a345ba1e588"

FILES_${PN}-dbg += "${libexecdir}/anaconda/.debug ${PYTHON_SITEPACKAGES_DIR}/pyanaconda/.debug"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/pyanaconda/_isys.a"
FILES_${PN} = "/lib ${libdir} ${sysconfdir} ${bindir} ${sbindir} ${libexecdir} \
              ${datadir}/anaconda ${datadir}/applications ${datadir}/glade \
              ${PYTHON_SITEPACKAGES_DIR}/pyanaconda ${PYTHON_SITEPACKAGES_DIR}/log_picker \
              ${datadir}/themes \
"
FILES_${PN}-misc = "/usr/lib"
PACKAGES += "${PN}-misc"
RDEPENDS_${PN}-misc += "bash python3-core"

EXTRA_OECONF += "--disable-selinux \
         --with-sysroot=${PKG_CONFIG_SYSROOT_DIR} \
"

inherit distro_features_check
REQUIRED_DISTRO_FEATURES = "systemd x11"

inherit autotools-brokensep gettext python3native pkgconfig gobject-introspection

do_configure_prepend() {
    ( cd ${S}; STAGING_DATADIR_NATIVE=${STAGING_DATADIR_NATIVE} ${S}/autogen.sh --noconfigure)
}

do_install_append() {
    install -m 644 ${WORKDIR}/81-edit-sudoers.ks ${D}${datadir}/anaconda/post-scripts
    install -m 644 ${S}/widgets/src/resources/*.svg ${D}${datadir}/anaconda/pixmaps
    install -m 644 ${S}/widgets/src/resources/*.png ${D}${datadir}/anaconda/pixmaps
}

addtask do_setupdistro after do_patch before do_configure
do_setupdistro() {
    cp ${WORKDIR}/wrlinux.py ${S}/pyanaconda/installclasses/
}

python __anonymous () {
    if not bb.utils.contains("PACKAGE_CLASSES", "package_rpm", True, False, d):
        raise bb.parse.SkipPackage('Anaconda requires RPM packages to be the default in PACKAGE_CLASSES.')
}
