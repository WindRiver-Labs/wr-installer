SUMMARY = "The anaconda package"
DESCRIPTION = "The anaconda package"
HOMEPAGE = "http://fedoraproject.org/wiki/Anaconda"
LICENSE = "GPLv2"
SECTION = "devel"


LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b"

DEPENDS = "e2fsprogs gettext intltool libarchive virtual/libx11 libnl1 \
           pango python rpm slang zlib dbus iscsi-initiator-utils audit \
           isomd5sum lvm2 system-config-keyboard-native libuser util-linux \
           libnewt libxcomposite gtk+ curl libarchive"

# Disabled networkmanager...
DEPENDS += "networkmanager"


RDEPENDS_anaconda="e2fsprogs e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-tune2fs \
                   ntfsprogs xfsprogs btrfs-tools nfs-utils-client \
                   parted dosfstools gzip libarchive lvm2 \
                   squashfs-tools openssh python python-misc python-modules python-dbus \
                   nspr nss python-nss parted python-pyblock python-pygtk \
                   cracklib-python system-config-keyboard system-config-keyboard-base \
                   system-config-date pykickstart libnewt-python dmraid lvm2 \
                   python-cryptsetup firstboot python-iniparse libnl1\
                   dmidecode python-meh libuser-python libuser \
                   libreport-python localedef device-mapper device-mapper-multipath \
                   python-pygobject python-rpm pyparted python-urlgrabber\
                   gnome-python libgnomecanvas grub usermode \
                   gtk-engine-clearlooks gtk-theme-clearlooks \
                   tzdata tzdata-misc tzdata-posix tzdata-right tzdata-africa \
                   tzdata-americas tzdata-antarctica tzdata-arctic tzdata-asia \
                   tzdata-atlantic tzdata-australia tzdata-europe tzdata-pacific \
                   module-init-tools smartpm util-linux efibootmgr \
                "

# Disabled networkmanager...
#RDEPENDS_anaconda += "network-manager-applet"

PR = "r1"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# This is were you set the package tarball upstream location. The file 
# name at the end of the path is used as the package's tarball name when
# searched in the local 'download' directories.
SRC_URI = "http://download.fedoraproject.org/pub/fedora/linux/releases/16/Everything/source/SRPMS/anaconda-16.25-1.fc16.src.rpm;extract=anaconda-16.25.tar.bz2 \
           file://smartinstall.py \
           file://wrlinux.py \
           file://rpmextract_header.patch \
           file://driverdisk_header.patch \
           file://disable_selinux_module.patch \
           file://pyudev_library_path.patch \
           file://kernel_pkgname.patch \
           file://fix-path-to-rsyslogd.patch \
           file://write-debian-style-net-config-files-to-target.patch \
           file://anaconda-initramfs-live.patch \
           file://anaconda-install-repo.patch \
           file://anaconda_reboot.patch \
           file://basic-storage-devices-only.patch \
           file://disable-lvm.patch \
           file://lsb-release.patch \
           file://multilib_policy_best.patch \
           file://disable_upgrade_support.patch \
           file://hide-lvm-crypt-checkboxes.patch \
           file://ignore-missing-hack.patch \
           file://disable_customize.patch \
           file://dont_disable_enabled_repos.patch \
           file://remove_g_type_init.patch \
           file://serial_and_vga_always.patch \
           file://fix_nmicli_args.patch \
           file://NO_dracut_for_WRLINUX.patch \
           file://anaconda-yum-to-smart.patch \
           file://anaconda-oe-grub.patch \
           file://anaconda-no-i18n.patch \
           file://anaconda-no-tz.patch \
           file://anaconda-no-nlm.patch \
           file://skip-language-selection.patch \
           file://not-set-the-window-icon-when-livecdInstall.patch \
           file://anaconda-livecd-write-ks.patch \
           file://anaconda-read-ks-for-liveimg.patch \
           file://anaconda-image-installation-based-kickstart.patch \
           file://anaconda-pyanaconda-check-ksdata.liveimg.patch \
           file://anaconda-pyanaconda-use-uname.patch \
           file://anaconda-progress_gui-for-livecdInstall-only.patch \
           file://anaconda-storage-umount-before-format.patch \
           file://anaconda-skip-mount-loop.patch \
           file://anaconda-pyanaconda-task_text-add-setGroupSelection.patch \
           file://anaconda-check-lokkit-before-run-it.patch \
           file://anaconda-backend_log.py-remove-c-from-rsyslogd.patch \
           file://anaconda-check-metacity-before-run-it.patch \
           file://anaconda-storage-fat32.patch \
           file://anaconda-sync-before-reboot.patch \
           file://anaconda-bootloader.py-fix-for-WR-efi.patch \
           file://anaconda-bootloader.py-efigrub2.patch \
           file://anaconda-no-destroy-all-devices.patch \
           file://anaconda-formats-fs.py-enable-EFIFS.patch \
           file://anaconda-storage-check-boot-efi.patch \
           file://anaconda-devicetree.py-no-ask-when-ks.patch \
           file://anaconda-mount-run-as-tmpfs.patch \
           file://anaconda-save-log-root.patch \
           file://anaconda-remove-un-verified-options.patch \
           file://anaconda-only-support-standard-partition.patch \
           file://anaconda-disable-the-partition-encrypt.patch \
           file://anaconda-disable-lvm-and-raid.patch \
           file://tweak-write-debian-style-net-config-files.patch \
           file://anaconda-livecd.py-remove-symlink.patch \
           file://anaconda-umount-before-mount.patch \
           file://anaconda-no-check-LiveOS.patch \
           file://pyanaconda-storage-update-fstab-by-appending.patch \
           file://anaconda-set-for-selinux.patch \
           file://anaconda-use-shadow-passswd.patch \
           file://anaconda-umount-before-resize.patch \
           file://anaconda-update-runlevel5-criteria.patch \
           file://anaconda-storage-check-Wind-River-Linux.patch \
           file://anaconda-not-check-rootfs-partition.patch \
           file://anaconda-fix-bin-sh.patch \
           file://anaconda-check-the-existence-of-usr-tmp.patch \
           file://anaconda-storage-release.patch \
           file://anaconda-correct-calls-of-smartrepo.patch \
           file://anaconda-implement-smart-mirrorlist.patch \
           file://anaconda-correct-nfs-repo-baseurl.patch \
           file://anaconda-remove-option-add-repo-from-cd.patch \
           file://anaconda-upgrade-fix-tmp.patch \
           file://anaconda-fix-default-label-for-x86.patch \
           file://anaconda-validate-repo.patch \
           file://anaconda-disable-edit-button-for-local-repo.patch \
           file://anaconda-fix-unpack.patch \
           file://anaconda-kernel-image.patch \
           file://anaconda-device-map.patch \
           file://pyanaconda-pyudev.py-find-udev-lib-while-systemd-ena.patch \
           file://0001-anaconda-use-tty7-to-instead-tty6-as-console.patch \
           file://0001-pyanaconda-storage-formats-__init__.py-wait-device-b.patch \
           file://0001-pyanaconda-timezone.py-fix-set-timezone-failed.patch \
           file://anaconda-loader.c-add-missing-include-sys-resource.h.patch \
          "

