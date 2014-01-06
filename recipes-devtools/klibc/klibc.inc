DEPENDS = "linux-libc-headers perl-native"
SECTION = "libs"
DESCRIPTION = "klibc is intended to be a minimalistic libc subset for \
use with initramfs.  It is deliberately written for small size, \
minimal entaglement, and portability, not speed."
LICENSE = "BSD-3-Clause & GPL-2.0 & MIT & Zlib"
LIC_FILES_CHKSUM = "file://usr/klibc/LICENSE;md5=d75181f10e998c21eb147f6d2e43ce8b"

# Prevents do_package failures with:
# debugsources.list: No such file or directory:
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

INC_PR = "r0"

KLIBC_ARCH = '${TARGET_ARCH}'
KLIBC_ARCH_armeb = 'arm'
KLIBC_ARCH_mipsel = 'mips'
KLIBC_ARCH_x86 = 'i386'
KLIBC_ARCH_i486 = 'i386'
KLIBC_ARCH_i586 = 'i386'
KLIBC_ARCH_i686 = 'i386'
KLIBC_ARCH_pentium = 'i386'

#SRCREV = "f05ff116bb9edbbb81d82fa47b78e630ce878470"
#SRC_URI = "git://git.kernel.org/pub/scm/libs/klibc/klibc.git;protocol=git"
SRC_URI = "http://www.kernel.org/pub/linux/libs/klibc/2.0/klibc-2.0.2.tar.bz2"

SRC_URI[md5sum] = "d19bf221645e988e76f5458f55ea39bc"
SRC_URI[sha256sum] = "af44057280548652e51a03d900797019eea0e8aec72880577b4c480518723090"

SRC_URI_append_linux-gnueabi = " file://klibc-config-eabi.patch"
SRC_URI_append_linux-uclibceabi = " file://klibc-config-eabi.patch"

SRC_URI += "file://klibc-linux-libc-dev.patch \
            file://prefix.patch \
            file://staging.patch \
            file://fix-installroot.patch"

# S = "${WORKDIR}/git"

PARALLEL_MAKE = ""

EXTRA_OEMAKE = "'KLIBCARCH=${KLIBC_ARCH}' \
                'CROSS_COMPILE=${TARGET_PREFIX}' \
                'KLIBCKERNELSRC=${STAGING_DIR_TARGET}${exec_prefix}' \
                'INSTALLROOT=${D}' \
                "

do_configure () {
        ln -sf "${STAGING_DIR_TARGET}${exec_prefix}" linux
}

THIS_LIBKLIBC = "libklibc (= ${PV}-${PR})"
