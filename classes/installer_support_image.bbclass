FEATURE_PACKAGES_installer-support = "packagegroup-installer-support"
IMAGE_FEATURES_append = " installer-support"
EXTRA_IMAGEDEPENDS += "grub grub-efi"

EXTRA_IMAGEDEPENDS += "glibc-locale"

# Generate filesystem images for image copy install
IMAGE_FSTYPES += "ext4"

ROOTFS_POSTPROCESS_COMMAND_append = " copy_grub_lib;"
IMAGE_POSTPROCESS_COMMAND_append = " emit_image_env;"

inherit distro_features_check
REQUIRED_DISTRO_FEATURES = "systemd ldconfig"

DEPENDS += "grub grub-efi"

copy_grub_lib() {
    mkdir -p ${IMAGE_ROOTFS}/${libdir}/grub
    for f in ${libdir}/grub/i386-pc ${libdir}/grub/${TARGET_ARCH}-efi ; do
        [ -d ${IMAGE_ROOTFS}/$f ] && continue
        echo "Copy $f"
        cp -rf ${STAGING_DIR_HOST}$f ${IMAGE_ROOTFS}/${f%/*}
    done
}

python emit_image_env () {
    localdata = bb.data.createCopy(d)

    # Export DISTRO for installer build
    localdata.setVarFlag("DISTRO", "unexport", "")

    dumpfile = d.expand("${TOPDIR}/installersupport_${PN}")
    with open(dumpfile , "w") as f:
        bb.data.emit_env(f, localdata, True)
}

python __anonymous () {
    if not bb.utils.contains("PACKAGE_CLASSES", "package_rpm", True, False, d):
        raise bb.parse.SkipPackage('Target build requires RPM packages to be the default in PACKAGE_CLASSES.')

    if d.getVar("VIRTUAL-RUNTIME_init_manager", True) != "systemd":
        raise bb.parse.SkipPackage('Target build requires systemd, set VIRTUAL-RUNTIME_init_manager = "systemd" in local.conf')
}
