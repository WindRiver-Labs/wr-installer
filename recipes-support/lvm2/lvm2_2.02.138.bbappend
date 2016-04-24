EXTRA_OECONF += " --enable-lvm1_fallback --enable-fsadm --with-pool=internal --with-device-uid=0 --with-device-gid=6 --with-device-mode=0660 --enable-applib --enable-cmdlib --enable-dmeventd --enable-udev_sync --with-udevdir=${nonarch_base_libdir}/udev/rules.d"

PACKAGES += "${PN}-libs device-mapper device-mapper-libs device-mapper-dev device-mapper-event device-mapper-event-libs device-mapper-event-dev device-mapper-event-dbg"

# DEBIAN_NOAUTONAME_device-mapper-libs = "1"

FILES_${PN} = "${sbindir}/fsadm \
        ${sbindir}/lvchange \
        ${sbindir}/lvconvert \
        ${sbindir}/lvcreate \
        ${sbindir}/lvdisplay \
        ${sbindir}/lvextend \
        ${sbindir}/lvm \
        ${sbindir}/lvmchange \
        ${sbindir}/lvmdiskscan \
        ${sbindir}/lvmdump \
        ${sbindir}/lvmsadc \
        ${sbindir}/lvmsar \
        ${sbindir}/lvreduce \
        ${sbindir}/lvremove \
        ${sbindir}/lvrename \
        ${sbindir}/lvresize \
        ${sbindir}/lvs \
        ${sbindir}/lvscan \
        ${sbindir}/pvchange \
        ${sbindir}/pvck \
        ${sbindir}/pvcreate \
        ${sbindir}/pvdisplay \
        ${sbindir}/pvmove \
        ${sbindir}/pvremove \
        ${sbindir}/pvresize \
        ${sbindir}/pvs \
        ${sbindir}/pvscan \
        ${sbindir}/vgcfgbackup \
        ${sbindir}/vgcfgrestore \
        ${sbindir}/vgchange \
        ${sbindir}/vgck \
        ${sbindir}/vgconvert \
        ${sbindir}/vgcreate \
        ${sbindir}/vgdisplay \
        ${sbindir}/vgexport \
        ${sbindir}/vgextend \
        ${sbindir}/vgimport \
        ${sbindir}/vgimportclone \
        ${sbindir}/vgmerge \
        ${sbindir}/vgmknodes \
        ${sbindir}/vgreduce \
        ${sbindir}/vgremove \
        ${sbindir}/vgrename \
        ${sbindir}/vgs \
        ${sbindir}/vgscan \
        ${sbindir}/vgsplit \
        ${sbindir}/lvmconf \
        ${sbindir}/build_lvm_initramfs.sh \
        ${sbindir}/blkdeactivate \
        ${sbindir}/dmstats \
        ${sbindir}/lvmconfig \
        ${sbindir}/lvmetad \
        ${mandir}/man5/lvm.conf.5.gz \
        ${mandir}/man8/fsadm.8.gz \
        ${mandir}/man8/lvchange.8.gz \
        ${mandir}/man8/lvconvert.8.gz \
        ${mandir}/man8/lvcreate.8.gz \
        ${mandir}/man8/lvdisplay.8.gz \
        ${mandir}/man8/lvextend.8.gz \
        ${mandir}/man8/lvm.8.gz \
        ${mandir}/man8/lvmchange.8.gz \
        ${mandir}/man8/lvmconf.8.gz \
        ${mandir}/man8/lvmdiskscan.8.gz \
        ${mandir}/man8/lvmdump.8.gz \
        ${mandir}/man8/lvmsadc.8.gz \
        ${mandir}/man8/lvmsar.8.gz \
        ${mandir}/man8/lvreduce.8.gz \
        ${mandir}/man8/lvremove.8.gz \
        ${mandir}/man8/lvrename.8.gz \
        ${mandir}/man8/lvresize.8.gz \
        ${mandir}/man8/lvs.8.gz \
        ${mandir}/man8/lvscan.8.gz \
        ${mandir}/man8/pvchange.8.gz \
        ${mandir}/man8/pvck.8.gz \
        ${mandir}/man8/pvcreate.8.gz \
        ${mandir}/man8/pvdisplay.8.gz \
        ${mandir}/man8/pvmove.8.gz \
        ${mandir}/man8/pvremove.8.gz \
        ${mandir}/man8/pvresize.8.gz \
        ${mandir}/man8/pvs.8.gz \
        ${mandir}/man8/pvscan.8.gz \
        ${mandir}/man8/vgcfgbackup.8.gz \
        ${mandir}/man8/vgcfgrestore.8.gz \
        ${mandir}/man8/vgchange.8.gz \
        ${mandir}/man8/vgck.8.gz \
        ${mandir}/man8/vgconvert.8.gz \
        ${mandir}/man8/vgcreate.8.gz \
        ${mandir}/man8/vgdisplay.8.gz \
        ${mandir}/man8/vgexport.8.gz \
        ${mandir}/man8/vgextend.8.gz \
        ${mandir}/man8/vgimport.8.gz \
        ${mandir}/man8/vgimportclone.8.gz \
        ${mandir}/man8/vgmerge.8.gz \
        ${mandir}/man8/vgmknodes.8.gz \
        ${mandir}/man8/vgreduce.8.gz \
        ${mandir}/man8/vgremove.8.gz \
        ${mandir}/man8/vgrename.8.gz \
        ${mandir}/man8/vgs.8.gz \
        ${mandir}/man8/vgscan.8.gz \
        ${mandir}/man8/vgsplit.8.gz \
        ${nonarch_base_libdir}/udev/rules.d/11-dm-lvm.rules \
        ${sysconfdir}/lvm/*"

