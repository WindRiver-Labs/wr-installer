SUMMARY = "libtar, tar manipulating library"
DESCRIPTION = "libtar is a library for manipulating POSIX tar files"
HOMEPAGE = "http://www.feep.net/libtar"
SECTION = "libs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=61cbac6719ae682ce6cd45b5c11e21af"

SRC_URI = "ftp://ftp.feep.net/pub/software/libtar/libtar-${PV}.tar.gz \
           file://fix_libtool_sysroot.patch \
           file://0002-Do-not-strip-libtar.patch \
           "
SRC_URI[md5sum] = "604238e8734ce6e25347a58c4f1a1d7e"
SRC_URI[sha256sum] = "4a2eefb6b7088f41de57356e5059cbf1f917509b4a810f7c614625a378e87bb8"

PR = "r1"

inherit autotools-brokensep

EXTRA_OECONF = "compat_cv_func_makedev_three_args=no"
EXTRA_OEMAKE = "CFLAGS='${CFLAGS} -DHAVE_STDARG_H'"

do_configure_prepend() {
    # copy from fedora
    cd autoconf
    test ! -f aclocal.m4 || sed '/^m4_include/d;s/ m4_include/ m4][_include/g' aclocal.m4 >psg.m4
    rm -f aclocal.m4
    cd ..
}
