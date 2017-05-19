SUMMARY = "The anaconda package"
DESCRIPTION = "The anaconda package"
HOMEPAGE = "http://fedoraproject.org/wiki/Anaconda"
LICENSE = "GPLv2"
SECTION = "devel"

LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

DEPENDS = "e2fsprogs gettext libarchive \
           pango python3 rpm audit \
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
                   system-config-date pykickstart dmraid firstboot \
                   dmidecode python3-meh libreport-python3 localedef \
                   python3-pygobject python3-rpm grub usermode tigervnc \
                   tzdata tzdata-misc tzdata-posix tzdata-right tzdata-africa \
                   tzdata-americas tzdata-antarctica tzdata-arctic tzdata-asia \
                   tzdata-atlantic tzdata-australia tzdata-europe tzdata-pacific \
                   keybinder module-init-tools dnf util-linux efibootmgr \
                   ca-certificates xfsprogs-fsck xfsprogs-mkfs isomd5sum \
                   btrfs-tools ntfs-3g iproute2 mdadm shadow chkconfig \
                   util-linux-swaponoff util-linux-uuidgen python3-blivet \
                   xrandr glibc-charmaps glibc-localedatas \
                   python3-pytz python3-langtable libpwquality-python3 \
                   python3-ntplib libgnomekbd libtimezonemap \
                   procps python3-prctl rsync glibc-utils python3-pid \
                   python3-ordered-set python3-wrapt python3-coverage \
                   python3-requests-file python3-requests-ftp \
                   python3-blivetgui librsvg librsvg-gtk \
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
          "

SRCREV = "045d6f19c7c9dc9f24aad28ffdde7391ef6bc2a7"

FILES_${PN}-dbg += "${libexecdir}/anaconda/.debug ${PYTHON_SITEPACKAGES_DIR}/pyanaconda/.debug"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/pyanaconda/_isys.a"
FILES_${PN} = "/lib ${libdir} ${sysconfdir} ${bindir} ${sbindir} ${libexecdir} \
              ${datadir}/anaconda ${datadir}/applications ${datadir}/glade \
              ${PYTHON_SITEPACKAGES_DIR}/pyanaconda ${PYTHON_SITEPACKAGES_DIR}/log_picker \
              ${datadir}/themes \
"
FILES_${PN}-misc = "/usr/lib"
PACKAGES += "${PN}-misc"
RDEPENDS_${PN}-misc += "bash python"

EXTRA_OECONF += "--disable-selinux \
         --with-sysroot=${PKG_CONFIG_SYSROOT_DIR} \
"

PACKAGECONFIG ??= "${@base_conditional('USE_NLS','yes','nls','',d)}"
PACKAGECONFIG[nls] = "--enable-nls, --disable-nls,,packagegroup-fonts-ttf"

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