# Here is the checksum attribute for the package's tarball. Leave this empty,
# and on the first compile pass bitbake will tell you what md5 value to insert.
SRC_URI[md5sum] = "4c04b77bf98da8d372b6b466c2a8e91d"
SRC_URI[sha256sum] = "78e0f163e1208fd6c41e6603fbdb51c66fb68a3549f81f1f0b1d095775cff0fd"

FILES_${PN}-dbg += "${libexecdir}/anaconda/.debug ${PYTHON_SITEPACKAGES_DIR}/pyanaconda/.debug"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/pyanaconda/_isys.a"
FILES_${PN} = "/lib ${libdir}/anaconda ${sysconfdir} ${bindir} ${sbindir} ${libexecdir} ${datadir} ${PYTHON_SITEPACKAGES_DIR}/pyanaconda ${PYTHON_SITEPACKAGES_DIR}/log_picker"

# Note helpful variables...
#  ${PN} is package name
#  ${PV} is package version

# Safe default to force a non-parallel build
PARALLEL_MAKE = "-j 4"


# Custom configure extensions
#EXTRA_OECONF += "--disable-static --enable-introspection --enable-gtk-doc"
EXTRA_OECONF += "--disable-selinux \
         STAGING_INCDIR=${STAGING_INCDIR} \
         STAGING_LIBDIR=${STAGING_LIBDIR} \
         BUILD_SYS=${BUILD_SYS} HOST_SYS=${HOST_SYS} \
"

# Enable this if the package uses automake/configure
inherit autotools-brokensep gettext pythonnative pkgconfig

addtask do_setupdistro after do_patch before do_configure

do_setupdistro() {
	rm -f ${S}/pyanaconda/installclasses/*.py
	rm -f ${S}/pyanaconda/yuminstall.py
	cp ${WORKDIR}/wrlinux.py ${S}/pyanaconda/installclasses/.
        cp ${WORKDIR}/smartinstall.py ${S}/pyanaconda/.
}

# You must populate the install rule
#  ${S} is the source directory
#  ${D} is the destination install directory
#  ${bindir} is the default bin directory
#  ${libdir} is the default lib directory
#
do_install() {
        echo ${S} "--" ${D}
	install -d ${D}${bindir}
	oe_runmake install DESTDIR=${D}
}
