DESCRIPTION = "libblockdev is a C library supporting GObject introspection for manipulation of \
block devices. It has a plugin-based architecture where each technology (like \
LVM, Btrfs, MD RAID, Swap,...) is implemented in a separate plugin, possibly \
with multiple implementations (e.g. using LVM CLI or the new LVM DBus API)."
HOMEPAGE = "http://rhinstaller.github.io/libblockdev/"
LICENSE = "LGPLv2+"
SECTION = "devel/lib"

LIC_FILES_CHKSUM = "file://LICENSE;md5=c07cb499d259452f324bb90c3067d85c"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "f169b3389f2c369cb9b144c51d72395cf3d0f84e"
PV = "2.7+git${SRCPV}"
SRC_URI = "git://github.com/rhinstaller/libblockdev;branch=master \
           file://0001-fix-configure-and-compile-failures.patch \
           file://0002-remove-python2-support.patch \
"

inherit autotools python3native gobject-introspection

DEPENDS += " \
    cryptsetup \
    nss \
    volume-key \
    libbytesize \
"
RDEPENDS_${PN} += " \
    lvm2 \
"

FILES_${PN} += "${PYTHON_SITEPACKAGES_DIR}"

PACKAGECONFIG ??= "python3 lvm dmraid kmod parted fs"
PACKAGECONFIG[python3] = "--with-python3, --without-python3,,python3"
PACKAGECONFIG[lvm] = "--with-lvm, --without-lvm, device-mapper-multipath"
PACKAGECONFIG[dmraid] = "--with-dm, --without-dm, dmraid"
PACKAGECONFIG[kmod] = "--with-kbd, --without-kbd, kmod"
PACKAGECONFIG[parted] = "--with-part, --without-part, parted"
PACKAGECONFIG[fs] = "--with-fs, --without-fs, util-linux"
PACKAGECONFIG[doc] = "--with-gtk-doc, --without-gtk-doc, gtk-doc-native"

export STAGING_INCDIR
export GIR_EXTRA_LIBS_PATH="${B}/src/utils/.libs"

