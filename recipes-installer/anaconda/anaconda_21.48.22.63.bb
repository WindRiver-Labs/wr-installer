SUMMARY = "The anaconda package"
DESCRIPTION = "The anaconda package"
HOMEPAGE = "http://fedoraproject.org/wiki/Anaconda"
LICENSE = "GPLv2"
SECTION = "devel"

LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "e2fsprogs gettext intltool libarchive virtual/libx11 \
           pango python rpm slang zlib dbus iscsi-initiator-utils audit \
           lvm2 system-config-keyboard-native libuser util-linux \
           libnewt libxcomposite gtk+ curl libarchive"

DEPENDS += "libxklavier glade \
            "

S = "${WORKDIR}/git"

# Disabled networkmanager...
DEPENDS += "networkmanager"

RDEPENDS_${PN} = "e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs \
                   e2fsprogs-tune2fs e2fsprogs-resize2fs \
                   ntfsprogs xfsprogs btrfs-tools nfs-utils-client \
                   parted dosfstools gzip libarchive lvm2 \
                   squashfs-tools openssh python python-misc python-modules python-dbus \
                   nspr nss python-nss python-pyparted python-pyblock \
                   cracklib-python system-config-keyboard system-config-keyboard-base \
                   system-config-date pykickstart libnewt-python dmraid lvm2 \
                   python-cryptsetup firstboot python-iniparse \
                   dmidecode python-meh python2-libuser libuser \
                   libreport-python localedef device-mapper device-mapper-multipath \
                   python-pygobject python-rpm python-urlgrabber\
                   libgnomecanvas grub usermode tigervnc keybinder \
                   tzdata tzdata-misc tzdata-posix tzdata-right tzdata-africa \
                   tzdata-americas tzdata-antarctica tzdata-arctic tzdata-asia \
                   tzdata-atlantic tzdata-australia tzdata-europe tzdata-pacific \
                   module-init-tools smartpm util-linux efibootmgr \
                   ca-certificates xfsprogs-fsck xfsprogs-mkfs isomd5sum \
                   btrfs-tools ntfs-3g iproute2 mdadm shadow chkconfig \
                   util-linux-swaponoff util-linux-uuidgen python-blivet \
                   xrandr glibc-charmaps glibc-localedatas python-ipy \
                   python-pytz python-langtable libpwquality-python \
                   python-ntplib libgnomekbd libtimezonemap \
                   procps python-prctl rsync glibc-utils \
                "

RDEPENDS_${PN} += "networkmanager libnmutil libnmglib libnmglib-vpn \
                   network-manager-applet \
"