FILES_${PN}-dev = "${libdir}/liblvm2app.so \
        ${libdir}/liblvm2cmd.so \
        ${includedir}/lvm2app.h \
        ${includedir}/lvm2cmd.h \
        ${libdir}/pkgconfig/lvm2app.pc \
        ${libdir}/libdevmapper-event-lvm2.so \
        ${libdir}/libdevmapper-event-lvm2mirror.so \
        ${libdir}/libdevmapper-event-lvm2snapshot.so \
        ${libdir}/device-mapper/libdevmapper-event-lvm2raid.so \
        ${libdir}/device-mapper/libdevmapper-event-lvm2mirror.so \
        ${libdir}/device-mapper/libdevmapper-event-lvm2snapshot.so"

FILES_${PN}-libs = "${libdir}/liblvm2app.so.* \
        ${libdir}/liblvm2cmd.so.* \
        ${libdir}/libdevmapper-event-lvm2.so.*"

FILES_device-mapper = "${sbindir}/dmsetup \
        ${mandir}/man8/dmsetup.8.gz \
        ${nonarch_base_libdir}/udev/rules.d/10-dm.rules \
        ${nonarch_base_libdir}/udev/rules.d/13-dm-disk.rules \
        ${nonarch_base_libdir}/udev/rules.d/69-dm-lvm-metad.rules \
        ${nonarch_base_libdir}/udev/rules.d/95-dm-notify.rules"

FILES_device-mapper-libs = "${libdir}/libdevmapper.so.1.02"

FILES_device-mapper-dev = "${libdir}/libdevmapper.so \
        ${includedir}/libdevmapper.h \
        ${libdir}/pkgconfig/devmapper.pc"

FILES_device-mapper-event = "${sbindir}/dmeventd \
        ${mandir}/man8/dmeventd.8.gz"

FILES_device-mapper-event-libs = "${libdir}/libdevmapper-event.so.*"

FILES_device-mapper-event-dev = "${libdir}/libdevmapper-event.so \
        ${libdir}/libdevmapper-event-lvm2raid.so \
        ${libdir}/libdevmapper-event-lvm2thin.so \
        ${libdir}/device-mapper/libdevmapper-event-lvm2thin.so \
        ${includedir}/libdevmapper-event.h \
        ${libdir}/pkgconfig/devmapper-event.pc"

FILES_device-mapper-event-dbg = "${libdir}/device-mapper/.debug"

DEPENDS += "udev"
RDEPENDS_${PN} += "ldd"

SYSTEMD_AUTO_ENABLE = "enable"

INSANE_SKIP_device-mapper-event-dev = "dev-elf"
INSANE_SKIP_${PN}-dev = "dev-elf"
