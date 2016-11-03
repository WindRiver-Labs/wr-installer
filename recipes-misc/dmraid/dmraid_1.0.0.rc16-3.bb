# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "dmraid (Device-mapper RAID tool and library)"
DESCRIPTION = "DMRAID supports RAID device discovery, RAID set activation, creation, \
removal, rebuild and display of properties for ATARAID/DDF1 metadata on \
Linux >= 2.4 using device-mapper."
HOMEPAGE = "http://people.redhat.com/heinzm/sw/dmraid"
LICENSE = "GPLv2+"

DEPENDS = "lvm2"
RDEPENDS_${PN} = "lvm2"

SRC_URI = "http://people.redhat.com/heinzm/sw/dmraid/src/dmraid-1.0.0.rc16-3.tar.bz2 \
	   file://klibc.m4 \
	   file://fix-parallel-compile-issue.patch \
	"

SRC_URI[md5sum] = "819338fcef98e8e25819f0516722beeb"
SRC_URI[sha256sum] = "93421bd169d71ff5e7d2db95b62b030bfa205a12010b6468dcdef80337d6fbd8"

LIC_FILES_CHKSUM="file://LICENSE;md5=15b3012575eeffacc3cec27a6d3cb31f \
                  file://LICENSE_GPL;md5=393a5ca445f6965873eca0259a17f833 \
                  file://LICENSE_LGPL;md5=7fbc338309ac38fefcd64b04bb903e34"

PACKAGES = "${PN} ${PN}-dbg ${PN}-staticdev ${PN}-dev ${PN}-doc"

FILES_${PN} += "${libdir}/device-mapper/libdmraid-events-isw.so \
                ${libdir}/libdmraid-events-isw.so \
"
INSANE_SKIP_${PN} = "dev-so"

inherit autotools-brokensep gettext

EXTRA_OECONF += " --disable-static_link --enable-led --enable-intel_led --disable-klibc --with-usrlibdir=${libdir}"

do_configure_prepend () {
    cp ${WORKDIR}/klibc.m4 ${S}
}

S = "${WORKDIR}/dmraid/1.0.0.rc16-3/dmraid"