SRC_URI = "git://github.com/rhinstaller/anaconda;protocol=https;branch=rhel7-branch \
           http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/21/Everything/source/SRPMS/a/anaconda-21.48.21-1.fc21.src.rpm;extract=anaconda-21.48.21.tar.bz2;name=anaconda-po \
           file://smartpayload.py \
           file://wrlinux.py \
           file://81-edit-sudoers.ks \
           file://0001-Remove-unnecessary-noverifyssl-for-http-ftp-protocol.patch \
           file://0002-scripts-run-anaconda-replace-usr-bin-bash-with-bin-s.patch \
           file://0003-widgets-Makefile.am-do-not-compile-doc.patch \
           file://0004-utils-Makefile.am-do-not-compile-dd.patch \
           file://0005-pyanaconda-flags.py-drop-selinux-module.patch \
           file://0006-geoloc.py-support-https.patch \
           file://0007-comment-out-Keybinder.patch \
           file://0008-dynamic-detect-workable-locale.patch \
           file://0009-anaconda-disable-ntp.patch \
           file://0010-tweak-for-testing.patch \
           file://0011-tweak-auditd-invoking-dir.patch \
           file://0012-use-png-icon-to-replace-svg-icon.patch \
           file://0013-improve-thread-monitor.patch \
           file://0014-bootloader.py-Change-grub2-settings-to-match-oe-core.patch \
           file://0015-tweak-detect-kernel-version.patch \
           file://0016-tweak-grub-config-file-for-WRLinux.patch \
           file://0017-set-plain-as-default-auto-partition.patch \
           file://0018-kickstart-disable-Authconfig-AutoPart-Timezone.patch \
           file://0019-invisible-help-button.patch \
           file://0020-disable-non-implemented-functions.patch \
           file://0021-do-not-support-spinner.patch \
           file://0022-disable-geoloc-by-default.patch \
           file://0023-support-UEFI-boot.patch \
           file://0024-do-not-verify-ssl-certification-by-default.patch \
           file://0025-tweak-default-nfs-mount-point.patch \
           file://0026-fix-quoted-empty-string-failed.patch \
           file://0027-do-not-support-ISO-hold-by-hard-drive-partitions.patch \
           file://0028-default-repository-setting-does-not-support-mirrorli.patch \
           file://0029-do-not-support-repo-name-check-and-repo-url-check.patch \
           file://0030-enable-gui-page-to-support-smart-repository-setting.patch \
           file://0031-fix-cannot-stat-usr-share-gettext-gettext.h.patch \
           file://0032-fix-Wind-River-boot-menu-not-work.patch \
           file://0033-tweak-bootloader-fs-type.patch \
           file://0034-support-timezone-setting.patch \
           file://0035-disable-ntp-support.patch \
           file://0036-do-not-support-manually-set-time.patch \
           file://0037-support-user-account-creation.patch \
           file://0038-detect-existence-of-Xorg.patch \
           file://0039-fix-write-network-conf-failed-while-liveinst.patch \
           file://0040-revert-commits-to-support-reboot-for-live-installs.patch \
           file://0041-text-repository-setting-do-not-support-local-ISO-fil.patch \
           file://0042-text-repository-setting-support-http-proxy.patch \
           file://0043-set-keyboard-xlayouts-with-us-by-default.patch \
           file://0044-text-mode-do-not-support-network-setting-for-now.patch \
           file://0045-text-add-user-to-sudo-group-as-administrator.patch \
           file://0046-support-EULA-location-configurable.patch \
           file://0047-always-write-fstab-after-install.patch \
           file://0048-tweak-boot-storage-sanity-check.patch \
           file://0049-kickstart-do-not-support-network-configuration.patch \
           file://0050-support-to-get-kickstart-from-network.patch \
           file://0051-support-authentication-for-kickstart.patch \
           file://0052-support-downloading-file-from-http-ftp-server-to-tar.patch \
           file://0053-live-install-supports-kickstart.patch \
          "

SRCREV = "1e5f44b5fd76489bbd95dba4e04f30939a71426b"
SRC_URI[anaconda-po.md5sum] = "dfdb1546cc18c9ec0a6673ccc3d35098"
SRC_URI[anaconda-po.sha256sum] = "a3421e067c82e435fc626142c77d91b94d514fe3fd7f3b429b22706876ac306a"

FILES_${PN}-dbg += "${libexecdir}/anaconda/.debug ${PYTHON_SITEPACKAGES_DIR}/pyanaconda/.debug"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/pyanaconda/_isys.a"
FILES_${PN} = "/lib ${libdir} ${sysconfdir} ${bindir} ${sbindir} ${libexecdir} \
              ${datadir}/anaconda ${datadir}/applications ${datadir}/glade \
              ${PYTHON_SITEPACKAGES_DIR}/pyanaconda ${PYTHON_SITEPACKAGES_DIR}/log_picker \
"
FILES_${PN}-misc = "/usr/lib"
PACKAGES += "${PN}-misc"
RDEPENDS_${PN}-misc += "bash python"

EXTRA_OECONF += "--disable-selinux \
         --with-sysroot=${PKG_CONFIG_SYSROOT_DIR} \
"

PACKAGECONFIG ??= "${@base_conditional('USE_NLS','yes','nls','',d)}"
PACKAGECONFIG[nls] = "--enable-nls, --disable-nls,,packagegroup-fonts-ttf"

inherit autotools-brokensep gettext pythonnative pkgconfig gobject-introspection

PYTHON_BASEVERSION = "2.7"
PYTHON_PN = "python"

do_prepare_po () {
	install -m 644 ${WORKDIR}/anaconda-21.48.21/po/*.po ${S}/po/
}
do_patch[postfuncs] += "${@base_conditional('USE_NLS','yes','do_prepare_po','',d)}"

do_configure_prepend() {
	( cd ${S}; STAGING_DATADIR_NATIVE=${STAGING_DATADIR_NATIVE} ${S}/autogen.sh --noconfigure)
}

do_install_append() {
	install -m 644 ${WORKDIR}/81-edit-sudoers.ks ${D}${datadir}/anaconda/post-scripts
}

addtask do_setupdistro after do_patch before do_configure
do_setupdistro() {
	cp ${WORKDIR}/wrlinux.py ${S}/pyanaconda/installclasses/
	cp ${WORKDIR}/smartpayload.py ${S}/pyanaconda/packaging/
}

