# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "dmraid (Device-mapper RAID tool and library)"
DESCRIPTION = "DMRAID supports RAID device discovery, RAID set activation, creation, \
removal, rebuild and display of properties for ATARAID/DDF1 metadata on \
Linux >= 2.4 using device-mapper."
HOMEPAGE = "http://people.redhat.com/heinzm/sw/dmraid"
LICENSE = "GPLv2+"
PR = "r0"

DEPENDS = "lvm2"

# XXX kpartx and  dmraid-events were listed as requires in spec file
RDEPENDS_${PN} = "lvm2"
RDEPENDS_${PN}-events= "${PN}-events dmraid"

SRC_URI = "http://people.redhat.com/heinzm/sw/dmraid/src/dmraid-1.0.0.rc16-3.tar.bz2 \
	   file://dmraid-1.0.0.rc16-test_devices.patch \
	   file://ddf1_lsi_persistent_name.patch \
	   file://pdc_raid10_failure.patch \
	   file://return_error_wo_disks.patch \
	   file://fix_sil_jbod.patch \
	   file://avoid_register.patch \
	   file://move_pattern_file_to_var.patch \
	   file://libversion.patch \
	   file://libversion-display.patch \
	   file://bz635995-data_corruption_during_activation_volume_marked_for_rebuild.patch \
	   file://bz626417_19-enabling_registration_degraded_volume.patch \
	   file://bz626417_20-cleanup_some_compilation_warning.patch \
	   file://bz626417_21-add_option_that_postpones_any_metadata_updates.patch \
	   file://klibc.m4 \
	   file://fix-dlopen.patch \
	   file://fix-parallel-compile-issue.patch \
	"

SRC_URI[md5sum] = "507252c1b68d745c2ecbda2ceac8feea"
SRC_URI[sha256sum] = "4022560e84b42a4b026c2a9f3d92e19f7bb4cb575f435dfa4ca30743e86a7161"

LIC_FILES_CHKSUM="file://LICENSE;md5=15b3012575eeffacc3cec27a6d3cb31f \
                  file://LICENSE_GPL;md5=393a5ca445f6965873eca0259a17f833 \
                  file://LICENSE_LGPL;md5=7fbc338309ac38fefcd64b04bb903e34"

# FILES_${PN} = "${base_libdir}/libdmraid* ${base_sbindir}/dmraid* ${sbindir}/dm* ${libdir}/libdmraid*so /var/lock/dmraid" 
PACKAGES += "${PN}-events"

FILES_${PN} = "${mandir}/man8/dmraid* ${base_sbindir}/dmraid ${base_sbindir}/dmraid.static ${base_libdir}/libdmraid.so.* ${base_libdir}/libdmraid-events-isw.so.*"
FILES_${PN}-dev = "${includedir}/dmraid ${base_libdir}/libdmraid.so ${base_libdir}/libdmraid-events-isw.so"
FILES_${PN}-events = "${mandir}/man8/dmevent_tool* ${mandir}/man8/dm_dso_reg_tool* ${base_sbindir}/dmevent_tool ${base_sbindir}/dm_dso_reg_tool"


inherit autotools-brokensep gettext

export DESTDIR="${D}"
EXTRA_OECONF += " --prefix=${D}/${prefix} --sbindir=${D}/${base_sbindir} --libdir=${D}/${base_libdir} --mandir=${D}/${mandir} --includedir=${D}/${includedir}"
EXTRA_OECONF += " --disable-static_link --enable-led --enable-intel_led --disable-klibc"

do_configure_prepend () {
    cp ${WORKDIR}/klibc.m4 ${S}
}

do_install_append() {
    install -m 755 -d ${D}${base_sbindir} ${D}${mandir}/man8 ${D}${base_libdir}

    ln -s dmraid ${D}${base_sbindir}/dmraid.static

    # Provide convenience link from dmevent_tool
    ln -sf dmevent_tool ${D}${base_sbindir}/dm_dso_reg_tool
    ln -sf dmevent_tool.8 ${D}${mandir}/man8/dm_dso_reg_tool.8
    ln -sf dmraid.8 ${D}${mandir}/man8/dmraid.static.8

    install -m 644 include/dmraid/*.h ${D}${includedir}/dmraid

    # Install the libdmraid and libdmraid-events (for dmeventd) DSO
    # Create version symlink to libdmraid.so.1 we link against
    install -m 755 lib/libdmraid.so ${D}${base_libdir}/libdmraid.so.${PV}
    ln -sf libdmraid.so.${PV} ${D}${base_libdir}/libdmraid.so
    ln -sf libdmraid.so.${PV} ${D}${base_libdir}/libdmraid.so.1

    install -m 755 lib/libdmraid-events-isw.so ${D}${base_libdir}/libdmraid-events-isw.so.${PV}
    ln -sf libdmraid-events-isw.so.${PV} ${D}${base_libdir}/libdmraid-events-isw.so
    ln -sf libdmraid-events-isw.so.${PV} ${D}${base_libdir}/libdmraid-events-isw.so.1

    rm -f ${D}${base_libdir}/libdmraid.a
}

S = "${WORKDIR}/dmraid/1.0.0.rc16/"
